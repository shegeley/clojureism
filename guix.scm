(use-modules
 (gnu packages guile)

 ((guix licenses) #:prefix license:)
 (guix build-system guile)
 (guix download)
 (guix gexp)
 (guix git-download)
 (guix packages)
 (guix utils)

 (packages srfi srfi-125))

(define %source-dir (dirname (current-filename)))

(define-public clojureism
  (package
    (name "clojureism")
    (version "0.1")
    (source (local-file %source-dir
              #:recursive? #t
              #:select? (git-predicate %source-dir)))
    (build-system guile-build-system)
    (arguments (list #:source-directory "src"))
    (propagated-inputs (list guile-srfi-125))
    (native-inputs (list guile-3.0))
    (synopsis "Small guile scheme libriary to provide clojure-alike atom, vector and hash-map basic procedures")
    (description "The point of this small libriary is to mimic clojure's basic operations on data structures with guile scheme as close as possible.
Structures correspondence: vector [clojure] <-> vector [scheme], hash-map [clojure] <-> srfi-125 hash-table [scheme], atom [clojure] <-> ice-9 atomic [scheme].
Operations: get, get-in (vector, hash-table); assoc, assoc-in (vector, hash-table); update, update-in (vector, hash-table); ref, swap!, reset! (atomic).
Bonus: clojure-alike hash-table printer.")
    (license license:gpl3+)
    (home-page "https://github.com/shegeley/clojureism")))

clojureism
