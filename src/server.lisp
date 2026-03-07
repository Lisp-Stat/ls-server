;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

(defvar *server* nil
  "The currently running Hunchentoot acceptor instance, or NIL.")

(defun start-server (&key (port *default-port*))
  "Start the ls-server HTTP server on PORT.
Creates an easy-acceptor and stores it in *SERVER*."
  (when *server*
    (warn "Server already running; stopping first.")
    (stop-server))
  (let ((acceptor (make-instance 'hunchentoot:easy-acceptor
                                 :port port
                                 :access-log-destination (or *access-log-destination*
                                                            (make-broadcast-stream))
                                 :message-log-destination (or *message-log-destination*
                                                             (make-broadcast-stream)))))
    (hunchentoot:start acceptor)
    (setf *server* acceptor)))

(defun stop-server ()
  "Stop the running ls-server HTTP server and set *SERVER* to NIL."
  (when *server*
    (hunchentoot:stop *server*)
    (setf *server* nil)))
