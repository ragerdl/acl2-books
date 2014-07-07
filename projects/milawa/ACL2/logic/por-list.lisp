; Milawa - A Reflective Theorem Prover
; Copyright (C) 2005-2009 Kookamara LLC
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

(in-package "MILAWA")
(include-book "formulas")
(set-verify-guards-eagerness 2)
(set-case-split-limitations nil)
(set-well-founded-relation ord<)
(set-measure-function rank)

(defund logic.por-list (x y)
  (declare (xargs :guard (and (logic.formula-listp x)
                              (logic.formula-listp y)
                              (same-lengthp x y))))
  (if (and (consp x)
           (consp y))
      (cons (logic.por (car x) (car y))
            (logic.por-list (cdr x) (cdr y)))
    nil))

(defthm logic.por-list-when-not-consp-one
  (implies (not (consp x))
           (equal (logic.por-list x y)
                  nil))
  :hints(("Goal" :in-theory (enable logic.por-list))))

(defthm logic.por-list-when-not-consp-two
  (implies (not (consp y))
           (equal (logic.por-list x y)
                  nil))
  :hints(("Goal" :in-theory (enable logic.por-list))))

(defthm logic.por-list-of-cons-and-cons
  (equal (logic.por-list (cons a x) (cons b y))
         (cons (logic.por a b)
               (logic.por-list x y)))
  :hints(("Goal" :in-theory (enable logic.por-list))))

(defthm logic.por-list-under-iff
  (iff (logic.por-list x y)
       (and (consp x)
            (consp y)))
  :hints(("Goal" :in-theory (enable logic.por-list))))

(defthm logic.por-list-of-list-fix-one
  (equal (logic.por-list (list-fix x) y)
         (logic.por-list x y))
  :hints(("Goal" :induct (cdr-cdr-induction x y))))

(defthm logic.por-list-of-list-fix-two
  (equal (logic.por-list x (list-fix y))
         (logic.por-list x y))
  :hints(("Goal" :induct (cdr-cdr-induction x y))))

(defthm true-listp-of-logic.por-list
  (equal (true-listp (logic.por-list x y))
         t)
  :hints(("Goal" :induct (cdr-cdr-induction x y))))

(defthm forcing-logic.formulap-of-logic.por-list
  (implies (and (force (logic.formula-listp x))
                (force (logic.formula-listp y)))
           (equal (logic.formula-listp (logic.por-list x y))
                  t))
  :hints(("Goal" :induct (cdr-cdr-induction x y))))

(defthm forcing-logic.formula-atblp-of-logic.por-list
  (implies (and (force (logic.formula-list-atblp x atbl))
                (force (logic.formula-list-atblp y atbl)))
           (equal (logic.formula-list-atblp (logic.por-list x y) atbl)
                  t))
  :hints(("Goal" :induct (cdr-cdr-induction x y))))

(defthm consp-of-logic.por-list
  (equal (consp (logic.por-list x y))
         (and (consp x)
              (consp y))))

(defthm car-of-logic.por-list
  (equal (car (logic.por-list x y))
         (if (and (consp x)
                  (consp y))
             (logic.por (car x) (car y))
           nil))
  :hints(("Goal" :expand (logic.por-list x y))))

(defthm cdr-of-logic.por-list
  (equal (cdr (logic.por-list x y))
         (logic.por-list (cdr x) (cdr y))))

(defthm len-of-logic.por-list
  (equal (len (logic.por-list x y))
         (if (< (len x) (len y))
             (len x)
           (len y)))
  :hints(("Goal" :induct (cdr-cdr-induction x y))))

(defthm forcing-logic.por-list-of-singleton-lhs
  (implies (force (consp rhs))
           (equal (logic.por-list (list lhs) rhs)
                  (list (logic.por lhs (car rhs))))))




(deflist logic.all-disjunctionsp (x)
  (equal (logic.fmtype x) 'por*)
  :elementp-of-nil nil
  :guard (logic.formula-listp x))

;; Some of the rules that are generated aren't very good because they're
;; for the general case; we replace them.
(in-theory (disable equal-of-car-when-logic.all-disjunctionsp
                    equal-when-memberp-of-logic.all-disjunctionsp
                    equal-when-memberp-of-logic.all-disjunctionsp-alt))

(defthm logic.fmtype-of-car-when-logic.all-disjunctionsp
  (implies (and (logic.all-disjunctionsp x)
                (consp x))
           (equal (logic.fmtype (car x))
                  'por*)))

(defthm logic.fmtype-when-memberp-of-logic.all-disjunctionsp
  (implies (and (memberp a x)
                (logic.all-disjunctionsp x))
           (equal (logic.fmtype a)
                  'por*))
  :hints(("Goal" :induct (cdr-induction x))))

(defthm logic.fmtype-when-memberp-of-logic.all-disjunctionsp-alt
  (implies (and (logic.all-disjunctionsp x)
                (memberp a x))
           (equal (logic.fmtype a)
                  'por*)))

(defthm forcing-logic.all-disjunctionsp-of-logic.por-list
  (implies (and (force (logic.formula-listp x))
                (force (logic.formula-listp y)))
           (logic.all-disjunctionsp (logic.por-list x y)))
  :hints(("Goal" :induct (cdr-cdr-induction x y))))

(defthm forcing-logic.all-disjunctionsp-of-logic.por-list-free
  (implies (and (equal x (logic.por-list lhs rhs))
                (force (logic.formula-listp lhs))
                (force (logic.formula-listp rhs))
                (force (equal (len lhs) (len rhs))))
           (equal (logic.all-disjunctionsp x)
                  t)))

(defthm logic.fmtype-of-nth-when-logic.all-disjunctionsp
  (implies (logic.all-disjunctionsp x)
           (equal (logic.fmtype (nth n x))
                  (if (< (nfix n) (len x))
                      'por*
                      nil)))
  :hints (("Goal" :in-theory (enable nth))))





(defprojection :list (logic.vlhses x)
               :element (logic.vlhs x)
               :guard (and (logic.formula-listp x)
                           (logic.all-disjunctionsp x))
               :nil-preservingp t)

(defthm forcing-logic.formula-listp-of-logic.vlhses
  (implies (and (force (logic.all-disjunctionsp x))
                (force (logic.formula-listp x)))
           (equal (logic.formula-listp (logic.vlhses x))
                  t))
  :hints(("Goal" :induct (cdr-induction x))))

(defthm forcing-logic.formula-list-atblp-of-logic.vlhses
  (implies (and (force (logic.all-disjunctionsp x))
                (force (logic.formula-list-atblp x atbl)))
           (equal (logic.formula-list-atblp (logic.vlhses x) atbl)
                  t))
  :hints(("Goal" :induct (cdr-induction x))))

(defthm forcing-logic.vlhses-of-logic.por-list
  (implies (and (force (logic.formula-listp x))
                (force (logic.formula-listp y))
                (force (equal (len x) (len y))))
           (equal (logic.vlhses (logic.por-list x y))
                  (list-fix x)))
  :hints(("Goal" :induct (cdr-cdr-induction x y))))

(defthm forcing-logic.vlhses-of-logic.por-list-free
  (implies (and (equal x (logic.por-list lhs rhs))
                (force (logic.formula-listp lhs))
                (force (logic.formula-listp rhs))
                (force (equal (len lhs) (len rhs))))
           (equal (logic.vlhses x)
                  (list-fix lhs))))

(defthm logic.vlhs-of-car-when-all-equalp-of-logic.vlhses
  (implies (all-equalp p (logic.vlhses x))
           (equal (logic.vlhs (car x))
                  (if (consp x)
                      p
                    nil))))



(defprojection :list (logic.vrhses x)
               :element (logic.vrhs x)
               :guard (and (logic.formula-listp x)
                           (logic.all-disjunctionsp x))
               :nil-preservingp t)

(defthm forcing-logic.formula-listp-of-logic.vrhses
  (implies (and (force (logic.all-disjunctionsp x))
                (force (logic.formula-listp x)))
           (equal (logic.formula-listp (logic.vrhses x))
                  t))
  :hints(("Goal" :induct (cdr-induction x))))

(defthm forcing-logic.formula-list-atblp-of-logic.vrhses
  (implies (and (force (logic.all-disjunctionsp x))
                (force (logic.formula-list-atblp x atbl)))
           (equal (logic.formula-list-atblp (logic.vrhses x) atbl)
                  t))
  :hints(("Goal" :induct (cdr-induction x))))

(defthm forcing-logic.vrhses-of-logic.por-list
  (implies (and (force (logic.formula-listp x))
                (force (logic.formula-listp y))
                (force (equal (len x) (len y))))
           (equal (logic.vrhses (logic.por-list x y))
                  (list-fix y)))
  :hints(("Goal" :induct (cdr-cdr-induction x y))))

(defthm forcing-logic.vrhses-of-logic.por-list-free
  (implies (and (equal x (logic.por-list lhs rhs))
                (force (logic.formula-listp lhs))
                (force (logic.formula-listp rhs))
                (force (equal (len lhs) (len rhs))))
           (equal (logic.vrhses x)
                  (list-fix rhs))))




(defthm forcing-equal-of-logic.por-list-rewrite
  (implies (and (force (equal (len x) (len y)))
                (force (logic.formula-listp x))
                (force (logic.formula-listp y)))
           (equal (equal (logic.por-list x y) z)
                  (and (true-listp z)
                       (logic.formula-listp z)
                       (logic.all-disjunctionsp z)
                       (equal (list-fix x) (logic.vlhses z))
                       (equal (list-fix y) (logic.vrhses z)))))
  :hints(("Goal" :induct (cdr-cdr-cdr-induction x y z))))
