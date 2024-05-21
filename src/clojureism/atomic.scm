(define-module (clojureism atomic)
 #:use-module (ice-9 atomic)
 #:export (ref reset! swap!))

(define (ref a) (atomic-box-ref a))

(define (reset! a val) (atomic-box-set! a val) val)

(define (swap! a f . args)
 (let [(val (apply f (ref a) args))] (reset! a val) val))
