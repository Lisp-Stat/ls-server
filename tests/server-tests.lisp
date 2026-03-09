;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER-TESTS -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server-tests)

;;; Server lifecycle tests

(defsuite server-suite (all-tests))

(deftest server-starts-and-accepts-connections (server-suite)
  "start-server creates an acceptor that accepts HTTP connections."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/health"))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest server-logs-suppressed-by-default (server-suite)
  "start-server with default config suppresses Hunchentoot log output (US-039)."
  (ensure-test-server)
  (let* ((acceptor ls-server:*server*)
         (access-dest (hunchentoot:acceptor-access-log-destination acceptor))
         (message-dest (hunchentoot:acceptor-message-log-destination acceptor)))
    ;; Log destinations must NOT be *error-output* (the REPL stream)
    (assert-false (eq access-dest *error-output*))
    (assert-false (eq message-dest *error-output*))
    ;; They should be broadcast streams (null sinks)
    (assert-true (typep access-dest 'broadcast-stream))
    (assert-true (typep message-dest 'broadcast-stream))))

(deftest server-stops-cleanly (server-suite)
  "stop-server stops the acceptor and sets *server* to NIL."
  (ensure-test-server)
  (ls-server:stop-server)
  (assert-false ls-server:*server*))

(deftest server-restart-when-running (server-suite)
  "start-server when already running restarts cleanly without error."
  (ensure-test-server)
  (assert-finishes (ls-server:start-server :port *test-port*))
  (multiple-value-bind (body status)
      (dex:get (test-url "/health"))
    (declare (ignore body))
    (assert-eql 200 status)))
