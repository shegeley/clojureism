(define-module (test)
 #:use-module (clojureism associative)
 #:use-module (clojureism atomic)

 #:use-module (ice-9 atomic)

 #:use-module (srfi srfi-125)
 #:use-module (srfi srfi-128)

 #:use-module (srfi srfi-64-ext)
 #:use-module (srfi srfi-64-ext test)
 #:use-module (srfi srfi-64))

(define table* (make-hash-table equal?))

(define (alist->hash-table* alist)
 (alist->hash-table alist equal?))

(define (hash-table=?* ht1 ht2)
 (hash-table=? (make-default-comparator) ht1 ht2))

(define table**
 (alist->hash-table*
  `((hello . world)
    (nested . ,(alist->hash-table*
                `((key1 . val1)
                  (key2 . ,(alist->hash-table*
                            `((key1- . val1-))))))))))
(define vector* (vector 1 2 3))
(define vector** (vector 1 (vector 10 20 (vector 42 49 69)) 3))

(define-test assoc-test
 (test-group "assoc/hash-table"
  (test-assert (hash-table=?*
                (alist->hash-table* `((a . 1) (b . 2)))
                (assoc table* 'a 1 'b 2))))
 (test-group "assoc/vector"
  (test-equal (vector 10 2 30) (assoc vector* 0 10 2 30))))

(define-test get-test
 (test-group "get/hash-table"
  (test-equal 1 (get (assoc table* 'a 1 'b 2) 'a))
  (test-equal #f (get table* 'z))
  (test-equal 100 (get table* 'a 100)))
 (test-group "get/vector"
  (test-equal 1 (get vector* 0))
  (test-equal 3 (get vector* 100 3))
  (test-error 'out-of-bounds (get vector* 100))))

(define-test get-in-test
 (test-group "get-in/hash-table"
  (test-equal 'val1- (get-in table** '(nested key2 key1-)))
  (test-equal #f (get-in table** '(nested key2 #f))))
 (test-group "get-in/vector"
  (test-equal 42 (get-in vector** '(1 2 0)))
  (test-error (get-in vector** '(100)))))

(define* (compare-modified expected x key proc
          #:key
          (modifier update)
          (getter get))
 (equal? expected (getter (modifier x key proc) key)))

(define-test update-test
 (test-group "update/hash-table"
  (test-assert (compare-modified 'world! table** 'hello (lambda (x) (symbol-append x '!)))))
 (test-group "update/vector"
  (test-assert (compare-modified 2 vector** 0 (lambda (x) (+ x 1))))))

(define-test update-in-test
 (test-group "update-in/hash-table"
  (test-assert (compare-modified 'val-1! table**
                '(nested key) (const 'val-1!)
                #:modifier update-in
                #:getter get-in)))
 (test-group "update-in/vector"
  (test-assert (compare-modified 21 vector**
                '(1 1) (const 21)
                #:modifier update-in
                #:getter get-in))))

(define-test assoc-in-test
 (test-group "assoc-in/hash-table"
  (test-assert
   (hash-table=?*
    (alist->hash-table*
     `((hello . world)
       (a . ,(alist->hash-table* `((b . 11))))
       (c . ,(alist->hash-table* `((d . 12))))
       (nested . ,(alist->hash-table*
                   `((key1 . val1)
                     (key2 . ,(alist->hash-table*
                               `((key1- . val1-)))))))))
    (assoc-in table** '(a b) 11 '(c d) 12)))
  (test-assert
   (hash-table=?*
    (alist->hash-table*
     `((hello . world)
       (a . ,(alist->hash-table*
              `((b . ,(alist->hash-table* `((c . 12)))))))
       (nested . ,(alist->hash-table*
                   `((key1 . val1)
                     (key2 . ,(alist->hash-table*
                               `((key1- . val1-)))))))))
    (assoc-in table** '(a b c) 12))))
 (test-group "assoc-in/vector"
  (test-equal
   (vector 1 (vector 10 20 (vector 42 11 69)) 3)
   (assoc-in vector** '(1 2 1) 11))
  (test-error 'out-of-bounds (assoc-in vector** '(100) 42))))

;; all atom tests have let because test-running order is not deterministic

(define-test ref-test
 (test-group "atom/ref"
  (let [(atom* (make-atomic-box 10))]
   (test-equal 10 (ref atom*)))))

(define-test swap!-test
 (let [(atom* (make-atomic-box 10))]
  (test-group "atom/swap!"
   (test-equal 11 (swap! atom* (lambda (x) (+ 1 x)))))))

(define-test reset!-test
 (let [(atom* (make-atomic-box 10))]
  (test-group "atom/reset!"
   (test-equal 30 (reset! atom* 30)))))
