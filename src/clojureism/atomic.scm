(define-module (clojureism atomic)
 #:use-module (ice-9 atomic)
 #:export (ref reset! swap!))

(define (ref a) (atomic-box-ref a))

(define (reset! a val) (atomic-box-set! a val) val)

(define (swap! box proc)
 "Stolen from ares. Thanks to @abcdw https://git.sr.ht/~abcdw/guile-ares-rs/tree/9194aeb/src/guile/ares/atomic.scm#L24"
 (let loop ((old-value (atomic-box-ref box)))
  (let* ((new-value (proc old-value))
         (cas-value (atomic-box-compare-and-swap! box old-value new-value)))
   (if (eq? old-value cas-value)
    new-value
    (loop cas-value)))))
