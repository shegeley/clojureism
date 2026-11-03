(define-module (clojureism mutation-test)
 #:use-module ((ares suitbl) #:select (define-suite test is throws-exception?))
 #:use-module ((clojureism associative) #:select (get get-in set* set-in* merge*))
 #:use-module ((oop goops) #:select (define-class (make . make-instance)))
 #:use-module ((srfi srfi-125) #:select (alist->hash-table make-hash-table
                                         hash-table-set! hash-table-copy
                                         (hash-table? . table?))))

(define (table . entries)
 (alist->hash-table entries equal?))

(define-class <editor> ()
 (busy? #:init-value #f)
 (render #:init-keyword #:render #:init-value #f))

(define-suite clojureism/mutation
 (test "set*: batches mutate and return the original table"
  (let ((editor (table '(pending . draft) '(busy? . #f))))
   (is (eq? editor (set* editor 'pending #f 'busy? #t 'busy? #f)))
   (is (eq? #f (get editor 'pending)))
   (is (eq? #f (get editor 'busy?)))
   (is (eq? editor (set* editor)))
   (is (eq? editor (set* editor 'pending 'next)))
   (is (eq? 'next (get editor 'pending)))))

 (test "set*: vectors and GOOPS retain identity"
  (let ((values (vector 1 2 3))
        (editor (make-instance <editor>)))
   (is (eq? values (set* values 0 #f 2 42)))
   (is (equal? #(#f 2 42) values))
   (is (eq? editor (set* editor 'busy? #t 'render 'ready)))
   (is (eq? #t (get editor 'busy?)))
   (is (eq? 'ready (get editor 'render)))))

 (test "set*: malformed batches fail before any writes"
  (let ((editor (table '(pending . draft))))
   (is (throws-exception? (set* editor 'pending #f 'busy?)))
   (is (eq? 'draft (get editor 'pending)))
   (is (throws-exception? (set* editor 'pending)))
   (is (throws-exception? (set* '() 'pending #f)))
   (is (throws-exception? (set* 42)))
   (is (throws-exception? (set* (vector 1) 1 2)))
   (is (throws-exception? (set* (make-instance <editor>) 'missing 1)))
   (is (throws-exception? (set* (hash-table-copy editor #f) 'pending #f)))))

 (test "set-in*: deep paths preserve siblings and existing branches"
  (let* ((render (table '(busy? . #f) '(width . 80)))
         (editor (table (cons 'render render) '(theme . dark))))
   (is (eq? editor (set-in* editor '(render busy?) #t '(render pending) #f)))
   (is (eq? render (get editor 'render)))
   (is (eq? #t (get-in editor '(render busy?))))
   (is (eq? #f (get-in editor '(render pending))))
   (is (= 80 (get-in editor '(render width))))
   (is (eq? 'dark (get editor 'theme)))
   (is (eq? editor (set-in* editor)))))

 (test "set-in*: missing and scalar branches become tables"
  (let ((editor (table '(render . #f) '(other . 17))))
   (set-in* editor '(render nested busy?) #t '(other pending) #f)
   (is (table? (get editor 'render)))
   (is (eq? #t (get-in editor '(render nested busy?))))
   (is (table? (get editor 'other)))
   (is (eq? #f (get-in editor '(other pending))))
   (set-in* editor '(render) 'replaced '(render) #f)
   (is (eq? #f (get editor 'render)))))

 (test "set-in*: mixed vectors, objects, and tables"
  (let* ((rows (vector (table '(busy? . #f)) #f))
         (editor (make-instance <editor> #:render rows)))
   (is (eq? editor (set-in* editor '(render 0 busy?) #t '(render 1 width) 80)))
   (is (eq? rows (get editor 'render)))
   (is (eq? #t (get-in editor '(render 0 busy?))))
   (is (= 80 (get-in editor '(render 1 width))))
   (is (throws-exception? (set-in* editor '(render 2 width) 90)))))

 (test "set-in*: validate all paths before any writes"
  (let ((editor (table '(pending . draft)))
        (cycle (list 'render)))
   (set-cdr! cycle cycle)
   (is (throws-exception? (set-in* editor '(pending) #f '())))
   (is (throws-exception? (set-in* editor '(pending) #f '() 1)))
   (is (throws-exception? (set-in* editor '(pending) #f '(render . busy?) 1)))
   (is (throws-exception? (set-in* editor '(pending) #f cycle 1)))
   (is (eq? 'draft (get editor 'pending)))
   (is (throws-exception? (set-in* #f '(pending) 1)))))

 (test "merge*: nested alist patches preserve table identities and siblings"
  (let* ((render (table '(pending . draft) '(width . 80)))
         (editor (table (cons 'render render) '(theme . dark))))
   (is (eq? editor
            (merge* editor '((render . ((pending . #f) (busy? . #t)))))))
   (is (eq? render (get editor 'render)))
   (is (eq? #f (get-in editor '(render pending))))
   (is (eq? #t (get-in editor '(render busy?))))
   (is (= 80 (get-in editor '(render width))))
   (is (eq? 'dark (get editor 'theme)))))

 (test "merge*: table patches and repeated patches apply in order"
  (let ((editor (table)))
   (merge* editor
           (table (cons 'render (table '(width . 80))))
           '((render . ((busy? . #t))) (theme . light) (theme . dark))
           '((render . ((width . 100)))))
   (is (= 100 (get-in editor '(render width))))
   (is (eq? #t (get-in editor '(render busy?))))
   (is (eq? 'dark (get editor 'theme)))))

 (test "merge*: new mapping branches do not alias the patch"
  (let* ((child (table '(busy? . #f)))
         (patch (table (cons 'render (table (cons 'nested child)))))
         (editor (table)))
   (merge* editor patch)
   (is (not (eq? (get editor 'render) (get patch 'render))))
   (is (not (eq? (get-in editor '(render nested)) child)))
   (set-in* editor '(render nested busy?) #t)
   (is (eq? #f (get child 'busy?)))
   (set* child 'width 80)
   (is (eq? #f (get-in editor '(render nested width))))))

 (test "merge*: existing nested alists become tables without losing fields"
  (let* ((old '((width . 80) (nested . ((keep . yes)))))
         (editor (table (cons 'render old))))
   (merge* editor '((render . ((busy? . #t) (nested . ((added . #f)))))))
   (is (table? (get editor 'render)))
   (is (= 80 (get-in editor '(render width))))
   (is (eq? 'yes (get-in editor '(render nested keep))))
   (is (eq? #f (get-in editor '(render nested added))))
   (is (equal? '((width . 80) (nested . ((keep . yes)))) old))))

 (test "merge*: scalars, ordinary lists, and vectors replace whole values"
  (let* ((items (list 1 2 3))
         (values (vector '(key . value)))
         (editor (table '(render . 42) (cons 'clear (table '(a . 1))))))
   (merge* editor `((render . ((busy? . #t))) (clear . #f)
                   (items . ,items) (values . ,values)))
   (is (eq? #t (get-in editor '(render busy?))))
   (is (eq? #f (get editor 'clear)))
   (is (eq? items (get editor 'items)))
   (is (eq? values (get editor 'values)))
   (merge* editor '((render . done)))
   (is (eq? 'done (get editor 'render)))))

 (test "merge*: empty mappings preserve fields and create empty branches"
  (let* ((render (table '(width . 80)))
         (editor (table (cons 'render render))))
   (is (eq? editor (merge* editor)))
   (is (eq? editor (merge* editor '() (table))))
   (merge* editor '((render . ()) (new . ())))
   (is (eq? render (get editor 'render)))
   (is (= 80 (get-in editor '(render width))))
   (is (table? (get editor 'new)))))

 (test "merge*: shared acyclic source branches are copied independently"
  (let* ((branch (table '(width . 80)))
         (editor (table)))
   (merge* editor (table (cons 'a branch) (cons 'b branch)))
   (set-in* editor '(a width) 100)
   (is (= 80 (get-in editor '(b width))))
   (is (= 80 (get branch 'width)))
   (is (eq? editor (merge* editor editor)))))

 (test "merge*: reject invalid sources before any writes"
  (let ((editor (table '(pending . draft))))
   (is (throws-exception? (merge* editor '((pending . #f)) '(invalid))))
   (is (throws-exception? (merge* editor '((pending . #f) . invalid))))
   (is (throws-exception? (merge* editor #f)))
   (is (eq? 'draft (get editor 'pending)))
   (is (throws-exception? (merge* '() '((pending . #f)))))))

 (test "merge*: reject recursive mappings before any writes"
  (let ((editor (table '(pending . draft)))
        (cycle (table))
        (alist-cycle (list (cons 'self #f))))
   (hash-table-set! cycle 'self cycle)
   (set-cdr! (car alist-cycle) alist-cycle)
   (is (throws-exception? (merge* editor '((pending . #f)) cycle)))
   (is (throws-exception? (merge* editor '((pending . #f)) alist-cycle)))
   (is (eq? 'draft (get editor 'pending)))))

 (test "merge*: patches can address vector indices and object slots"
  (let ((values (vector #f 'keep))
        (editor (make-instance <editor>)))
   (is (eq? values (merge* values '((0 . ((width . 80)))))))
   (is (= 80 (get-in values '(0 width))))
   (is (eq? 'keep (get values 1)))
   (is (eq? editor (merge* editor '((busy? . #t) (render . ((width . 80)))))))
   (is (eq? #t (get editor 'busy?)))
   (is (= 80 (get-in editor '(render width))))))

 (test "new branches preserve hash-table key comparison"
  (let* ((branch (make-hash-table string-ci=?))
         (editor (make-hash-table string-ci=?)))
   (hash-table-set! branch "Width" 80)
   (merge* editor (table (cons "Render" branch)))
   (is (= 80 (get-in editor '("render" "width"))))
   (merge* editor '(("RENDER" . (("WIDTH" . 100)))))
   (is (= 100 (get-in editor '("render" "width"))))
   (is (= 80 (get branch "width")))
   (set-in* editor '("Other" "Width") 40)
   (is (= 40 (get-in editor '("other" "width"))))))

 (test "set-in*: nested alists preserve unrelated fields"
  (let* ((old '((width . 80)))
         (editor (table (cons 'render old))))
   (set-in* editor '(render busy?) #t)
   (is (= 80 (get-in editor '(render width))))
   (is (eq? #t (get-in editor '(render busy?))))
   (is (equal? '((width . 80)) old))))

 (test "merge*: immutable source tables create mutable independent branches"
  (let* ((branch (hash-table-copy (table '(width . 80)) #f))
         (patch (hash-table-copy (table (cons 'render branch)) #f))
         (editor (table)))
   (merge* editor patch)
   (set-in* editor '(render width) 100)
   (is (= 100 (get-in editor '(render width))))
   (is (= 80 (get branch 'width)))))

 (test "immutable ancestors fail before changing their mutable children"
  (let* ((child (table '(width . 80)))
         (parent (hash-table-copy (table (cons 'render child)) #f))
         (outer (table (cons 'locked parent))))
   (is (throws-exception? (merge* parent '((render . ((width . 100)))))))
   (is (= 80 (get child 'width)))
   (is (throws-exception? (set-in* parent '(render width) 100)))
   (is (= 80 (get child 'width)))
   (is (throws-exception? (merge* outer '((locked . ((render . ((width . 100)))))))))
   (is (= 80 (get child 'width)))
   (is (throws-exception? (set-in* outer '(locked render width) 100)))
   (is (= 80 (get child 'width)))))

 (test "umbrella module re-exports the mutation API"
  (is (eq? set* (@ (clojureism) set*)))
  (is (eq? set-in* (@ (clojureism) set-in*)))
  (is (eq? merge* (@ (clojureism) merge*)))))
