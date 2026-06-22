;;; Adapted from https://stackoverflow.com/a/54169156

(defun quicksort (lst)
  (if (null lst)
      nil
      (let ((pivot (first lst)) (less nil) (greater nil))
        (dolist (i (rest lst))
          (if (< i pivot) (push i less) (push i greater)))
        (append (quicksort less) (list pivot) (quicksort greater)))))

(defun main ()
  (let ((xs (loop repeat 20 append (list (random 100)))))
    (format t "Unsorted: ~a~%" xs)
    (format t "Sorted  : ~a~%" (quicksort xs)))
  (uiop:quit))  ;; (require :asdf)
