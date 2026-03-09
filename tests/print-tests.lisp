;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER-TESTS -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server-tests)

;;; Suite

(defsuite print-suite (all-tests))

;;; Tests — data-frame print-object URL (US-026, US-030)

(deftest print-df-shows-url-when-server-running (print-suite)
  "print-object for data-frame includes /table/ URL inside #<...> output."
  (ensure-test-server)
  (let* ((sym (df:find-data-frame "mtcars"))
         (df (symbol-value sym))
         (output (let ((*print-pretty* nil))
                   (prin1-to-string df))))
    (assert-true (search "/table/MTCARS" output))
    ;; URL must appear before the closing >
    (let ((url-pos (search "/table/MTCARS" output))
          (close-pos (position #\> output :from-end t)))
      (assert-true (< url-pos close-pos)))
    ;; Space before closing > so URL is clickable (US-038)
    (let ((close-pos (position #\> output :from-end t)))
      (assert-eql #\Space (char output (1- close-pos))))))

(deftest print-df-no-url-when-server-stopped (print-suite)
  "print-object for data-frame has no URL when server is not running."
  (stop-test-server)
  (let* ((sym (df:find-data-frame "mtcars"))
         (df (symbol-value sym))
         (output (let ((*print-pretty* nil))
                   (prin1-to-string df))))
    (assert-false (search "/table/" output))))

(deftest print-df-preserves-description (print-suite)
  "print-object for data-frame preserves the docstring/description."
  (ensure-test-server)
  (let* ((sym (df:find-data-frame "mtcars"))
         (df (symbol-value sym))
         (output (let ((*print-pretty* nil))
                   (prin1-to-string df))))
    (assert-true (search "observations" output))))

;;; Tests — vega-plot print-object URL (US-026, US-030)

(deftest print-plot-shows-url-when-server-running (print-suite)
  "print-object for vega-plot includes /plot/ URL inside #<...> output."
  (ensure-test-server)
  (ensure-test-plot)
  (let* ((plot (gethash "TEST-PLOT" vega:*all-plots*))
         (output (let ((*print-pretty* nil))
                   (prin1-to-string plot))))
    (assert-true (search "/plot/TEST-PLOT" output))
    ;; URL must appear before the closing >
    (let ((url-pos (search "/plot/TEST-PLOT" output))
          (close-pos (position #\> output :from-end t)))
      (assert-true (< url-pos close-pos)))
    ;; Space before closing > so URL is clickable (US-038)
    (let ((close-pos (position #\> output :from-end t)))
      (assert-eql #\Space (char output (1- close-pos))))))

(deftest print-plot-no-url-when-server-stopped (print-suite)
  "print-object for vega-plot has no URL when server is not running."
  (stop-test-server)
  (ensure-test-plot)
  (let* ((plot (gethash "TEST-PLOT" vega:*all-plots*))
         (output (let ((*print-pretty* nil))
                   (prin1-to-string plot))))
    (assert-false (search "/plot/" output))))
