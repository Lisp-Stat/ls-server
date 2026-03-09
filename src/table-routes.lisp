;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

;;; Handlers

(defun handle-table-get (name)
  "Handle GET /table/<name> — serve data frame as HTML table or data.
When Accept is application/json or application/vega-json, delegates to
handle-data-get so plot specs referencing /table/<name> URLs receive JSON.
Returns 404 if the data frame is not found."
  (let ((sym (df:find-data-frame name)))
    (unless sym
      (setf (hunchentoot:return-code*) 404)
      (setf (hunchentoot:content-type*) "application/json")
      (return-from handle-table-get
        (format nil "{\"error\":\"Data frame '~A' not found\"}" name)))
    (let ((accept (hunchentoot:header-in* :accept)))
      (if (and accept
               (or (search "application/json" accept)
                   (search "application/vega-json" accept))
               (not (search "text/html" accept)))
          (handle-data-get name)
          (progn
            (setf (hunchentoot:content-type*) "text/html")
            (data-table-page name :documentation (documentation sym 'variable)))))))

;;; Dispatcher

(defun table-dispatcher (request)
  "Dispatch requests matching /table/<name>.
Returns a handler function or NIL."
  (let ((uri (hunchentoot:script-name request)))
    (when (cl-ppcre:scan "^/table/([\\w\\-]+)$" uri)
      (lambda ()
        (multiple-value-bind (match groups)
            (cl-ppcre:scan-to-strings "^/table/([\\w\\-]+)$"
                                      (hunchentoot:script-name*))
          (declare (ignore match))
          (handle-table-get (aref groups 0)))))))

;;; Register dispatcher
(push 'table-dispatcher hunchentoot:*dispatch-table*)
