;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: CL-USER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(uiop:define-package #:ls-server
  (:use #:cl)
  (:documentation "HTTP server for the Lisp-Stat system. Serves plots (Vega-Embed), data frames (CSV/JSON/sexp), Vega-Lite specs and DataTables views using Accept header content negotiation.")
  (:export #:*server*
           #:*default-port*
           #:*server-host*
           #:*access-log-destination*
           #:*message-log-destination*
           #:start-server
           #:stop-server
           #:parse-accept
           #:negotiate-content-type
           #:find-plot
           #:list-plots
           #:data-table-page
           #:landing-page
           #:plots-index-page
           #:tables-index-page))
