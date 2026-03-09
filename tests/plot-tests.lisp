;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER-TESTS -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server-tests)

;;; Helpers — grouped at top

(defun ensure-test-plot ()
  "Create a test plot in vega:*all-plots* for integration tests.
Uses vega::%defplot with a complete bar chart spec including data,
mark, and encoding so Vega-Embed renders a visible visualization.
NOTE: Uses vega::%defplot, an internal function from the vega package.
This is fragile and may break if the vega package changes its internal API."
  (unless (gethash "TEST-PLOT" vega:*all-plots*)
    (let* ((spec '(:mark :bar
                   :data (:values #((:a "A" :b 28)
                                    (:a "B" :b 55)
                                    (:a "C" :b 43)))
                   :encoding (:x (:field :a :type :nominal)
                              :y (:field :b :type :quantitative))))
           (plot (vega::%defplot 'test-plot spec)))
      (setf (gethash "TEST-PLOT" vega:*all-plots*) plot))))

(defun ensure-url-test-plot ()
  "Create a test plot that references data via /data/mtcars URL.
NOTE: Uses vega::%defplot, an internal function from the vega package."
  (unless (gethash "URL-TEST-PLOT" vega:*all-plots*)
    (let* ((spec `(:mark :point
                   :data (:url "/data/mtcars")
                   :encoding (:x (:field "mpg" :type :quantitative)
                              :y (:field "hp" :type :quantitative))))
           (plot (vega::%defplot 'url-test-plot spec)))
      (setf (gethash "URL-TEST-PLOT" vega:*all-plots*) plot))))

(defun extract-spec-from-html (html)
  "Extract the Vega-Lite spec JSON string from a Vega-Embed HTML page.
Looks for 'var spec = {...};' and returns the JSON string."
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings "var spec = (\\{.*\\});\\s*vegaEmbed" html
                                :sharedp t)
    (declare (ignore match))
    (when groups (aref groups 0))))

(defun remove-test-plot ()
  "Remove the test plot from vega:*all-plots*."
  (remhash "TEST-PLOT" vega:*all-plots*))

;;; Suite

(defsuite plot-suite (all-tests))

;;; Tests — GET /plot (listing)

(deftest plot-list-returns-200 (plot-suite)
  "GET /plot returns HTTP 200."
  (ensure-test-server)
  (ensure-test-plot)
  (multiple-value-bind (body status)
      (dex:get (test-url "/plot"))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest plot-list-returns-json (plot-suite)
  "GET /plot returns Content-Type application/json."
  (ensure-test-server)
  (ensure-test-plot)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/plot"))
    (declare (ignore body status))
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "application/json" content-type)))))

;;; Tests — GET /plot/<name> with Accept: application/vega-json (US-008)

(deftest plot-spec-returns-vega-json (plot-suite)
  "GET /plot/test-plot with Accept: application/vega-json returns 200 with spec."
  (ensure-test-server)
  (ensure-test-plot)
  (multiple-value-bind (body status)
      (dex:get (test-url "/plot/test-plot")
               :headers '(("Accept" . "application/vega-json")))
    (assert-eql 200 status)
    (assert-true (> (length body) 0))))

(deftest plot-spec-has-schema (plot-suite)
  "GET /plot/test-plot spec response contains $schema key."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((body (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "application/vega-json")))))
    (assert-true (search "$schema" body))))

(deftest plot-spec-has-data (plot-suite)
  "GET /plot/test-plot spec response contains data values."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((body (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "application/vega-json")))))
    (assert-true (search "values" body))
    (assert-true (search "bar" body))))

(deftest plot-spec-content-type (plot-suite)
  "GET /plot/test-plot with Accept: application/vega-json returns correct Content-Type."
  (ensure-test-server)
  (ensure-test-plot)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/plot/test-plot")
               :headers '(("Accept" . "application/vega-json")))
    (declare (ignore body status))
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "application/vega-json" content-type)))))

;;; Tests — GET /plot/<name> with Accept: text/html (US-009)

(deftest plot-html-returns-html (plot-suite)
  "GET /plot/test-plot with Accept: text/html returns 200 with HTML."
  (ensure-test-server)
  (ensure-test-plot)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/plot/test-plot")
               :headers '(("Accept" . "text/html")))
    (assert-eql 200 status)
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "text/html" content-type)))
    (assert-true (> (length body) 0))))

(deftest plot-html-has-vega-embed (plot-suite)
  "GET /plot/test-plot HTML response contains vegaEmbed call."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((body (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "text/html")))))
    (assert-true (search "vegaEmbed" body))))

(deftest plot-html-has-cdn (plot-suite)
  "GET /plot/test-plot HTML response contains jsDelivr CDN links."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((body (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "text/html")))))
    (assert-true (search "cdn.jsdelivr.net" body))))

(deftest plot-html-has-loader-header (plot-suite)
  "GET /plot/test-plot HTML response contains application/vega-json in loader config."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((body (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "text/html")))))
    (assert-true (search "application/vega-json" body))))

;;; Tests — 404 for nonexistent plots

(deftest plot-not-found (plot-suite)
  "GET /plot/nonexistent returns 404."
  (ensure-test-server)
  (handler-case
      (progn
        (dex:get (test-url "/plot/nonexistent")
                 :headers '(("Accept" . "application/vega-json")))
        (assert-fail "Expected 404 but request succeeded"))
    (dex:http-request-not-found ()
      (assert-true t))))

;;; Tests — end-to-end plot verification (US-018)

(deftest plot-html-spec-has-correct-schema (plot-suite)
  "HTML page embeds spec with correct Vega-Lite v6 schema URL."
  (ensure-test-server)
  (ensure-test-plot)
  (let* ((html (dex:get (test-url "/plot/test-plot")
                        :headers '(("Accept" . "text/html"))))
         (spec-json (extract-spec-from-html html))
         (spec (yason:parse spec-json))
         (schema (gethash "$schema" spec)))
    (assert-equal "https://vega.github.io/schema/vega-lite/v6.json" schema)))

(deftest plot-html-spec-has-inline-data (plot-suite)
  "HTML page spec contains inline data values for test plot."
  (ensure-test-server)
  (ensure-test-plot)
  (let* ((html (dex:get (test-url "/plot/test-plot")
                        :headers '(("Accept" . "text/html"))))
         (spec-json (extract-spec-from-html html))
         (spec (yason:parse spec-json))
         (data (gethash "data" spec))
         (values (gethash "values" data))
         (first-a (gethash "a" (first values))))
    (assert-eql 3 (length values))
    (assert-equal "A" first-a)))

(deftest plot-url-data-fetchable (plot-suite)
  "Plot with data URL: fetch the URL and verify it returns expected data."
  (ensure-test-server)
  (ensure-url-test-plot)
  (let* ((html (dex:get (test-url "/plot/url-test-plot")
                        :headers '(("Accept" . "text/html"))))
         (spec-json (extract-spec-from-html html))
         (spec (yason:parse spec-json))
         (data (gethash "data" spec))
         (data-url (gethash "url" data)))
    ;; Verify spec has a data URL
    (assert-equal "/data/mtcars" data-url)
    ;; Fetch the data URL from the server
    (let ((data-body (dex:get (test-url data-url)
                              :headers '(("Accept" . "application/json")))))
      (assert-true (> (length data-body) 0))
      ;; Verify it parses as JSON with multiple rows
      (let ((parsed (yason:parse data-body)))
        (assert-true (> (length parsed) 10))))))

;;; Tests — DELETE /plot/<name> (US-025)

(defun ensure-deletable-plot ()
  "Create a plot specifically for delete testing.
NOTE: Uses vega::%defplot, an internal function from the vega package.
This is fragile and may break if the vega package changes its internal API."
  (let* ((spec '(:mark :bar
                 :data (:values #((:x "A" :y 1)))))
         (plot (vega::%defplot 'delete-me spec)))
    (setf (gethash "DELETE-ME" vega:*all-plots*) plot)))

(deftest plot-delete-returns-200 (plot-suite)
  "DELETE /plot/delete-me returns 200 and removes the plot."
  (ensure-test-server)
  (ensure-deletable-plot)
  (multiple-value-bind (body status)
      (dex:delete (test-url "/plot/delete-me"))
    (assert-eql 200 status)
    (assert-true (search "deleted" body))))

(deftest plot-delete-removes-plot (plot-suite)
  "After DELETE, GET /plot/delete-me returns 404."
  (ensure-test-server)
  (ensure-deletable-plot)
  (dex:delete (test-url "/plot/delete-me"))
  (handler-case
      (progn
        (dex:get (test-url "/plot/delete-me")
                 :headers '(("Accept" . "application/vega-json")))
        (assert-fail "Expected 404 but request succeeded"))
    (dex:http-request-not-found ()
      (assert-true t))))

(deftest plot-delete-nonexistent-404 (plot-suite)
  "DELETE /plot/nonexistent returns 404."
  (ensure-test-server)
  (handler-case
      (progn
        (dex:delete (test-url "/plot/nonexistent-plot-xyz"))
        (assert-fail "Expected 404 but request succeeded"))
    (dex:http-request-not-found ()
      (assert-true t))))

(deftest plots-spa-has-actions-menu (plot-suite)
  "Plots SPA page explicitly enables VegaEmbed actions menu (US-041)."
  (let ((html (ls-server:plots-index-page)))
    (assert-false (search "actions: false" html))
    (assert-true (search "actions: true" html))
    (assert-true (search "vegaEmbed" html))))

(deftest plot-embed-page-has-actions-menu (plot-suite)
  "Individual plot embed page explicitly enables VegaEmbed actions menu (US-041)."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((html (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "text/html")))))
    (assert-false (search "actions: false" html))
    (assert-true (search "actions: true" html))))

(deftest plots-spa-thumbnail-uses-loader (plot-suite)
  "Plots SPA renderThumbnail uses custom vega loader with Accept header (US-040)."
  (let ((html (ls-server:plots-index-page)))
    (assert-true (search "vega.loader" html))
    (assert-true (search "runAsync" html))))

(deftest plots-spa-has-resize-handle (plot-suite)
  "Plots SPA page contains resize handle element and CSS."
  (let ((html (ls-server:plots-index-page)))
    (assert-true (search "resize-handle" html))
    (assert-true (search "col-resize" html))
    (assert-true (search "isResizing" html))))

(deftest plots-spa-actions-not-clipped (plot-suite)
  "Plots SPA CSS ensures VegaEmbed actions menu is not clipped (US-042)."
  (let ((html (ls-server:plots-index-page)))
    ;; .vega-embed must have overflow: visible so actions dropdown is not clipped
    (assert-true (search "vega-embed" html))
    (assert-true (search "overflow: visible" html))
    ;; .vega-actions must have z-index so dropdown renders above other content
    (assert-true (search "vega-actions" html))
    (assert-true (search "z-index" html))))

(deftest plot-embed-page-no-actions-css-conflict (plot-suite)
  "Individual plot embed page has no CSS that would clip VegaEmbed actions (US-042)."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((html (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "text/html")))))
    ;; Individual page should not have overflow: auto that clips actions
    (assert-false (search "overflow: auto" html))
    ;; Should not have overflow: hidden on the embed container
    (assert-false (search "overflow: hidden" html))))

(deftest plots-spa-main-plot-natural-size (plot-suite)
  "Plots SPA #main-plot uses natural VegaEmbed sizing, not full width/height (US-045).
The #main-plot container must not force width/height so VegaEmbed sizes to the plot."
  (let ((html (ls-server:plots-index-page)))
    ;; #main-plot should not have width or height forcing full-panel fill
    (assert-false (search "#main-plot { width:" html))
    (assert-true (search "#main-plot {" html))))

(deftest plot-embed-white-background (plot-suite)
  "Individual plot page has explicit white background (US-045)."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((html (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "text/html")))))
    (assert-true (search "background: #fff" html))))

(deftest plots-spa-has-favicon (plot-suite)
  "Plots SPA page has a lambda favicon link (US-044)."
  (let ((html (ls-server:plots-index-page)))
    (assert-true (search "rel='icon'" html))
    (assert-true (search "image/svg+xml" html))))

(deftest plot-embed-has-favicon (plot-suite)
  "Individual plot embed page has a lambda favicon link (US-044)."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((html (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "text/html")))))
    (assert-true (search "rel='icon'" html))))

;;; Tests — server-side URL rewriting for port independence

(defun ensure-stale-url-plot ()
  "Create a test plot whose spec contains an absolute localhost:20202 data URL.
Simulates a plot created while the server was running on port 20202.
NOTE: Uses vega::%defplot, an internal function from the vega package.
This is fragile and may break if the vega package changes its internal API."
  (unless (gethash "STALE-URL-PLOT" vega:*all-plots*)
    (let* ((spec '(:mark :point
                   :data (:url "http://localhost:20202/data/mtcars")
                   :encoding (:x (:field "mpg" :type :quantitative)
                              :y (:field "hp"  :type :quantitative))))
           (plot (vega::%defplot 'stale-url-plot spec)))
      (setf (gethash "STALE-URL-PLOT" vega:*all-plots*) plot))))

(deftest plot-spec-absolute-localhost-url-rewritten (plot-suite)
  "GET /plot spec response rewrites http://localhost:20202/PATH to /PATH."
  (ensure-test-server)
  (ensure-stale-url-plot)
  (let* ((body (dex:get (test-url "/plot/stale-url-plot")
                        :headers '(("Accept" . "application/vega-json"))))
         (spec (yason:parse body))
         (data (gethash "data" spec))
         (data-url (gethash "url" data)))
    (assert-false (search "localhost:20202" (or data-url ""))
                  "Served spec must not contain stale absolute URL with port 20202")
    (assert-equal "/data/mtcars" data-url)))

(deftest plot-spec-relative-url-survives-rewrite (plot-suite)
  "GET /plot spec response does not alter already-relative data URLs."
  (ensure-test-server)
  (ensure-url-test-plot)
  (let* ((body (dex:get (test-url "/plot/url-test-plot")
                        :headers '(("Accept" . "application/vega-json"))))
         (spec (yason:parse body))
         (data (gethash "data" spec))
         (data-url (gethash "url" data)))
    (assert-equal "/data/mtcars" data-url)))

(deftest plot-html-page-has-base-url-loader (plot-suite)
  "Plots SPA HTML includes baseURL: window.location.origin in Vega loader config."
  (let ((html (ls-server:plots-index-page)))
    (assert-true (search "window.location.origin" html))
    (assert-true (search "baseURL" html))))

(deftest plot-embed-page-has-base-url-loader (plot-suite)
  "Individual plot embed page has baseURL: window.location.origin in vegaEmbed loader."
  (ensure-test-server)
  (ensure-test-plot)
  (let ((html (dex:get (test-url "/plot/test-plot")
                       :headers '(("Accept" . "text/html")))))
    (assert-true (search "window.location.origin" html))
    (assert-true (search "baseURL" html))))
