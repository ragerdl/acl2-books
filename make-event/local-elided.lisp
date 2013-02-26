(in-package "ACL2")

(local (make-event '(defun foo (x) x)))

(make-event '(local (defun foo (x) x)))

(make-event '(local (defun foo-2 (x) x)))

(progn
  (encapsulate
   ((bar1 (x) t))
   (local (defun bar1 (x) (foo x)))
   (defthm bar1-preserves-consp
     (implies (consp x)
              (consp (bar1 x))))))

(progn
  (make-event '(local (defun g (x) x)))
  (local (defun g2 (x) x))
  (make-event
   (value '(encapsulate
            ((bar2 (x) t))
            (local (defun bar2 (x) (foo x)))
            (defthm bar2-preserves-consp
              (implies (consp x)
                       (consp (bar2 x))))))))

; redundant
(make-event
 (value '(encapsulate
          ((bar2 (x) t))
          (local (defun bar2 (x) (foo x)))
          (defthm bar2-preserves-consp
            (implies (consp x)
                     (consp (bar2 x)))))))

(make-event
 (value '(encapsulate
          ((bar3 (x) t))
          (make-event '(local (defun bar3 (x) (foo x))))
          (defthm bar3-preserves-consp
            (implies (consp x)
                     (consp (bar3 x)))))))

; redundant
(encapsulate
 ((bar3 (x) t))
 (make-event '(local (defun bar3 (x) (foo x))))
 (defthm bar3-preserves-consp
   (implies (consp x)
            (consp (bar3 x)))))

; not still redundant
(include-book "misc/eval" :dir :system)
(must-fail
 (encapsulate
  ((bar3 (x) t))
  (local (defun bar3 (x) (foo x)))
  (defthm bar3-preserves-consp
    (implies (consp x)
             (consp (bar3 x))))))

(make-event '(defun foo-3 (x) x))

(defmacro my-local (x)
  `(local ,x))

(encapsulate
 ()
 (my-local (defun g3 (x) x))
 (make-event '(my-local (defun g3 (x) x)))
 (make-event '(my-local (defun g4 (x) x)))
 (my-local (defun g4 (x) x))
 (progn (my-local (defun g5 (x) x))
        (my-local (make-event (value '(defun g6 (x) x))))))

