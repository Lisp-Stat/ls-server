;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER-TESTS -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server-tests)

;;; Helpers — grouped at top, before suites

(defparameter *test-port* 20293
  "Port used for the test HTTP server.")

(defparameter *test-base-url*
  (format nil "http://127.0.0.1:~D" *test-port*)
  "Base URL for the test HTTP server.")

(defun ensure-test-server ()
  "Start the test server on *TEST-PORT* if it is not already running.
Polls the health endpoint to confirm readiness instead of sleeping.
Signals an error if the server fails to become ready."
  (ls-server:start-server :port *test-port*)
  (loop repeat 100
        when (handler-case
                 (progn (dex:get (format nil "~A/health" *test-base-url*))
                        t)
               (error () nil))
          do (return)
        do (sleep 0.01d0)
        finally (error "Test server failed to start on port ~D" *test-port*)))

(defun stop-test-server ()
  "Stop the test server if it is running."
  (ls-server:stop-server))

(defun test-url (path)
  "Build a full test URL from PATH (e.g. \"/health\")."
  (concatenate 'string *test-base-url* path))

;;; Suites

(defsuite health-suite (all-tests))

;;; Tests

(deftest health-returns-200 (health-suite)
  "GET /health returns HTTP 200."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/health"))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest health-returns-json (health-suite)
  "GET /health returns Content-Type application/json."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/health"))
    (declare (ignore body status))
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "application/json" content-type)))))

(deftest health-body-has-status-ok (health-suite)
  "GET /health returns JSON body with status=ok."
  (ensure-test-server)
  (let* ((body (dex:get (test-url "/health")))
         (parsed (yason:parse body))
         (status (gethash "status" parsed)))
    (assert-equal "ok" status)))
