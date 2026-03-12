;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

;;; Yason encoding extensions

;;; Single-float encoding fix: use single-float precision for ~F output
;;; to avoid IEEE 754 representation artifacts (e.g. 15.2 -> 15.199999809265137).
;;; Yason's default FLOAT method coerces to double-float first, which expands
;;; the inexact single-float representation to full double-float digits.
;;; NOTE: Uses yason::*json-output*, an internal symbol from the yason package.
;;; This is fragile and may break if yason changes its internal stream variable.
(defmethod yason:encode ((object single-float)
                         &optional (stream yason::*json-output*))
  "Encode SINGLE-FLOAT with single-float precision to avoid artifacts."
  (let ((*read-default-float-format* 'single-float))
    (format stream "~F" object))
  object)

(defparameter *data-supported-types*
  '("text/csv" "application/json" "application/vega-json" "text/s-expression")
  "Content types supported by the data endpoint. CSV is first so it is
the default for wildcard and absent Accept headers.")

;;; Handlers

(defun handle-data-list ()
  "Handle GET /data — return JSON array of data frame names."
  (setf (hunchentoot:content-type*) "application/json")
  (with-output-to-string (s)
    (yason:encode (map 'vector #'symbol-name (df:data-frame-symbols)) s)))

(defun handle-data-get (name)
  "Handle GET /data/<name> — serve data frame with content negotiation."
  (let ((sym (df:find-data-frame name)))
    (unless sym
      (setf (hunchentoot:return-code*) 404)
      (setf (hunchentoot:content-type*) "application/json")
      (return-from handle-data-get
        (format nil "{\"error\":\"Data frame '~A' not found\"}" name)))
    (let* ((accept (hunchentoot:header-in* :accept))
           (content-type (negotiate-content-type accept *data-supported-types*
                                                 :default "text/csv")))
      (setf (hunchentoot:content-type*) content-type)
      (with-output-to-string (s)
        (cond
          ((string= content-type "application/vega-json")
           (vega:encode-symbol-for-vega sym s))
          ((string= content-type "text/csv")
           (dfio:write-csv (symbol-value sym) s :add-first-row t))
          ((string= content-type "text/s-expression")
           (dfio:write-df sym s))
          (t ; application/json — reuse vega encoder for symbol values
           (vega:encode-symbol-for-vega sym s)))))))

(defun read-request-body ()
  "Read the raw request body as a string from the current Hunchentoot request."
  (hunchentoot:raw-post-data :force-text t))

(defun handle-data-put (name)
  "Handle PUT /data/<name> — replace data frame with JSON body.
Expects a JSON array of row objects. Returns 404 if data frame not found,
400 if JSON is invalid or empty."
  (let ((sym (df:find-data-frame name)))
    (unless sym
      (setf (hunchentoot:return-code*) 404)
      (setf (hunchentoot:content-type*) "application/json")
      (return-from handle-data-put
        (format nil "{\"error\":\"Data frame '~A' not found\"}" name)))
    (let ((body (read-request-body)))
      (handler-case
          (let* ((rows (yason:parse body)))
            (unless (and (listp rows) (plusp (length rows)))
              (error "Expected non-empty JSON array of row objects"))
            (let* ((keys (let (ks)
                           (maphash (lambda (k v) (declare (ignore v)) (push k ks))
                                    (first rows))
                           ks))
                   (col-names (mapcar (lambda (key)
                                       (intern (string-upcase key) :keyword))
                                     keys))
                   (col-vectors (mapcar (lambda (key)
                                         (coerce (mapcar (lambda (row)
                                                           (gethash key row))
                                                         rows)
                                                 'vector))
                                       keys))
                   (new-df (df:make-df col-names col-vectors)))
              (setf (symbol-value sym) new-df)
              (setf (hunchentoot:content-type*) "application/json")
              (with-output-to-string (s)
                ;; NOTE: Uses vega::encode-symbol-as-metadata via
                ;; encode-symbol-for-vega for symbol values (e.g. :NA).
                (let ((yason:*symbol-encoder*     'vega::encode-symbol-as-metadata)
                      (yason:*symbol-key-encoder* 'vega::encode-symbol-as-metadata))
                  (yason:encode new-df s)))))
        (error ()
          (setf (hunchentoot:return-code*) 400)
          (setf (hunchentoot:content-type*) "application/json")
          "{\"error\":\"Invalid JSON body\"}")))))

(defun handle-data-patch (name)
  "Handle PATCH /data/<name> — update specific cells in data frame.
Expects JSON: {\"updates\": [{\"row\": N, \"column\": \"col\", \"value\": V}, ...]}.
Returns 404 if data frame not found, 400 if JSON is invalid or indices out of range."
  (let ((sym (df:find-data-frame name)))
    (unless sym
      (setf (hunchentoot:return-code*) 404)
      (setf (hunchentoot:content-type*) "application/json")
      (return-from handle-data-patch
        (format nil "{\"error\":\"Data frame '~A' not found\"}" name)))
    (let ((body (read-request-body)))
      (handler-case
          (let* ((parsed (yason:parse body))
                 (updates (gethash "updates" parsed))
                 (df (symbol-value sym)))
            (dolist (update updates)
              (let* ((row (gethash "row" update))
                     (col-name (gethash "column" update))
                     (col (intern (string-upcase col-name) :keyword))
                     (val (gethash "value" update))
                     (col-vec (df:column df col)))
                (unless col-vec
                  (error "Column '~A' not found in data frame" col-name))
                (unless (and (integerp row) (>= row 0) (< row (length col-vec)))
                  (error "Row index ~A out of range [0, ~A)" row (length col-vec)))
                (setf (aref col-vec row) val)))
            (setf (hunchentoot:content-type*) "application/json")
            (with-output-to-string (s)
              ;; NOTE: Uses vega::encode-symbol-as-metadata via
              ;; encode-symbol-for-vega for symbol values (e.g. :NA).
              (let ((yason:*symbol-encoder*     'vega::encode-symbol-as-metadata)
                    (yason:*symbol-key-encoder* 'vega::encode-symbol-as-metadata))
                (yason:encode df s))))
        (error ()
          (setf (hunchentoot:return-code*) 400)
          (setf (hunchentoot:content-type*) "application/json")
          "{\"error\":\"Invalid JSON body\"}")))))

;;; Dispatcher

(defun data-dispatcher (request)
  "Dispatch requests matching /data or /data/<name>.
Routes GET, PUT, and PATCH methods. Returns a handler function or NIL."
  (let ((uri (hunchentoot:script-name request)))
    (cond
      ((string= uri "/data")
       #'handle-data-list)
      ((cl-ppcre:scan "^/data/([\\w\\-]+)$" uri)
       (lambda ()
         (multiple-value-bind (match groups)
             (cl-ppcre:scan-to-strings "^/data/([\\w\\-]+)$"
                                       (hunchentoot:script-name*))
           (declare (ignore match))
           (let ((name (aref groups 0))
                 (method (hunchentoot:request-method*)))
             (case method
               (:put   (handle-data-put name))
               (:patch (handle-data-patch name))
               (t      (handle-data-get name))))))))))

;;; Register dispatcher
(push 'data-dispatcher hunchentoot:*dispatch-table*)

;;; Future enhancement
#+nil
(defun handle-data-delete (name)
  "Handle DELETE /data/<n> — remove data frame by name."
  (handler-case
      (progn
        (df:undef name)   ; string form — no find-data-frame call needed
        (setf (hunchentoot:content-type*) "application/json")
        "{\"status\":\"deleted\"}")
    (error (e)
      (setf (hunchentoot:return-code*) 404)
      (format nil "{\"error\":\"~A\"}" e))))
