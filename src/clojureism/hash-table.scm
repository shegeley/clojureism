(define-module (clojureism hash-table)
 #:use-module (srfi srfi-69)

 #:export (hash-table-deep-hash hash-table-compare))

(define (hash-table-deep-hash table)
 "Quick and dirty hash-table compare procedure via hashes"
 (hash-table-fold table
   (lambda (key val acc)
    (hash (cond ((hash-table? val)
                 (cons (hash (vector key (hash-table-deep-hash val))) acc))
                (else (cons (hash (vector key val)) acc))))) 0))

(define* (hash-table-compare comparator
          #:key (on hash-table-deep-hash) . args)
 (apply comparator (map on args)))
