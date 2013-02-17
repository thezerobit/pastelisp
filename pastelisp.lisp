;;;; pastelisp.lisp

(restas:define-module #:pastelisp
  (:use #:cl #:who #:postmodern)
  (:export
    #:*connection-params*
    #:paste
    #:create-tables
    #:start-server))

(in-package #:pastelisp)

(defparameter *connection-params*
  (list "pastelisp" "pastelispuser" "pastelisppass" "localhost"
        :pooled-p T))

;; database definition
(defclass paste ()
  ((id :col-type serial)
   (slug :col-type string :initarg :slug :reader slug)
   (payload :col-type string :initarg :payload :reader payload)
   (created :col-type timestamp :initarg :created)
   (highlight-type :col-type string :initarg :highlight-type
                   :reader highlight-type))
  (:metaclass dao-class)
  (:keys id))

(defun create-tables ()
  (with-connection *connection-params*
    (execute (dao-table-definition 'paste))
    (execute "CREATE INDEX ON paste (created)")
    (execute "CREATE UNIQUE INDEX ON paste (slug)")))

(defun default-doc (&key body style)
  (with-html-output-to-string (out nil :prologue T)
    (:html
      (:head (:title "PASTELIST")
             (:style (str style)))
      (:body (:div (:a :href "/" "new"))
             (:div (:a :href "/recent" "recent"))
             (:div (str body))))))

(defun gen-slug (length)
  (let ((letters "abcdefghijklmnopqrstuvwxyzABCDEFHIJKLMNOPQRSTUVWXYZ1234567890"))
    (coerce (loop for x from 1 upto length
                  collecting (elt letters (secure-random:number (length letters))))
            'string)))

;; routes

(restas:define-route main ("" :method :get)
  (default-doc :body
    (with-html-output-to-string (out)
      (:form :method "POST" :action "/new"
          (:div (:textarea :name "payload" :rows 24 :cols 80))
          (:div "Highlight Type: "
           (:select :name "lexer"
            (:option :value "" "None")
            (mapc (lambda (x) (htm (:option :value (car x) (str (cdr x)))))
                  (colorize:coloring-types))))
          (:div (:input :type "submit" :value "Create"))))))

(restas:define-route new ("new" :method :post)
  (let ((payload (hunchentoot:post-parameter "payload"))
        (valid-colorizer (assoc (hunchentoot:post-parameter "lexer")
                               (colorize:coloring-types) :test #'string=)))
    (let ((paste
            (make-instance 'paste
                           :slug (gen-slug 8)
                           :payload payload
                           :created (simple-date:universal-time-to-timestamp
                                      (get-universal-time))
                           :highlight-type (if valid-colorizer
                                             (string (car valid-colorizer))
                                             ""))))
      (with-connection *connection-params* (insert-dao paste))
      (restas:redirect 'show :slug (slug paste)))))

(restas:define-route recent ("/recent" :method :get)
  (with-connection *connection-params*
    (let ((recent-pastes
            (query-dao 'paste (:limit
                                (:order-by
                                  (:select :* :from 'paste)
                                  (:desc 'created))
                                20))))
      (default-doc
        :body (with-html-output-to-string (out)
                (:ul
                  (mapc (lambda (paste)
                          (htm (:li (:a :href (restas:genurl 'show :slug (slug paste))
                                     (str (slug paste))))))
                        recent-pastes)))))))

(restas:define-route show (":slug" :method :get)
  (with-connection *connection-params*
    (let ((paste (car (select-dao 'paste (:= 'slug slug)))))
      (if paste
        (let ((ht (highlight-type paste))
              (valid-colorizer (assoc (highlight-type paste)
                               (colorize:coloring-types) :test #'string=)))
          (default-doc :style colorize:*coloring-css* :body
            (format nil "<pre>~a</pre>"
                    (if valid-colorizer
                      (colorize:html-colorization
                        (car valid-colorizer)
                        (payload paste))
                      (escape-string (payload paste))))))
        (restas:abort-route-handler (default-doc :body "Paste Not Found")
                                    :return-code 404)))))

(defun start-server ()
  (restas:start '#:pastelisp :port 8080))
