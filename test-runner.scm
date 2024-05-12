(use-modules
 (srfi srfi-64-ext)
 (srfi srfi-64-ext test))

(define runner
 ((@@ (srfi srfi-64-ext runners) test-runner-default)))

(run-module-tests (resolve-module '(test)) #:runner runner)
