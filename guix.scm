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

(define %source-dir (dirname (current-filename)))

(define-public clojureism
 (package
  (name "clojureism")
  (version "0.0.1")
  (source (local-file %source-dir
           #:recursive? #t
           #:select? (git-predicate %source-dir)))
  (build-system guile-build-system)
  (inputs '())
  (arguments (list #:source-directory "src"))
  (native-inputs (list guile-3.0-latest))
  (synopsis "Small guile scheme libriary to provide clojure-alike atom, vector and hash-map basic procedures")
  (description "The point of this small libriary is to mimic clojure's basic operations on data structures with guile scheme as close as possible.
Structures correspondence: vector [clojure] <-> vector [scheme], hash-map [clojure] <-> srfi-69 hash-table [scheme], atom [clojure] <-> ice-9 atomic [scheme].
Operations: get, get-in (vector, hash-table); assoc, assoc-in (vector, hash-table); update, update-in (vector, hash-table); ref, swap!, reset! (atomic).
Bonus: clojure-alike hash-table printer.")
  (license license:gpl3+)
  (home-page "https://github.com/shegeley/clojureism")))

clojureism
