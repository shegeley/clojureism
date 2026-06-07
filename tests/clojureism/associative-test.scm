(define-module (clojureism associative-test)
  #:use-module ((ares suitbl) #:select (define-suite test is throws-exception?))

  #:use-module ((clojureism associative) #:select (get get-in
                                                   assoc assoc-in
                                                   update update-in))

  #:use-module (oop goops)

  #:use-module ((srfi srfi-125) #:select (make-hash-table
                                          alist->hash-table
                                          hash-table=?))
  #:use-module ((srfi srfi-128) #:select (make-default-comparator)))

(define (alist->hash-table* alist)
  (alist->hash-table alist equal?))

(define (hash-table=?* ht1 ht2)
  (hash-table=? (make-default-comparator) ht1 ht2))

(define (table*) (make-hash-table equal?))

(define (table**)
  (alist->hash-table*
   `((hello . world)
     (nested . ,(alist->hash-table*
                 `((key1 . val1)
                   (key2 . ,(alist->hash-table*
                             `((key1- . val1-))))))))))

(define (vector*)  (vector 1 2 3))
(define (vector**) (vector 1 (vector 10 20 (vector 42 49 69)) 3))

(define-class <point> ()
  (x    #:init-keyword #:x    #:init-value 0)
  (y    #:init-keyword #:y    #:init-value 0)
  (meta #:init-keyword #:meta #:init-value #f))

(define-suite clojureism/associative

  (test "assoc/hash-table"
    (is (hash-table=?*
         (alist->hash-table* `((a . 1) (b . 2)))
         (assoc (table*) 'a 1 'b 2))))

  (test "assoc/vector"
    (is (equal? (vector 10 2 30) (assoc (vector*) 0 10 2 30))))

  (test "get/hash-table"
    (is (equal? 1 (get (assoc (table*) 'a 1 'b 2) 'a)))
    (is (equal? #f (get (table*) 'z)))
    (is (equal? 100 (get (table*) 'a 100))))

  (test "get/vector"
    (is (equal? 1 (get (vector*) 0)))
    (is (equal? 3 (get (vector*) 100 3)))
    (is (throws-exception? (get (vector*) 100))))

  (test "get-in/hash-table"
    (is (equal? 'val1- (get-in (table**) '(nested key2 key1-))))
    (is (equal? #f (get-in (table**) '(nested key2 #f)))))

  (test "get-in/vector"
    (is (equal? 42 (get-in (vector**) '(1 2 0))))
    (is (throws-exception? (get-in (vector**) '(100)))))

  (test "update/hash-table"
    (is (equal? 'world!
                (get (update (table**) 'hello (lambda (x) (symbol-append x '!)))
                     'hello))))

  (test "update/vector"
    (is (equal? 2 (get (update (vector**) 0 (lambda (x) (+ x 1))) 0))))

  (test "update-in/hash-table"
    (is (equal? 'val-1!
                (get-in (update-in (table**) '(nested key) (const 'val-1!))
                        '(nested key)))))

  (test "update-in/vector"
    (is (equal? 21
                (get-in (update-in (vector**) '(1 1) (const 21)) '(1 1)))))

  (test "assoc-in/hash-table"
    (is (hash-table=?*
         (alist->hash-table*
          `((hello . world)
            (a . ,(alist->hash-table* `((b . 11))))
            (c . ,(alist->hash-table* `((d . 12))))
            (nested . ,(alist->hash-table*
                        `((key1 . val1)
                          (key2 . ,(alist->hash-table*
                                    `((key1- . val1-)))))))))
         (assoc-in (table**) '(a b) 11 '(c d) 12)))
    (is (hash-table=?*
         (alist->hash-table*
          `((hello . world)
            (a . ,(alist->hash-table*
                   `((b . ,(alist->hash-table* `((c . 12)))))))
            (nested . ,(alist->hash-table*
                        `((key1 . val1)
                          (key2 . ,(alist->hash-table*
                                    `((key1- . val1-)))))))))
         (assoc-in (table**) '(a b c) 12))))

  (test "assoc-in/vector"
    (is (equal? (vector 1 (vector 10 20 (vector 42 11 69)) 3)
                (assoc-in (vector**) '(1 2 1) 11)))
    (is (throws-exception? (assoc-in (vector**) '(100) 42))))

  ;; goops object support: get/get-in/assoc/assoc-in over slots by name

  (test "get/goops"
    (let ((p (make <point> #:x 3 #:y 4)))
      (is (equal? 3 (get p 'x)))
      (is (equal? 4 (get p 'y)))
      (is (equal? #f (get p 'absent)))
      (is (equal? 100 (get p 'absent 100)))))

  (test "assoc/goops"
    ;; assoc is functional: returns a fresh clone, original untouched
    (let ((p (make <point> #:x 3 #:y 4)))
      (is (equal? 10 (get (assoc p 'x 10) 'x)))
      (is (equal? 3 (get p 'x)))
      (is (equal? 20 (get (assoc p 'x 10 'y 20) 'y)))))

  (test "get-in/goops"
    (let ((p (make <point> #:x 1 #:y 2
                   #:meta (make <point> #:x 42 #:y 49))))
      (is (equal? 42 (get-in p '(meta x))))
      (is (equal? 49 (get-in p '(meta y))))
      (is (equal? #f (get-in p '(meta absent))))))

  (test "assoc-in/goops"
    (let ((p (make <point> #:x 1 #:y 2
                   #:meta (make <point> #:x 42 #:y 49))))
      (is (equal? 7 (get-in (assoc-in p '(meta x) 7) '(meta x))))
      ;; original nested object untouched
      (is (equal? 42 (get-in p '(meta x))))))

  (test "update/goops"
    (let ((p (make <point> #:x 3 #:y 4)))
      (is (equal? 4 (get (update p 'x 1+) 'x)))
      (is (equal? 3 (get p 'x))))))
