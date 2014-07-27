; Repeat function and lemmas
; Copyright (C) 2005-2013 Kookamara LLC
;
; Contact:
;
;   Kookamara LLC
;   11410 Windermere Meadows
;   Austin, TX 78759, USA
;   http://www.kookamara.com/
;
; License: (An MIT/X11-style license)
;
;   Permission is hereby granted, free of charge, to any person obtaining a
;   copy of this software and associated documentation files (the "Software"),
;   to deal in the Software without restriction, including without limitation
;   the rights to use, copy, modify, merge, publish, distribute, sublicense,
;   and/or sell copies of the Software, and to permit persons to whom the
;   Software is furnished to do so, subject to the following conditions:
;
;   The above copyright notice and this permission notice shall be included in
;   all copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;   DEALINGS IN THE SOFTWARE.
;
; Original author: Jared Davis <jared@kookamara.com>
;
; repeat.lisp
; This file was originally part of the Unicode library.

(in-package "ACL2")
(include-book "rev")
(local (include-book "take"))
(local (include-book "nthcdr"))

(local (defthm commutativity-2-of-+
         (equal (+ x (+ y z))
                (+ y (+ x z)))))

(local (defthm fold-consts-in-+
         (implies (and (syntaxp (quotep x))
                       (syntaxp (quotep y)))
                  (equal (+ x (+ y z)) (+ (+ x y) z)))))

(local (defthm distributivity-of-minus-over-+
         (equal (- (+ x y)) (+ (- x) (- y)))))


(defsection replicate
  :parents (std/lists make-list)
  :short "@(call replicate) creates a list of @('x')es with length @('n'); it
is a simpler alternative to @(see make-list)."

  (defund replicate-fn (n x)
    (declare (xargs :guard (natp n)
                    :verify-guards nil))
    (mbe :logic (if (zp n)
                    nil
                  (cons x (replicate-fn (- n 1) x)))

; On CCL, a simple loop of (loop for i from 1 to 10000 do (replicate 10000 6))
; finished in 2.74 seconds when we use make-list, versus 3.69 seconds when we
; use make-list-ac.  So lets use make-list.

         :exec (make-list n :initial-element x)))

  (defmacro replicate (n x)
    `(replicate-fn ,n ,x))

  (add-macro-alias replicate replicate-fn)

  (local (in-theory (enable replicate)))

  (defthm replicate-when-zp
    (implies (zp n)
             (equal (replicate n a)
                    nil)))

  (defthm |(replicate 0 x)|
    (equal (replicate 0 x)
           nil))

  (defthm replicate-under-iff
    (iff (replicate n x)
         (not (zp n))))

  (defthm consp-of-replicate
    (equal (consp (replicate n a))
           (not (zp n))))

  (defthm replicate-1
    (equal (replicate 1 a)
           (list a)))

  (defthm take-when-atom
    (implies (atom x)
             (equal (take n x)
                    (replicate n nil))))

  (defthm len-of-replicate
    (equal (len (replicate n x))
           (nfix n)))

  (defthm replicate-of-nfix
    (equal (replicate (nfix n) x)
           (replicate n x)))

  (defthm car-of-replicate-increment
    ;; Goofy rule that helps when recurring when replicate is involved.
    ;; BOZO there's a better rule than this in str/arithmetic, but it case-splits.
    (implies (natp n)
             (equal (car (replicate (+ 1 n) x))
                    x)))

  (defthm cdr-of-replicate-increment
    ;; Goofy rule that helps when recurring when replicate is involved.
    (implies (natp n)
             (equal (cdr (replicate (+ 1 n) x))
                    (replicate n x))))

  (defthm member-of-replicate
    (equal (member a (replicate n b))
           (if (equal a b)
               (replicate n b)
             nil)))

  (encapsulate
    ()
    (local (defun dec-dec-induct (k n)
             (if (zp k)
                 nil
               (if (zp n)
                   nil
                 (dec-dec-induct (- k 1) (- n 1))))))

    (defthm take-of-replicate
      (equal (take n (replicate k a))
             (if (<= (nfix n) (nfix k))
                 (replicate n a)
               (append (replicate k a)
                       (replicate (- (nfix n) (nfix k)) nil))))
      :hints(("Goal" :induct (dec-dec-induct k n))))

    (defthm nthcdr-of-replicate
      (equal (nthcdr n (replicate k a))
             (if (<= (nfix n) (nfix k))
                 (replicate (- (nfix k) (nfix n)) a)
               nil))
      :hints(("Goal" :induct (dec-dec-induct k n)))))


  (defthm append-of-replicate-to-cons-of-same
    (equal (append (replicate n a) (cons a x))
           (cons a (append (replicate n a) x))))

  (encapsulate
    ()
    (local (defthm l0
             (implies (equal (append (replicate n a) x) y)
                      (and (equal (replicate n a) (take n y))
                           (equal (nthcdr n y) x)))))

    (local (defthm l1
             (implies (not (<= (nfix n) (len y)))
                      (not (equal (append (replicate n a) x) y)))))

    (local (defthm l2
             (implies (and (<= n (len y))
                           (equal (replicate n a) (take n y))
                           (equal x (nthcdr n y)))
                      (equal (append (replicate n a) x) y))
             :hints(("Goal"
                     :in-theory (disable append-of-take-and-nthcdr)
                     :use ((:instance append-of-take-and-nthcdr
                                      (n n)
                                      (x y)))))))

    (defthm equal-of-append-replicate
      (implies (case-split (<= n (len y)))
               (equal (equal (append (replicate n a) x) y)
                      (and (equal (replicate n a) (take n y))
                           (equal x (nthcdr n y)))))
      :hints(("Goal"
              :use ((:instance l0)
                    (:instance l2))))))

  (defthm rev-of-replicate
    (equal (rev (replicate n a))
           (replicate n a))))


(local (in-theory (enable replicate)))


(defsection make-list-ac-removal
  :parents (replicate make-list)
  :short "Rewrite rule that eliminates @('make-list-ac') (and hence @(see
make-list)) in favor of @(see replicate)."

  (local (defun silly-replicate (n x acc)
           (if (zp n)
               acc
             (cons x (silly-replicate (- n 1) x acc)))))

  (local (defthm lemma1
           (equal (make-list-ac n x acc)
                  (silly-replicate n x acc))))

  (local (defthm lemma2
           (equal (silly-replicate n x acc)
                  (append (replicate n x) acc))))

  (defthm make-list-ac-removal
    (equal (make-list-ac n x acc)
           (append (replicate n x)
                   acc))))

(verify-guards replicate-fn)


(defsection take-of-take-split
  :parents (std/lists/take)
  :short "Aggressive case splitting rule to reduce @('(take a (take b x))')."
  :long "@(def take-of-take-split)

<p>This rule may sometimes cause too much case splitting.  If you disable it,
nests of @('take') can still be reduced when ACL2 can determine the
relationship between @('a') and @('b'), using the following related rules:</p>

@(def take-of-take-same)
@(def take-more-of-take-fewer)
@(def take-fewer-of-take-more)"

  :autodoc nil

  (local (defun my-induct (a b x)
           (if (or (zp a)
                   (zp b))
               (list a b x)
             (my-induct (- a 1) (- b 1) (cdr x)))))

  (defthm take-more-of-take-fewer
    (implies (< (nfix b) (nfix a))
             (equal (take a (take b x))
                    (append (take b x) (replicate (- (nfix a) (nfix b)) nil))))
    :hints(("Goal" :induct (my-induct a b x))))

  (defthm take-of-take-split
    ;; This has a very aggressive case split.
    (equal (take a (take b x))
           (if (<= (nfix a) (nfix b))
               (take a x)
             (append (take b x) (replicate (- (nfix a) (nfix b)) nil))))))
