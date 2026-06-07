(define-module (clojureism atomic-test)
  #:use-module ((ares suitbl) #:select (define-suite test is))

  #:use-module ((clojureism atomic) #:select (ref reset! swap!))

  #:use-module ((ice-9 atomic) #:select (make-atomic-box)))

(define-suite clojureism/atomic

  (test "atom/ref"
    (let ((atom* (make-atomic-box 10)))
      (is (equal? 10 (ref atom*)))))

  (test "atom/swap!"
    (let ((atom* (make-atomic-box 10)))
      (is (equal? 11 (swap! atom* (lambda (x) (+ 1 x)))))))

  (test "atom/reset!"
    (let ((atom* (make-atomic-box 10)))
      (is (equal? 30 (reset! atom* 30))))))
