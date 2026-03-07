;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

;;; Configuration — all user-facing options and feature flags

(defparameter *default-port* 20202
  "Default port for the ls-server HTTP server.")

(defparameter *server-host* "localhost"
  "Hostname used in printed URLs. Default is localhost.")

(defparameter *access-log-destination* nil
  "Destination for Hunchentoot access log.
When NIL, logs are suppressed (sent to a broadcast stream with no targets).
Set to a pathname string to redirect access logs to a file,
or to *error-output* for REPL debugging.")

(defparameter *message-log-destination* nil
  "Destination for Hunchentoot message/error log.
When NIL, logs are suppressed (sent to a broadcast stream with no targets).
Set to a pathname string to redirect message logs to a file,
or to *error-output* for REPL debugging.")


