(use-modules
 (srfi srfi-64-ext)
 (srfi srfi-64-ext test))

(run-project-tests-cli (list (resolve-module '(test))))
