;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

;;; print-object :around methods for data-frame and vega-plot
;;; Include the ls-server URL inside the #<...> output when the server is running.

(defun server-base-url ()
  "Return the base URL of the running server, or NIL if not running."
  (when *server*
    (format nil "http://~A:~A" *server-host*
            (hunchentoot:acceptor-port *server*))))

(defun inject-url-into-output (output url stream)
  "Inject URL into OUTPUT before the final > character, then write to STREAM.
If OUTPUT does not end with >, write it unchanged."
  (let ((close-pos (position #\> output :from-end t)))
    (if close-pos
        (progn
          (write-string (subseq output 0 close-pos) stream)
          (format stream "~%~A >" url))
        (write-string output stream))))

(defmethod print-object :around ((df df:data-frame) stream)
  "When ls-server is running, include the table URL inside #<...> output."
  (if (and *server* (not *print-pretty*) (slot-boundp df 'df:name))
      (let ((output (with-output-to-string (s)
                      (call-next-method df s)))
            (base (server-base-url)))
        (if base
            (inject-url-into-output output
                                    (format nil "~A/table/~A" base (df:name df))
                                    stream)
            (write-string output stream)))
      (call-next-method)))

;;; NOTE: Uses vega::vega-plot, an internal symbol from the vega package.
;;; This is fragile and may break if the vega package changes its class name.
(defmethod print-object :around ((p vega::vega-plot) stream)
  "When ls-server is running, include the plot URL inside #<...> output."
  (if (and *server* (not *print-pretty*))
      (let ((output (with-output-to-string (s)
                      (call-next-method p s)))
            (name (plot:plot-name p))
            (base (server-base-url)))
        (if (and base name)
            (inject-url-into-output output
                                    (format nil "~A/plot/~A" base name)
                                    stream)
            (write-string output stream)))
      (call-next-method)))
