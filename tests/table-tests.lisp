;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER-TESTS -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server-tests)

;;; Suite

(defsuite table-suite (all-tests))

;;; Tests — GET /table/<name>

(deftest table-returns-200 (table-suite)
  "GET /table/mtcars returns HTTP 200."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/table/mtcars"))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest table-returns-html (table-suite)
  "GET /table/mtcars returns Content-Type text/html."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/table/mtcars"))
    (declare (ignore body status))
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "text/html" content-type)))))

(deftest table-has-handsontable-css (table-suite)
  "GET /table/mtcars HTML contains Handsontable CSS CDN link."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/table/mtcars"))))
    (assert-true (search "handsontable.full.min.css" body))))

(deftest table-has-handsontable-js (table-suite)
  "GET /table/mtcars HTML contains Handsontable JS CDN link."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/table/mtcars"))))
    (assert-true (search "handsontable.full.min.js" body))))

(deftest table-fetches-data-url (table-suite)
  "GET /table/mtcars HTML contains fetch URL /data/mtcars."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/table/mtcars"))))
    (assert-true (search "/data/mtcars" body))))

(deftest table-not-found (table-suite)
  "GET /table/nonexistent returns 404."
  (ensure-test-server)
  (handler-case
      (progn
        (dex:get (test-url "/table/nonexistent"))
        (assert-fail "Expected 404 but request succeeded"))
    (dex:http-request-not-found ()
      (assert-true t))))

(deftest table-has-documentation (table-suite)
  "GET /table/mtcars HTML contains the data-frame documentation."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/table/mtcars"))))
    (assert-true (search "Documentation" body))
    (assert-true (search "Motor Trend" body))))

;;; Tests — Save/Cancel batch mode (US-022)

(deftest table-has-save-button (table-suite)
  "GET /table/mtcars HTML contains a Save button."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/table/mtcars"))))
    (assert-true (search "save-btn" body))
    (assert-true (search "saveData()" body))))

(deftest table-has-cancel-button (table-suite)
  "GET /table/mtcars HTML contains a Cancel button."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/table/mtcars"))))
    (assert-true (search "cancel-btn" body))
    (assert-true (search "cancelEdits()" body))))

(deftest table-no-afterchange-patch (table-suite)
  "GET /table/mtcars HTML does not contain the old afterChange PATCH handler."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/table/mtcars"))))
    (assert-false (search "afterChange" body))))

;;; Tests — content negotiation (US-035)

(deftest table-json-accept-returns-json (table-suite)
  "GET /table/mtcars with Accept: application/json returns JSON data."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/table/mtcars")
               :headers '(("Accept" . "application/json")))
    (assert-eql 200 status)
    (let ((ct (gethash "content-type" headers)))
      (assert-true (search "application/json" ct)))
    (assert-true (search "mpg" body))))

(deftest table-vega-json-accept-returns-json (table-suite)
  "GET /table/mtcars with Accept: application/vega-json returns Vega JSON."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/table/mtcars")
               :headers '(("Accept" . "application/vega-json"))
               :force-string t)
    (assert-eql 200 status)
    (let ((ct (gethash "content-type" headers)))
      (assert-true (search "application/vega-json" ct)))
    (assert-true (search "mpg" body))))

(deftest table-html-accept-returns-html (table-suite)
  "GET /table/mtcars with Accept: text/html returns HTML page."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/table/mtcars")
               :headers '(("Accept" . "text/html")))
    (assert-eql 200 status)
    (let ((ct (gethash "content-type" headers)))
      (assert-true (search "text/html" ct)))
    (assert-true (search "handsontable" body))))

(deftest table-page-has-favicon (table-suite)
  "Data table page has a lambda favicon link (US-044)."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/table/mtcars")
                       :headers '(("Accept" . "text/html")))))
    (assert-true (search "rel='icon'" body))))
