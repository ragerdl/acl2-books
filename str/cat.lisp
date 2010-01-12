; ACL2 String Library
; Copyright (C) 2009 Centaur Technology
; Contact: jared@cs.utexas.edu
;
; This program is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2 of the License, or (at your option) any later
; version.  This program is distributed in the hope that it will be useful but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
; more details.  You should have received a copy of the GNU General Public
; License along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

(in-package "STR")
(include-book "doc")
(local (include-book "arithmetic"))
(local (include-book "unicode/take" :dir :system))

(defmacro cat (&rest args)
  
  ":Doc-Section Str
  Concatenate strings~/
  
  ~c[(cat x y z ...)] is identical to ~c[(concatenate 'string x y z ...)], but 
  has a somewhat shorter name. ~/ "

  `(concatenate 'string . ,args))


(defund append-chars-aux (x n y)
  (declare (xargs :guard (and (stringp x)
                              (natp n)
                              (< n (length x))))
           (type string x)
           (type integer n))
  (if (zp n)
      (cons (char x 0) y)
    (append-chars-aux x (- n 1) (cons (char x n) y))))

(encapsulate
 ()
 (local (defthm lemma
          (implies (and (not (zp n))
                        (<= n (len x)))
                   (equal (append (simpler-take (- n 1) x) (cons (nth (- n 1) x) y))
                          (append (simpler-take n x) y)))
          :hints(("goal" 
                  :in-theory (enable simpler-take)
                  :induct (simpler-take n x)))))

 (defthm append-chars-aux-correct
   (implies (and (stringp x)
                 (natp n)
                 (< n (length x)))
            (equal (append-chars-aux x n y)
                   (append (take (+ 1 n) (coerce x 'list)) y)))
   :hints(("Goal"
           :in-theory (enable append-chars-aux)
           :induct (append-chars-aux x n y)))))

(local (in-theory (disable append-chars-aux-correct)))

(local (defthm append-chars-aux-correct-better
         (implies (and (stringp x)
                       (natp n)
                       (< n (length x)))
                  (equal (append-chars-aux x n y)
                         (append (simpler-take (+ 1 n) (coerce x 'list)) y)))
         :hints(("Goal"
                 :use ((:instance append-chars-aux-correct))))))

(defund append-chars (x y)

  ":Doc-Section Str 
  Efficient (append (coerce x 'list) y)~/
 
  This function is logically equal to ~c[(append (coerce x 'list) y)], but is
  implemented efficiently via ~c[char]. ~/ "

  (declare (xargs :guard (stringp x))
           (type string x))
                  
  (mbe :logic (append (coerce x 'list) y)
       :exec (if (equal x "")
                 y
               (append-chars-aux x (1- (length x)) y))))

(defthm character-listp-of-append-chars
  (equal (character-listp (append-chars x y))
         (character-listp y))
  :hints(("Goal" :in-theory (enable append-chars))))



(defund revappend-chars-aux (x n xl y)
  (declare (xargs :guard (and (stringp x)
                              (natp n)
                              (natp xl)
                              (<= n xl)
                              (equal xl (length x)))
                  :measure (nfix (- (nfix xl) (nfix n)))))
  (if (mbe :logic (zp (- (nfix xl) (nfix n)))
           :exec (= n xl))
      y
    (revappend-chars-aux x 
                         (mbe :logic (+ (nfix n) 1)
                              :exec (+ n 1))
                         xl
                         (cons (char x n) y))))

(defthm revappend-chars-aux-correct
  (implies (and (stringp x)
                (natp n)
                (natp xl)
                (<= n xl)
                (equal xl (length x)))
           (equal (revappend-chars-aux x n xl y)
                  (revappend (nthcdr n (coerce x 'list)) y)))
  :hints(("Goal" 
          :in-theory (enable revappend-chars-aux)
          :induct (revappend-chars-aux x n xl y))))

(defund revappend-chars (x y)
  
  ":Doc-Section Str
  Efficient (revappend (coerce x 'list) y~/

  This function is logically equal to ~c[(revappend (coerce x 'list) y)], but 
  is implemented efficiently via ~c[char]. ~/ "

  (declare (xargs :guard (stringp x))
           (type string x))

  (mbe :logic (revappend (coerce x 'list) y)
       :exec (revappend-chars-aux x 0 (length x) y)))

(defthm character-listp-of-revappend-chars
  (equal (character-listp (revappend-chars x y))
         (character-listp y))
  :hints(("Goal" :in-theory (enable revappend-chars))))



#||

(include-book ;; newline to fool dependency scanner
 "cat")

;; Simple experiments on fv-1:

(defparameter *str* "Hello, world!")

;; 3.84 seconds, 2.08 GB allocated
(progn
  (gc$)
  (time (loop for i fixnum from 1 to 5000000
              do
              (revappend (coerce *str* 'list) nil))))

;; .05 seconds, 20 MB allocated
(progn
  (gc$)
  (time (loop for i fixnum from 1 to 100000
              do
              (STR::revappend-chars *str* nil))))


;; 4.38 seconds, 2.08 GB allocated
(progn
  (gc$)
  (time (loop for i fixnum from 1 to 5000000
              do
              (append (coerce *str* 'list) nil))))

;; .06 seconds, 20 MB allocated
(progn
  (gc$)
  (time (loop for i fixnum from 1 to 100000
              do
              (STR::append-chars *str* nil))))

||#
