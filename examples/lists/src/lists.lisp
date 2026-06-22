;;; ------------ chapter 2 content

;; non-tail recursive list length
(defun length-of-list (lst)
  (if (null lst)
      0
      (1+ (length-of-list (cdr lst)))))

(defun main ()
  (format t "Length of list: ~a~%"
            (length-of-list '(a b c d)))
  (format t "Length of list: ~a~%"
            (length-of-list-tco '(a b c d)))
  (uiop:quit))  ;; (require :asdf)
