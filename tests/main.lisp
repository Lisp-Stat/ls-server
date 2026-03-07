;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER-TESTS -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server-tests)

;;; Root suite
(defsuite all-tests ())

;;; Test runner
(defun run-tests (&optional (report-progress t))
  "Run all ls-server test suites. Returns the clunit-report object.

Binds *test-output-stream* to the current *standard-output* because
clunit2 initialises *test-output-stream* at load time; if the system
was loaded with (ql:quickload :silent t) that stream is a null broadcast
stream that discards all output.  Ensures the test server is stopped
after tests complete."
  (let ((*print-pretty* t)
        (clunit:*test-output-stream* *standard-output*))
    (unwind-protect
         (run-suite 'all-tests :report-progress report-progress)
      (stop-test-server))))

;;; Seed test — validates the harness works
(deftest harness-sanity (all-tests)
  "Validates that the test harness loads and runs."
  (assert-true t))
