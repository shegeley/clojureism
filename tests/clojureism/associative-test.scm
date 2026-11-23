(define-module (clojureism associative-test)
 #:use-module ((ares suitbl) #:select (define-suite test is throws-exception?))

 #:use-module ((clojureism associative) #:select (get get-in
                                                  assoc assoc-in
                                                  update update-in
                                                  set*))

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

(define-class <account> ()
  (%secret #:init-keyword #:secret #:init-value #f)
  (name #:init-keyword #:name #:init-value #f))

(define-class <shadowed> ()
  (value #:init-value 'public)
  (%value #:init-value 'private))

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

  (test "get/alist"
    (is (equal? 2 (get '((a . 1) (b . 2)) 'b)))
    (is (equal? "s" (get '(("k" . "s")) "k")))
    (is (equal? #f (get '((a . 1)) 'z)))
    (is (equal? 100 (get '((a . 1)) 'z 100)))
    (is (equal? #f (get '() 'z))))

  (test "get-in/alist"
    (is (equal? 'deep (get-in '((a . ((b . ((c . deep)))))) '(a b c))))
    (is (equal? #f (get-in '((a . ((b . 1)))) '(a z c)))))

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
      (is (equal? 3 (get p 'x)))))

  ;; %-prefixed internal slots resolve through their plain symbolic name;
  ;; an exact slot name always wins over the %-fallback

  (test "get/goops %-slot fallback"
    (let ((a (make <account> #:secret "s3cret" #:name 'bob)))
      (is (equal? "s3cret" (get a 'secret)))
      (is (equal? "s3cret" (get a '%secret)))
      (is (equal? 'bob (get a 'name)))
      (is (equal? #f (get a 'missing))))
    (is (equal? 'public (get (make <shadowed>) 'value)))
    (is (equal? 'private (get (make <shadowed>) '%value))))

  (test "set*/goops %-slot fallback"
    (let ((a (make <account> #:secret "old")))
      (is (eq? a (set* a 'secret "new")))
      (is (equal? "new" (get a '%secret)))
      (is (throws-exception? (set* a 'missing 1)))))

  (test "assoc/goops %-slot fallback stays functional"
    (let* ((a (make <account> #:secret "old"))
           (b (assoc a 'secret "new")))
      (is (equal? "new" (get b 'secret)))
      (is (equal? "old" (get a '%secret)))))

  ;; alist write support: assoc/assoc-in/update/update-in update alists
  ;; functionally, keeping alist representation and entry order

  (test "assoc/alist"
    (let ((before '((a . 1) (b . 2))))
      (is (equal? '((a . 1) (b . 9)) (assoc before 'b 9)))
      (is (equal? '((a . 1) (b . 2) (c . 3)) (assoc before 'c 3)))
      (is (equal? '((a . 1) (b . 5) (c . 3)) (assoc before 'c 3 'b 5)))
      (is (equal? '((a . 1) (b . 2)) before))
      (is (equal? '((a . 1)) (assoc '() 'a 1)))))

  (test "assoc-in/alist"
    (let ((nested '((outer . ((inner . 1) (other . 2))))))
      (is (equal? '((outer . ((inner . 1) (other . 9))))
                  (assoc-in nested '(outer other) 9)))
      (is (equal? '((outer . ((inner . 1) (other . 2) (fresh . 3))))
                  (assoc-in nested '(outer fresh) 3)))
      (is (equal? '((outer . ((inner . 1) (other . 2)))) nested)))
    (is (equal? '((a . ((b . ((c . 1))))))
                (assoc-in '((a . #f)) '(a b c) 1)))
    (is (equal? '((a . ((b . 1)))) (assoc-in '() '(a b) 1))))

  (test "assoc-in/mixed alist and hash-table"
    ;; a hash table nested in an alist stays a hash table
    (let ((mixed `((config . ,(alist->hash-table* '((mode . quiet)))))))
      (is (equal? 'loud
                  (get-in (assoc-in mixed '(config mode) 'loud) '(config mode)))))
    ;; an alist nested in a hash table stays an alist
    (let ((t (alist->hash-table* '((opts . ((depth . 1)))))))
      (is (equal? '((depth . 2)) (get (assoc-in t '(opts depth) 2) 'opts)))))

  (test "update/alist"
    (is (equal? '((n . 2)) (update '((n . 1)) 'n 1+))))

  (test "update-in/alist"
    (is (equal? '((a . ((b . 2)))) (update-in '((a . ((b . 1)))) '(a b) 1+)))))
