(define-module (clojureism associative)
 #:use-module ((ice-9 format) #:select (format))
 #:use-module ((ice-9 match) #:select (match))
 #:use-module ((srfi srfi-1) #:select (every))
 #:use-module ((srfi srfi-9 gnu) #:select (set-record-type-printer!))
 #:use-module ((srfi srfi-125) #:select (make-hash-table hash-table
                                         hash-table? hash-table-copy hash-table-mutable?
                                         hash-table-empty-copy hash-table->alist
                                         hash-table-ref/default hash-table-set!
                                         hash-table-walk))
 #:use-module ((oop goops) #:select (slot-ref slot-set!
                                     slot-bound? slot-exists?
                                     shallow-clone
                                     class-of is-a? <object>
                                     (make . make-instance)))

 #:replace (assoc)
 #:export (get get-in
           assoc assoc-in
           update update-in
           set-hash-table-printer! table-printer
           copy set* set-in* merge* make associative?))

(define hash-table* (make-hash-table equal?))

(define hash-table-type (record-type-descriptor hash-table*))

(define table-printer
 (lambda (table port)
  (write-char #\{ port)
  (hash-table-walk table (lambda (k v) (format port " ~a ~a " k v)))
  (write-char #\} port)))

(set-record-type-printer! hash-table-type table-printer)

(define (goops? x) (is-a? x <object>))

(define (associative? x) (or (hash-table? x) (vector? x) (goops? x)))

(define (copy x)
 (cond
  ((vector? x) (vector-copy x))
  ;; #t for mutability
  ((hash-table? x) (hash-table-copy x #t))
  ((goops? x) (shallow-clone x))))

(define (require-target x)
 (unless (associative? x)
  (error "Expected a SRFI-125 hash table, vector, or GOOPS object" x))
 (when (and (hash-table? x) (not (hash-table-mutable? x)))
  (error "Cannot update an immutable hash table")))

(define (require-pairs args)
 (unless (even? (length args))
  (error "Expected key/value pairs" args)))

(define (for-each-binding proc args)
 (match args
  (() #t)
  ((key value . rest)
   (proc key value)
   (for-each-binding proc rest))))

(define (set-one! x key val)
 (cond
  ((vector? x) (vector-set! x key val))
  ((hash-table? x) (hash-table-set! x key val))
  ((goops? x) (slot-set! x key val))))

(define (set* x . args)
 "Assign key/value pairs to @var{x} in order and return @var{x}.
Validate the argument count before writing. Later values for a key win."
 (require-target x)
 (require-pairs args)
 (for-each-binding (lambda (key value) (set-one! x key value)) args)
 x)

(define (require-path path)
 (unless (and (list? path) (pair? path))
  (error "Expected a non-empty proper key path" path)))

(define (empty-mapping prototype)
 (if (hash-table? prototype)
     (hash-table-empty-copy prototype)
     (make-hash-table equal?)))

(define (set-path! x path value)
 (require-target x)
 (match path
  ((key) (set-one! x key value))
  ((key . rest)
   (let* ((current (ref x key))
          (branch (cond
                   ((associative? current) current)
                   ((alist? current) (copy-mapping current))
                   (else (empty-mapping x)))))
    (set-path! branch rest value)
    (unless (eq? branch current)
     (set-one! x key branch))))))

(define (set-in* x . args)
 "Assign path/value pairs to @var{x} and return @var{x}.
Paths are non-empty proper lists. Validate all paths before writing.
Missing or scalar branches become tables; nested alists become table copies."
 (require-target x)
 (require-pairs args)
 (for-each-binding (lambda (path value) (require-path path)) args)
 (for-each-binding (lambda (path value) (set-path! x path value)) args)
 x)

(define (alist? x)
 (and (list? x) (every pair? x)))

(define (mapping? x)
 (or (hash-table? x) (alist? x)))

(define (mapping-entries source)
 (cond
  ((hash-table? source) (hash-table->alist source))
  ((alist? source) source)
  (else (error "Expected an alist or SRFI-125 hash table patch" source))))

(define (validate-mapping source ancestors)
 (when (memq source ancestors)
  (error "Cannot merge a cyclic mapping"))
 (for-each
  (lambda (entry)
   (let ((value (cdr entry)))
    (when (mapping? value)
     (validate-mapping value (cons source ancestors)))))
  (mapping-entries source)))

(define (copy-mapping source)
 (validate-mapping source '())
 (merge-source! (empty-mapping source) source))

(define (merge-value! current value)
 (if (mapping? value)
     (let ((branch (cond
                    ((hash-table? current) current)
                    ((alist? current) (copy-mapping current))
                    (else (empty-mapping value)))))
      (merge-source! branch value))
     value))

(define (merge-source! target source)
 (require-target target)
 (for-each
  (lambda (entry)
   (let* ((key (car entry))
          (value (merge-value! (ref target key) (cdr entry))))
    (set-one! target key value)))
  (mapping-entries source))
 target)

(define (merge* target . sources)
 "Recursively merge alist or SRFI-125 table patches into @var{target}.
Return @var{target}. Preserve existing nested tables and their comparators.
Copy new mapping branches; treat non-alist lists and vectors as leaf values.
An empty alist is an empty mapping. Reject malformed or cyclic mapping
sources before writing. Updates are sequential, without rollback on errors."
 (require-target target)
 (for-each (lambda (source) (validate-mapping source '())) sources)
 (for-each (lambda (source) (merge-source! target source)) sources)
 target)

(define (make x)
 (cond
  ((vector? x) (vector))
  ((hash-table? x) (hash-table equal?))
  ((goops? x) (make-instance (class-of x)))))

(define (alist-ref/default x k alt)
  "Read @var{k} from alist @var{x}, @var{alt} when absent --- the read side of the alist support @code{set-path!}/@code{merge-value!} already had on write paths.  Uses @code{equal?}, like the hash-table branch.  Not @code{assoc}: this module redefines it below."
  (match x
    (() alt)
    (((key . value) . rest)
     (if (equal? key k) value (alist-ref/default rest k alt)))
    (_ alt)))

(define* (ref x k #:optional (alt #f))
 (cond
  ((vector? x) (vector-ref x k))
  ((hash-table? x) (hash-table-ref/default x k alt))
  ((goops? x) (if (and (slot-exists? x k) (slot-bound? x k))
                  (slot-ref x k)
                  alt))
  ((alist? x) (alist-ref/default x k alt))))

(define (mutable? x)
 (cond
  ((vector? x) #t)
  ((hash-table? x) #f)))

(define (assoc x . args)
 (apply set* (copy x) args))

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
