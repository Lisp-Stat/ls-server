;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

;;; Helpers — grouped at top

(defparameter *plot-supported-types*
  '("text/html" "application/vega-json")
  "Content types supported by the plot endpoint.")

(defun find-plot (name)
  "Look up NAME (case-insensitive) in vega:*all-plots*.
Returns the plot object or NIL."
  (gethash (string-upcase name) vega:*all-plots*))

(defun list-plots ()
  "Return a sorted list of plot name strings from vega:*all-plots*."
  (let (names)
    (maphash (lambda (k v)
               (declare (ignore v))
               (push k names))
             vega:*all-plots*)
    (sort names #'string<)))

;;; Handlers

(defun handle-plot-list ()
  "Handle GET /plot — return JSON array of plot names."
  (setf (hunchentoot:content-type*) "application/json")
  (with-output-to-string (s)
    (yason:encode (coerce (list-plots) 'vector) s)))

(defun handle-plot-get (name)
  "Handle GET /plot/<name> — serve plot with content negotiation."
  (let ((plot (find-plot name)))
    (unless plot
      (setf (hunchentoot:return-code*) 404)
      (setf (hunchentoot:content-type*) "application/json")
      (return-from handle-plot-get
        (format nil "{\"error\":\"Plot '~A' not found\"}" name)))
    (let* ((accept (hunchentoot:header-in* :accept))
           (content-type (negotiate-content-type accept *plot-supported-types*)))
      (cond
        ((string= content-type "application/vega-json")
         (setf (hunchentoot:content-type*) "application/vega-json; charset=utf-8")
         (vega:write-spec plot))
        (t ; text/html (default)
         (setf (hunchentoot:content-type*) "text/html")
         (vega-embed-page name (vega:write-spec plot)))))))

(defun handle-plot-delete (name)
  "Handle DELETE /plot/<name> — remove plot from vega:*all-plots*.
Returns 404 if the plot is not found."
  (let ((key (string-upcase name)))
    (unless (gethash key vega:*all-plots*)
      (setf (hunchentoot:return-code*) 404)
      (setf (hunchentoot:content-type*) "application/json")
      (return-from handle-plot-delete
        (format nil "{\"error\":\"Plot '~A' not found\"}" name)))
    (remhash key vega:*all-plots*)
    (setf (hunchentoot:content-type*) "application/json")
    (format nil "{\"deleted\":\"~A\"}" name)))

;;; Dispatcher

(defun plot-dispatcher (request)
  "Dispatch requests matching /plot or /plot/<name>.
Routes GET and DELETE methods. Returns a handler function or NIL."
  (let ((uri (hunchentoot:script-name request)))
    (cond
      ((string= uri "/plot")
       #'handle-plot-list)
      ((cl-ppcre:scan "^/plot/([\\w\\-]+)$" uri)
       (lambda ()
         (multiple-value-bind (match groups)
             (cl-ppcre:scan-to-strings "^/plot/([\\w\\-]+)$"
                                       (hunchentoot:script-name*))
           (declare (ignore match))
           (let ((name (aref groups 0))
                 (method (hunchentoot:request-method*)))
             (case method
               (:delete (handle-plot-delete name))
               (t       (handle-plot-get name))))))))))

;;; Register dispatcher
(push 'plot-dispatcher hunchentoot:*dispatch-table*)
