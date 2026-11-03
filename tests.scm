(use-modules
 ((ares suitbl core) #:select (with-test-runner))
 ((ares suitbl ares) #:select (load-project-tests))
 ((ares suitbl runner) #:select (make-suitbl get-state))
 ((ares suitbl reporters) #:select (minimal))
 ((ares suitbl state) #:select (get-run-summary))
 ((ice-9 format) #:select (format)))

(define-public (run-project-tests)
 (let ((runner (make-suitbl #:config `((test-reporter . ,minimal)))))
  (with-test-runner runner
   (load-project-tests)
   (runner '((type . runner/run-tests))))
  (get-run-summary (get-state runner))))

(let ((summary (run-project-tests)))
 (format #t "~%Clojureism test summary: ~s~%" summary)
 (exit (if (and summary
                (positive? (assoc-ref summary 'assertions))
                (zero? (assoc-ref summary 'failures))
                (zero? (assoc-ref summary 'errors)))
           0 1)))
