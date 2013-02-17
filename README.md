# PASTELISP

A Simple Pastebin in Common Lisp.

## INSTALL

To load in a lisp REPL: (ql:quickload "pastelisp")

## DEPLOYMENT

To create database:

    sudo -u postgres createuser -D -A -P pastelispuser # pastelisppass
    sudo -u postgres createdb -O pastelispuser pastelisp

To run local test server: (pastelisp:start-server)

Uses hunchentoot and Restas under the hood, so see those projects
for more detailed instructions on deployment.

## Author

Stephen A. Goss (steveth45@gmail.com)

## Copyright

Copyright (c) 2012 Stephen A. Goss (steveth45@gmail.com)

# License

Licensed under the Modified BSD License.
