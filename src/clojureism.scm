(define-module (clojureism)
 #:use-module ((clojureism associative) #:select (get get-in
                                                  assoc assoc-in
                                                  update update-in
                                                  set* set-in* merge*
                                                  set-hash-table-printer!
                                                  table-printer associative?))
 #:use-module ((clojureism atomic) #:select (ref reset! swap!))

 #:re-export (get get-in
              assoc assoc-in
              update update-in
              set* set-in* merge*
              ref reset! swap!
              set-hash-table-printer! table-printer
              associative?))
