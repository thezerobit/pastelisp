;;;; pastelisp.asd

(asdf:defsystem #:pastelisp
  :serial t
  :description "A Simple Pastebin in Common Lisp"
  :author "Your Name <your.name@example.com>"
  :license "Specify license here"
  :depends-on (#:restas
               #:cl-who
               #:postmodern
               #:colorize
               #:simple-date
               #:secure-random)
  :components ((:file "pastelisp")))

