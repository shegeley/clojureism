(use-modules
 (guix gexp)
 ((guix licenses) #:prefix license:)
 (guix packages)
 (guix git-download)
 (guix download)
 (guix utils)
 (guix build-system guile)
 (gnu packages guile)
 (gnu packages package-management))

(define-public guile-srfi-64-ext
 (package
  (name "guile-srfi-64-ext")
  (version "v0.0.1")
  (source (origin
           (method git-fetch)
           (uri (git-reference
                 (url "https://github.com/shegeley/srfi-64-ext")
                 (commit version)))
           (file-name (git-file-name name version))
           (sha256 (base32 "1wzpv9bhbqdnc7jbfszifkg0hbphsd2nh7dsdd5ywz1r46fixqfh"))))
  (build-system guile-build-system)
  (inputs (list guix))
  (native-inputs (list guile-3.0))
  (arguments (list #:source-directory "src"))
  (synopsis "A little testing framework build around (srfi srfi-64)")
  (description "Simple (srfi srfi-64) wrappers from Andrew's Tropin RDE project to make testing easier in any Guile Scheme project")
  (license license:gpl3+)
  (home-page "https://github.com/shegeley/srfi-64-ext")))

 guile-srfi-64-ext
