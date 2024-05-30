(define-module (clojureism)
 #:use-module (clojureism associative)
 #:use-module (clojureism atomic)

 #:re-export (get get-in
              assoc assoc-in
              update update-in
              ref reset! swap!
              set-hash-table-printer! table-printer
              copy set* make associative?))
