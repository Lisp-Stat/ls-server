;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER-TESTS -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server-tests)

;;; Suites

(defsuite landing-suite (all-tests))

;;; Tests

(deftest landing-returns-200 (landing-suite)
  "GET / returns HTTP 200."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/"))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest landing-returns-html (landing-suite)
  "GET / returns Content-Type containing text/html."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/"))
    (declare (ignore body status))
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "text/html" content-type)))))

(deftest landing-has-plots-link (landing-suite)
  "GET / HTML contains a link to /plots."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/"))))
    (assert-true (search "/plots" body))))

(deftest landing-has-tables-link (landing-suite)
  "GET / HTML contains a link to /tables."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/"))))
    (assert-true (search "/tables" body))))

;;; Index page tests

(deftest plots-index-returns-200 (landing-suite)
  "GET /plots returns HTTP 200."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/plots"))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest plots-index-returns-html (landing-suite)
  "GET /plots returns text/html content type."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/plots"))
    (declare (ignore body status))
    (let ((ct (gethash "content-type" headers)))
      (assert-true (search "text/html" ct)))))

(deftest plots-index-has-plot-links (landing-suite)
  "GET /plots HTML contains links to individual plots."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((body (dex:get (test-url "/plots"))))
    (assert-true (search "/plot/" body))))

;;; Tests — /plots SPA structure (US-024)

(deftest plots-index-has-vega-embed (landing-suite)
  "GET /plots HTML contains vega-embed CDN script."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/plots"))))
    (assert-true (search "vega-embed" body))))

(deftest plots-index-has-main-plot (landing-suite)
  "GET /plots HTML contains #main-plot div for full-size rendering."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/plots"))))
    (assert-true (search "main-plot" body))))

(deftest plots-index-has-spa-js (landing-suite)
  "GET /plots HTML contains the selectPlot SPA function."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/plots"))))
    (assert-true (search "selectPlot" body))))

(deftest plots-index-has-sidebar (landing-suite)
  "GET /plots HTML contains sidebar container."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/plots"))))
    (assert-true (search "sidebar" body))))

(deftest plots-index-has-context-menu (landing-suite)
  "GET /plots HTML contains context menu for right-click actions."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/plots"))))
    (assert-true (search "context-menu" body))
    (assert-true (search "showContextMenu" body))))

(deftest tables-index-returns-200 (landing-suite)
  "GET /tables returns HTTP 200."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/tables"))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest tables-index-returns-html (landing-suite)
  "GET /tables returns text/html content type."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/tables"))
    (declare (ignore body status))
    (let ((ct (gethash "content-type" headers)))
      (assert-true (search "text/html" ct)))))

(deftest tables-index-has-table-links (landing-suite)
  "GET /tables HTML contains links to individual tables."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/tables"))))
    (assert-true (search "/table/" body))))

(deftest tables-index-has-data-links (landing-suite)
  "GET /tables HTML contains links to data endpoints in card grid."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/tables"))))
    (assert-true (search "/data/" body))))

;;; Tests — favicon (US-044)

(deftest landing-has-favicon (landing-suite)
  "Landing page has a lambda favicon link (US-044)."
  (let ((html (ls-server:landing-page)))
    (assert-true (search "rel='icon'" html))
    (assert-true (search "image/svg+xml" html))))

(deftest tables-index-has-favicon (landing-suite)
  "Tables index page has a lambda favicon link (US-044)."
  (let ((html (ls-server:tables-index-page)))
    (assert-true (search "rel='icon'" html))
    (assert-true (search "image/svg+xml" html))))
