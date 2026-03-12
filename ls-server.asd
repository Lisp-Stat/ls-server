;;; -*- Mode: LISP; Syntax: ANSI-Common-lisp; Package: ASDF -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(defsystem "ls-server"
  :name "LS-Server"
  :version "1.0.2"
  :license :MS-PL
  :author "Steve Nunez <steve@symbolics.tech>"
  :description "HTTP server for the Lisp-Stat system"
  :long-description "Serves plots (Vega-Embed), data frames (CSV/JSON/sexp), Vega-Lite specs, and DataTables views using Accept header content negotiation."
  :homepage "https://lisp-stat.dev/"
  :source-control (:git "https://github.com/Lisp-Stat/ls-server.git")
  :bug-tracker "https://github.com/Lisp-Stat/ls-server/issues"
  :depends-on ("hunchentoot"
               "yason"
               "cl-ppcre"
               "cl-who"
               "alexandria"
               "data-frame"
               "dfio"
               "plot/vega")
  :pathname "src/"
  :components ((:file "pkgdcl")
               (:file "config" :depends-on ("pkgdcl"))
               (:file "negotiation" :depends-on ("pkgdcl"))
               (:file "server" :depends-on ("pkgdcl" "config"))
               (:file "health" :depends-on ("pkgdcl" "server"))
               (:file "data-routes" :depends-on ("pkgdcl" "negotiation"))
               (:file "html" :depends-on ("pkgdcl"))
               (:file "plot-routes" :depends-on ("pkgdcl" "negotiation" "html"))
               (:file "table-routes" :depends-on ("pkgdcl" "data-routes" "html"))
               (:file "landing-routes" :depends-on ("pkgdcl" "html" "data-routes" "plot-routes"))
               (:file "print-extensions" :depends-on ("pkgdcl" "config" "server")))
  :in-order-to ((test-op (test-op "ls-server/tests"))))

(defsystem "ls-server/tests"
  :description "Tests for ls-server"
  :depends-on ("ls-server"
               "clunit2"
               "dexador")
  :pathname "tests/"
  :components ((:file "test-package")
               (:file "main" :depends-on ("test-package"))
               (:file "health-tests" :depends-on ("test-package" "main"))
               (:file "server-tests" :depends-on ("test-package" "main" "health-tests"))
               (:file "negotiation-tests" :depends-on ("test-package" "main"))
               (:file "data-tests" :depends-on ("test-package" "main" "health-tests"))
               (:file "plot-tests" :depends-on ("test-package" "main" "health-tests"))
               (:file "table-tests" :depends-on ("test-package" "main" "health-tests"))
               (:file "landing-tests" :depends-on ("test-package" "main" "health-tests" "plot-tests"))
               (:file "print-tests" :depends-on ("test-package" "main" "health-tests" "plot-tests")))
  :perform (test-op (o s)
             (uiop:symbol-call :ls-server-tests :run-tests)))
