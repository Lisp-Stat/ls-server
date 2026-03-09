;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

;;; Health-check endpoint
(hunchentoot:define-easy-handler (health-handler :uri "/health") ()
  "Return a JSON health-check response."
  (setf (hunchentoot:content-type*) "application/json")
  "{\"status\":\"ok\"}")
