;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: CL-USER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(uiop:define-package #:ls-server-tests
  (:documentation "Tests for ls-server")
  (:use #:cl
        #:clunit)
  (:export #:run-tests))
