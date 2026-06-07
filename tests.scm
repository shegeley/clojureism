(use-modules
 (ares suitbl core)
 ((ares suitbl runner) #:prefix runner:)
 ((ares suitbl reporters) #:prefix reporters:)
 ((ares suitbl state) #:prefix state:)
 (ares suitbl discovery)
 (srfi srfi-197)
 (ice-9 exceptions))

(define load-project-tests
  (@@ (ares suitbl ares) load-project-tests))

(define-public (run-project-tests)
  (let* ((test-runner (runner:make-suitbl)))
    (parameterize ((test-runner* test-runner))
      (load-project-tests)
      (test-runner `((type . runner/run-tests))))
    (state:get-run-summary (runner:get-state test-runner))))

(run-project-tests)
