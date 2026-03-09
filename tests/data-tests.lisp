;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER-TESTS -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server-tests)

;;; Suite

(defsuite data-suite (all-tests))

;;; Tests — GET /data (listing)

(deftest data-list-returns-200 (data-suite)
  "GET /data returns HTTP 200."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/data"))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest data-list-returns-json (data-suite)
  "GET /data returns Content-Type application/json."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/data"))
    (declare (ignore body status))
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "application/json" content-type)))))

(deftest data-list-contains-mtcars (data-suite)
  "GET /data response contains MTCARS in the list."
  (ensure-test-server)
  (let* ((body (dex:get (test-url "/data")))
         (parsed (yason:parse body)))
    (assert-true (member "MTCARS" parsed :test #'string=))))

;;; Tests — GET /data/<name> (retrieval with content negotiation)

(deftest data-get-json (data-suite)
  "GET /data/mtcars with Accept: application/json returns 200 with JSON."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/data/mtcars")
               :headers '(("Accept" . "application/json")))
    (assert-eql 200 status)
    (assert-true (> (length body) 0))))

(deftest data-get-vega-json (data-suite)
  "GET /data/mtcars with Accept: application/vega-json returns 200."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/data/mtcars")
               :headers '(("Accept" . "application/vega-json")))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest data-get-csv (data-suite)
  "GET /data/mtcars with Accept: text/csv returns 200 with CSV content."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/data/mtcars")
               :headers '(("Accept" . "text/csv")))
    (assert-eql 200 status)
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "text/csv" content-type)))
    (assert-true (search "," body))))

(deftest data-get-sexp (data-suite)
  "GET /data/mtcars with Accept: text/s-expression returns 200."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/data/mtcars")
               :headers '(("Accept" . "text/s-expression")))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest data-not-found (data-suite)
  "GET /data/nonexistent returns 404."
  (ensure-test-server)
  (handler-case
      (progn
        (dex:get (test-url "/data/nonexistent"))
        (assert-fail "Expected 404 but request succeeded"))
    (dex:http-request-not-found ()
      (assert-true t))))

(deftest data-case-insensitive (data-suite)
  "GET /data/MTCARS works same as /data/mtcars (case-insensitive)."
  (ensure-test-server)
  (multiple-value-bind (body status)
      (dex:get (test-url "/data/MTCARS")
               :headers '(("Accept" . "application/json")))
    (declare (ignore body))
    (assert-eql 200 status)))

(deftest data-no-accept-defaults-csv (data-suite)
  "GET /data/mtcars without Accept header defaults to text/csv."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/data/mtcars"))
    (assert-eql 200 status)
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "text/csv" content-type)))
    (assert-true (search "," body))))

;;; Tests — content-type header verification for all formats

(deftest data-get-json-content-type (data-suite)
  "GET /data/mtcars with Accept: application/json returns Content-Type application/json."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/data/mtcars")
               :headers '(("Accept" . "application/json")))
    (declare (ignore body))
    (assert-eql 200 status)
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "application/json" content-type)))))

(deftest data-get-vega-json-content-type (data-suite)
  "GET /data/mtcars with Accept: application/vega-json returns Content-Type application/vega-json."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/data/mtcars")
               :headers '(("Accept" . "application/vega-json")))
    (declare (ignore body))
    (assert-eql 200 status)
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "application/vega-json" content-type)))))

(deftest data-get-csv-content-type (data-suite)
  "GET /data/mtcars with Accept: text/csv returns Content-Type text/csv."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/data/mtcars")
               :headers '(("Accept" . "text/csv")))
    (declare (ignore body))
    (assert-eql 200 status)
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "text/csv" content-type)))))

(deftest data-get-sexp-content-type (data-suite)
  "GET /data/mtcars with Accept: text/s-expression returns Content-Type text/s-expression."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/data/mtcars")
               :headers '(("Accept" . "text/s-expression")))
    (declare (ignore body))
    (assert-eql 200 status)
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "text/s-expression" content-type)))))

(deftest data-wildcard-defaults-csv (data-suite)
  "GET /data/mtcars with Accept: */* returns text/csv (default)."
  (ensure-test-server)
  (multiple-value-bind (body status headers)
      (dex:get (test-url "/data/mtcars")
               :headers '(("Accept" . "*/*")))
    (declare (ignore body))
    (assert-eql 200 status)
    (let ((content-type (gethash "content-type" headers)))
      (assert-true (search "text/csv" content-type)))))

;;; Tests — floating-point encoding (US-015)

(deftest data-json-float-precision (data-suite)
  "GET /data/mtcars JSON encodes single-floats without IEEE 754 artifacts."
  (ensure-test-server)
  (let ((body (dex:get (test-url "/data/mtcars")
                       :headers '(("Accept" . "application/json")))))
    ;; Verify no single-float precision artifacts appear in the JSON
    (assert-false (search "15.199999" body))
    (assert-false (search "22.799999" body))
    ;; Verify correct values do appear
    (assert-true (search "15.2" body))
    (assert-true (search "22.8" body))))

;;; Helpers — test data frame management

(defun ensure-test-df ()
  "Create a temporary test data frame TEST-DF in the LS-USER package.
Returns the symbol."
  (let ((sym (intern "TEST-DF" (find-package :ls-user))))
    (setf (symbol-value sym)
          (df:make-df '(:name :age :score)
                      '(#("Alice" "Bob" "Carol")
                        #(30 25 35)
                        #(90.0d0 85.0d0 95.0d0))))
    sym))

(defun cleanup-test-df ()
  "Remove the TEST-DF binding from LS-USER."
  (let ((sym (find-symbol "TEST-DF" (find-package :ls-user))))
    (when (and sym (boundp sym))
      (makunbound sym))))

;;; Tests — PUT /data/<name> (replace)

(deftest data-put-replaces-frame (data-suite)
  "PUT /data/test-df with JSON array replaces the data frame."
  (ensure-test-server)
  (unwind-protect
       (progn
         (ensure-test-df)
         (multiple-value-bind (body status)
             (dex:request (test-url "/data/test-df")
                          :method :put
                          :content "[{\"name\":\"Dave\",\"age\":40,\"score\":100.0}]"
                          :headers '(("Content-Type" . "application/json")
                                     ("Accept" . "application/json")))
           (assert-eql 200 status)
           (let* ((parsed (yason:parse body))
                  (first-row (first parsed))
                  (name (gethash "name" first-row)))
             (assert-equal "Dave" name))))
    (cleanup-test-df)))

(deftest data-put-before-after (data-suite)
  "PUT replaces a data frame and GET returns the new data."
  (ensure-test-server)
  (unwind-protect
       (progn
         (ensure-test-df)
         ;; Before: verify initial state has 3 rows
         (let* ((before (dex:get (test-url "/data/test-df")
                                 :headers '(("Accept" . "application/json"))))
                (before-rows (yason:parse before)))
           (assert-eql 3 (length before-rows))
           (assert-true (search "Alice" before)))
         ;; PUT: replace with new 2-row data
         (dex:request (test-url "/data/test-df")
                      :method :put
                      :content "[{\"name\":\"X\",\"age\":1,\"score\":10.0},{\"name\":\"Y\",\"age\":2,\"score\":20.0}]"
                      :headers '(("Content-Type" . "application/json")
                                 ("Accept" . "application/json")))
         ;; After: GET and verify replacement
         (let* ((after (dex:get (test-url "/data/test-df")
                                :headers '(("Accept" . "application/json"))))
                (after-rows (yason:parse after)))
           (assert-eql 2 (length after-rows))
           (assert-true (search "X" after))
           (assert-true (search "Y" after))
           (assert-false (search "Alice" after))))
    (cleanup-test-df)))

(deftest data-put-not-found (data-suite)
  "PUT /data/nonexistent returns 404."
  (ensure-test-server)
  (handler-case
      (progn
        (dex:request (test-url "/data/nonexistent")
                     :method :put
                     :content "[{\"x\":1}]"
                     :headers '(("Content-Type" . "application/json")))
        (assert-fail "Expected 404 but request succeeded"))
    (dex:http-request-not-found ()
      (assert-true t))))

(deftest data-put-invalid-json (data-suite)
  "PUT /data/test-df with invalid JSON returns 400."
  (ensure-test-server)
  (unwind-protect
       (progn
         (ensure-test-df)
         (handler-case
             (progn
               (dex:request (test-url "/data/test-df")
                            :method :put
                            :content "NOT-JSON{{{{"
                            :headers '(("Content-Type" . "application/json")))
               (assert-fail "Expected 400 but request succeeded"))
           (dex:http-request-bad-request ()
             (assert-true t))))
    (cleanup-test-df)))

;;; Tests — PATCH /data/<name> (update cells)

(deftest data-patch-updates-row (data-suite)
  "PATCH /data/test-df updates a cell in the data frame."
  (ensure-test-server)
  (unwind-protect
       (progn
         (ensure-test-df)
         (multiple-value-bind (body status)
             (dex:request (test-url "/data/test-df")
                          :method :patch
                          :content "{\"updates\":[{\"row\":0,\"column\":\"score\",\"value\":99.0}]}"
                          :headers '(("Content-Type" . "application/json")
                                     ("Accept" . "application/json")))
           (assert-eql 200 status)
           (let* ((parsed (yason:parse body))
                  (score-found nil))
             ;; Find the row with updated score
             (dolist (row parsed)
               (let ((val (gethash "score" row)))
                 (when (and val (= val 99.0d0))
                   (setf score-found t))))
             (assert-true score-found))))
    (cleanup-test-df)))

(deftest data-patch-not-found (data-suite)
  "PATCH /data/nonexistent returns 404."
  (ensure-test-server)
  (handler-case
      (progn
        (dex:request (test-url "/data/nonexistent")
                     :method :patch
                     :content "{\"updates\":[{\"row\":0,\"column\":\"x\",\"value\":1}]}"
                     :headers '(("Content-Type" . "application/json")))
        (assert-fail "Expected 404 but request succeeded"))
    (dex:http-request-not-found ()
      (assert-true t))))

;;; Tests — data frames with NA values (US-031)

(defun ensure-na-df ()
  "Create a test data frame with :NA symbol values.
Simulates data like vgcars where some columns contain :NA."
  (let ((sym (intern "NA-TEST-DF" (find-package :ls-user))))
    (setf (symbol-value sym)
          (df:make-df '(:name :value)
                      (list #("A" "B" "C")
                            (make-array 3 :initial-contents '(1 :na 3)))))
    sym))

(defun cleanup-na-df ()
  "Remove the NA-TEST-DF binding from LS-USER."
  (let ((sym (find-symbol "NA-TEST-DF" (find-package :ls-user))))
    (when (and sym (boundp sym))
      (makunbound sym))))

(deftest data-na-values-return-json (data-suite)
  "GET /data/<name> with :NA values returns valid JSON with null."
  (ensure-test-server)
  (unwind-protect
       (progn
         (ensure-na-df)
         (multiple-value-bind (body status)
             (dex:get (test-url "/data/na-test-df")
                      :headers '(("Accept" . "application/json")))
           (assert-eql 200 status)
           (assert-true (search "null" body))))
    (cleanup-na-df)))

(deftest data-na-values-vega-json (data-suite)
  "GET /data/<name> with :NA values returns valid Vega JSON with null."
  (ensure-test-server)
  (unwind-protect
       (progn
         (ensure-na-df)
         (multiple-value-bind (body status)
             (dex:get (test-url "/data/na-test-df")
                      :headers '(("Accept" . "application/vega-json"))
                      :force-string t)
           (assert-eql 200 status)
           (assert-true (search "null" body))))
    (cleanup-na-df)))
