;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

;;; Helpers

(defun parse-media-type-entry (entry)
  "Parse a single Accept header entry like \"text/html;q=0.9\" into
a (media-type . quality) cons.  Returns NIL for malformed entries."
  (let* ((parts (cl-ppcre:split "\\s*;\\s*" (string-trim '(#\Space #\Tab) entry)))
         (media-type (string-downcase (first parts)))
         (quality 1.0d0))
    (when (or (string= media-type "") (null parts))
      (return-from parse-media-type-entry nil))
    (dolist (param (rest parts))
      (when (cl-ppcre:scan "^\\s*q\\s*=" param)
        (let* ((val (string-trim '(#\Space #\Tab)
                                   (cl-ppcre:regex-replace "^\\s*q\\s*=\\s*" param "")))
               ;; Append d0 to force double-float parsing
               (df-str (concatenate 'string val "d0")))
          (handler-case
              (setf quality (read-from-string df-str))
            (error () (setf quality 0.0d0))))))
    (cons media-type quality)))

(defun specificity (media-type)
  "Return a specificity score for MEDIA-TYPE: 0 for */*, 1 for type/*, 2 for type/subtype."
  (cond
    ((string= media-type "*/*") 0)
    ((alexandria:ends-with-subseq "/*" media-type) 1)
    (t 2)))

;;; Public API

(defun parse-accept (accept-header)
  "Parse an Accept header string into a list of (media-type . quality) pairs,
sorted by quality descending, then specificity descending.
E.g. \"text/html, application/json;q=0.9\"
=> ((\"text/html\" . 1.0d0) (\"application/json\" . 0.9d0))"
  (when (or (null accept-header) (string= accept-header ""))
    (return-from parse-accept nil))
  (let* ((entries (cl-ppcre:split "\\s*,\\s*" accept-header))
         (parsed (remove nil (mapcar #'parse-media-type-entry entries))))
    (stable-sort parsed
                 (lambda (a b)
                   (if (= (cdr a) (cdr b))
                       (> (specificity (car a)) (specificity (car b)))
                       (> (cdr a) (cdr b)))))))

(defun media-type-matches-p (pattern candidate)
  "Return T if PATTERN matches CANDIDATE.  Both are downcased strings.
Supports */* and type/* wildcards."
  (cond
    ((string= pattern "*/*") t)
    ((alexandria:ends-with-subseq "/*" pattern)
     (let ((prefix (subseq pattern 0 (- (length pattern) 1))))
       (alexandria:starts-with-subseq prefix candidate)))
    (t (string= pattern candidate))))

(defun negotiate-content-type (accept-header supported-types
                               &key (default (first supported-types)))
  "Select the best matching media type from SUPPORTED-TYPES based on ACCEPT-HEADER.
Returns the matched type string, or DEFAULT if no match.
Handles wildcards: */* matches anything, type/* matches any subtype."
  (when (or (null accept-header) (string= accept-header ""))
    (return-from negotiate-content-type default))
  (let ((parsed (parse-accept accept-header))
        (downcased-supported (mapcar #'string-downcase supported-types)))
    (dolist (entry parsed)
      (let ((pattern (car entry)))
        (dolist (supported downcased-supported)
          (when (media-type-matches-p pattern supported)
            ;; Return the original-case version from supported-types
            (let ((idx (position supported downcased-supported :test #'string=)))
              (return-from negotiate-content-type (nth idx supported-types)))))))
    default))
