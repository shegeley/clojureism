(define-module (clojureism associative)
 #:use-module (ice-9 format)
 #:use-module (ice-9 match)

 #:use-module (srfi srfi-9 gnu) ;; custom record printers

 #:use-module (srfi srfi-125) ;; advanced hash-tables

 #:replace (assoc)

 #:export (get get-in
           assoc assoc-in
           update update-in
           set-hash-table-printer! table-printer
           copy set* make associative?))

(define hash-table* (make-hash-table equal?))

(define hash-table-type (record-type-descriptor hash-table*))

(define table-printer
 (lambda (table port)
  (write-char #\{ port)
  (hash-table-walk table (lambda (k v) (format port " ~a ~a " k v)))
  (write-char #\} port)))

(set-record-type-printer! hash-table-type table-printer)

(define (associative? x) (or (hash-table? x) (vector? x)))

(define (copy x)
 (cond
  ((vector? x) (vector-copy x))
  ;; #t for mutability
  ((hash-table? x) (hash-table-copy x #t))))

(define (set* x key val)
 (cond
  ((vector? x) (vector-set! x key val))
  ((hash-table? x) (hash-table-set! x key val))))

(define (make x)
 (cond
  ((vector? x) (vector))
  ((hash-table? x) (hash-table equal?))))

(define* (ref x k #:optional (alt #f))
 (cond
  ((vector? x) (vector-ref x k))
  ((hash-table? x) (hash-table-ref/default x k alt))))

(define (mutable? x)
 (cond
  ((vector? x) #t)
  ((hash-table? x) #f)))

(define (assoc/in-place x . args)
 (match args
  (() x)
  ((key val) (begin (set* x key val) x))
  ((key val rest ...) (apply assoc (assoc x key val) rest))))

(define (assoc x . args)
 (apply assoc/in-place (copy x) args))

(define* (get x k #:optional (alt #f))
 (with-exception-handler
  (lambda (exn) (if alt alt (throw exn)))
  (lambda () (ref x k alt)) #:unwind? #t))

(define (get-in x ks)
 (match ks
  (() x)
  ((k) (get x k))
  ((k rest ...) (let [(x1 (get x k))] (if x1 (get-in x1 rest) #f)))))

(define (assoc-in x . args)
 (match args
  ((ks1 val1)
   (match ks1
    ((k) (assoc x k val1))
    ((k rest ...)
     (let [(val (get x k))]
      (cond
       ((associative? val) (assoc x k (assoc-in val rest val1)))
       (else (assoc x k (assoc-in (make x) rest val1))))))))
  ((ks1 val1 rest ...) (apply assoc-in (assoc-in x ks1 val1) rest))))

(define (update x . args)
 (match args
  ((k f) (assoc x k (f (get x k))))
  ((k f rest ...) (apply update (update x k f) rest))))

(define (update-in x . args)
 (match args
  ((ks1 f1) (let [(v (get-in x ks1))] (assoc-in x ks1 (f1 v))))
  ((ks1 f1 rest ...) (apply update-in (update-in x ks1 f1) rest))))
