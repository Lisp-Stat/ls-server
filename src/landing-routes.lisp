;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

;;; Handlers

(defun handle-landing ()
  "Handle GET / — serve the landing page."
  (setf (hunchentoot:content-type*) "text/html")
  (landing-page))

(defun handle-plots-index ()
  "Handle GET /plots — serve the plots index page."
  (setf (hunchentoot:content-type*) "text/html")
  (plots-index-page))

(defun handle-tables-index ()
  "Handle GET /tables — serve the tables index page."
  (setf (hunchentoot:content-type*) "text/html")
  (tables-index-page))

;;; Dispatcher

(defun landing-dispatcher (request)
  "Dispatch requests matching /, /plots, or /tables.
Returns a handler function or NIL."
  (let ((uri (hunchentoot:script-name request)))
    (cond
      ((string= uri "/") #'handle-landing)
      ((string= uri "/plots") #'handle-plots-index)
      ((string= uri "/tables") #'handle-tables-index))))

;;; Register dispatcher
(push 'landing-dispatcher hunchentoot:*dispatch-table*)
