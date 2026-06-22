;;; ------------ chapter 2 content

(defun %length-of-list-tco (lst cnt)
  (if (null lst)
      cnt
      (%length-of-list-tco (cdr lst) (1+ cnt))))

;; tail recursive list length
(defun length-of-list-tco (lst)
  (%length-of-list-tco lst 0))
