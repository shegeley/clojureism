(use-modules
 (guix gexp)
 (guix download)
 ((guix licenses) #:prefix license:)
 (guix packages)
 (guix git-download)
 (guix download)
 (guix utils)
 (guix build-system guile)
 (gnu packages guile)
 (gnu packages guile-xyz)
 (gnu packages package-management))

(define-public guile-srfi-126
 (let ((commit "f480cf2d1a33c1f3d0fab3baf321c0ed5b5eb248")
       (revision "0"))
  (package
   (name "guile-srfi-126")
   (version revision)
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/scheme-requests-for-implementation/srfi-126")
           (commit commit)))
     (file-name (git-file-name name version))
     (modules '((guix build utils)))
     (snippet
      '(begin
        (delete-file-recursively "r6rs")

        (delete-file "srfi/126.sld")
        (delete-file "srfi/126.sld.in")
        (delete-file "srfi/:126.sls")
        (delete-file "srfi/:126.sls.in")

        (delete-file "test-suite.body.scm")
        (delete-file "test-suite.r6rs.sps")
        (delete-file "test-suite.r6rs.sps.in")
        (delete-file "test-suite.r7rs.scm")
        (delete-file "test-suite.r7rs.scm.in")
        #t))
     (sha256
      (base32 "18psw8l798xmbv2h90cz41r51q1mydzg7yr71krfprx5kdfqn32q"))))
   (build-system guile-build-system)
   (native-inputs (list guile-3.0))
   (home-page "https://github.com/scheme-requests-for-implementation/srfi-126")
   (synopsis "SRFI 126: R6RS-based hashtables")
   (description "The utility procedures provided by this SRFI in addition to the R6RS API may be categorized as follows:
    - Constructors: alist->eq-hashtable, alist->eqv-hashtable, alist->hashtable
    - Access and mutation: hashtable-lookup, hashtable-intern!
    - Copying: hashtable-empty-copy
    - Key/value collections: hashtable-values, hashtable-key-list, hashtable-value-list, hashtable-entry-lists
    - Iteration: hashtable-walk, hashtable-update-all!, hashtable-prune!, hashtable-merge!, hashtable-sum, hashtable-map->lset, hashtable-find
    - Miscellaneous: hashtable-empty?, hashtable-pop!, hashtable-inc!, hashtable-dec!")
   (license license:expat))))

(define-public guile-srfi-125
 (let ((commit "8f4942f0612b6cc6af56fc90146afcccfe67d85f")
       (hash "11fzpsjqlg2qd6gcxnsiy9vgisnw4d0gkh9wiarkjqyr3j95440q")
       (revision "1"))
  (package
   (name "guile-srfi-125")
   (version revision)
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/shegeley/srfi-125")
           (commit commit)))
     (sha256 (base32 hash))
     (snippet '(begin
                (rename-file "srfi/125.sld" "srfi/srfi-125.scm")
                (delete-file "tables-test.sps")
                #t))))
   (build-system guile-build-system)
   (inputs (list guile-3.0))
   (propagated-inputs (list guile-srfi-128 guile-srfi-126))
   (home-page "https://github.com/scheme-requests-for-implementation/srfi-125")
   (synopsis "SRFI 125: Intermediate hash tables")
   (description "The procedures in this SRFI are drawn primarily from SRFI 69 and R6RS. In addition, the following sources are acknowledged:
    - The hash-table-mutable? procedure and the second argument of hash-table-copy (which allows the creation of immutable hash tables) are from R6RS, renamed in the style of this SRFI.
    - The hash-table-intern! procedure is from Racket, renamed in the style of this SRFI.
    - The hash-table-find procedure is a modified version of table-search in Gambit.
    - The procedures hash-table-unfold and hash-table-count were suggested by SRFI 1.
    - The procedures hash-table=? and hash-table-map were suggested by Haskell's Data.Map.Strict module.
    - The procedure hash-table-map->list is from Guile.

    The procedures hash-table-empty?, hash-table-empty-copy, hash-table-pop!, hash-table-map!, hash-table-intersection!, hash-table-difference!, and hash-table-xor! were added for convenience and completeness. ")
   (license license:expat))))

guile-srfi-125
