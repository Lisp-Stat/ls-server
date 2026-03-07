;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER-TESTS -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server-tests)

;;; Suites

(defsuite negotiation-suite (all-tests))

;;; Tests — parse-accept

(deftest parse-accept-simple (negotiation-suite)
  "Parses a single media type with implicit quality 1.0."
  (let ((result (ls-server:parse-accept "application/json")))
    (assert-eql 1 (length result))
    (assert-equal "application/json" (car (first result)))
    (assert-eql 1.0d0 (cdr (first result)))))

(deftest parse-accept-with-quality (negotiation-suite)
  "Parses multiple types with explicit quality; html (1.0) sorts before json (0.9)."
  (let ((result (ls-server:parse-accept "text/html, application/json;q=0.9")))
    (assert-eql 2 (length result))
    (assert-equal "text/html" (car (first result)))
    (assert-eql 1.0d0 (cdr (first result)))
    (assert-equal "application/json" (car (second result)))
    (assert-eql 0.9d0 (cdr (second result)))))

(deftest parse-accept-empty (negotiation-suite)
  "Returns NIL for empty or NIL input."
  (assert-eql nil (ls-server:parse-accept nil))
  (assert-eql nil (ls-server:parse-accept "")))

;;; Tests — negotiate-content-type

(deftest negotiate-selects-best-match (negotiation-suite)
  "Selects the highest quality match from the supported list."
  (let ((result (ls-server:negotiate-content-type
                 "text/html;q=0.5, application/json;q=0.9"
                 '("text/html" "application/json"))))
    (assert-equal "application/json" result)))

(deftest negotiate-wildcard-star-star (negotiation-suite)
  "The wildcard */* matches the first supported type."
  (let ((result (ls-server:negotiate-content-type
                 "*/*"
                 '("application/json" "text/csv"))))
    (assert-equal "application/json" result)))

(deftest negotiate-wildcard-type-star (negotiation-suite)
  "The wildcard text/* matches text/csv from the supported list."
  (let ((result (ls-server:negotiate-content-type
                 "text/*"
                 '("application/json" "text/csv"))))
    (assert-equal "text/csv" result)))

(deftest negotiate-fallback-default (negotiation-suite)
  "Returns the default when no supported type matches the Accept header."
  (let ((result (ls-server:negotiate-content-type
                 "image/png"
                 '("application/json" "text/csv")
                 :default "application/json")))
    (assert-equal "application/json" result)))

(deftest negotiate-nil-header (negotiation-suite)
  "Returns the default for a NIL Accept header."
  (let ((result (ls-server:negotiate-content-type
                 nil
                 '("application/json" "text/csv"))))
    (assert-equal "application/json" result)))
