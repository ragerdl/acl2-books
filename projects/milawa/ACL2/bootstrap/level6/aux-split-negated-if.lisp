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
(include-book "aux-split")
(%interactive)


#||

An experiment to see if it's worth improving eqtrace-bldr-okp... it helps, but
it probably isn't worth the trouble.

;(defund rw.slow-hypbox-arities (x)
  (declare (xargs :guard (rw.hypboxp x)))
  (app (logic.slow-term-list-arities (rw.hypbox->left x))
       (logic.slow-term-list-arities (rw.hypbox->right x))))

;(defund rw.hypbox-arities (x acc)
  (declare (xargs :guard (and (rw.hypboxp x)
                              (true-listp acc))))
  (logic.term-list-arities (rw.hypbox->left x)
                           (logic.term-list-arities (rw.hypbox->right x)
                                                    acc)))

(defthm true-listp-of-rw.hypbox-arities
  (implies (force (true-listp acc))
           (equal (true-listp (rw.hypbox-arities x acc))
                  t))
  :hints(("Goal" :in-theory (enable rw.hypbox-arities))))

(defthm rw.hypbox-arities-removal
  (implies (force (true-listp acc))
           (equal (rw.hypbox-arities x acc)
                  (app (rw.slow-hypbox-arities x) acc)))
  :hints(("Goal" :in-theory (enable rw.hypbox-arities
                                    rw.slow-hypbox-arities))))

(defthm rw.slow-hypbox-arities-correct
  (implies (force (rw.hypboxp x))
           (equal (logic.arities-okp (rw.slow-hypbox-arities x) atbl)
                  (rw.hypbox-atblp x atbl)))
  :hints(("Goal"
          :in-theory (e/d (rw.slow-hypbox-arities
                           rw.hypbox-atblp)
                          ((:executable-counterpart acl2::force))))))

(definlined rw.fast-hypbox-atblp (x atbl)
  (declare (xargs :guard (and (rw.hypboxp x)
                              (logic.arity-tablep atbl))))
  ;; This is a generally faster check than rw.hypbox-atblp.  The speed advantage
  ;; comes from collecting and mergesorting the function names (to remove dupes)
  ;; before arity checking begins.
  ;;
  ;; We could consider using mergesort-map on arity table and use
  ;; ordered-list-subsetp here, but we think that generally the aren't enough
  ;; functions mentioned in the hypbox to make that worthwhile.  And, at any
  ;; rate, we get a pretty big advantage just from running the mergesort.
  ;;
  ;; We could also consider using ordered-list-subsetp and requiring that the
  ;; atbl be sorted ahead of time.  That might be quite valuable, but we haven't
  ;; looked into fixing up the proof checkers to handle it.
  (let* ((arities (rw.hypbox-arities x nil))
         (sorted  (mergesort arities)))
    (logic.arities-okp sorted atbl)))

(defthm rw.fast-hypbox-atblp-removal
  (implies (force (rw.hypboxp x))
           (equal (rw.fast-hypbox-atblp x atbl)
                  (rw.hypbox-atblp x atbl)))
  :hints(("Goal" :in-theory (enable rw.fast-hypbox-atblp))))



(ACL2::defttag rw.eqtrace-bldr-okp-timing)
(ACL2::progn!
 (ACL2::set-raw-mode t)
; (COMMON-LISP::DEFUN RW.EQTRACE-BLDR-OKP (X ATBL)
                     (LET ((METHOD (LOGIC.METHOD X))
                           (CONCLUSION (LOGIC.CONCLUSION X))
                           (SUBPROOFS (LOGIC.SUBPROOFS X))
                           (EXTRAS (LOGIC.EXTRAS X)))
                          (AND (EQUAL METHOD 'RW.EQTRACE-BLDR)
                               (TUPLEP 2 EXTRAS)
                               (LET ((TRACE (FIRST EXTRAS))
                                     (BOX (SECOND EXTRAS)))
                                    (AND (RW.EQTRACEP TRACE)
                                         (RW.HYPBOXP BOX)
                                         (RW.FAST-HYPBOX-ATBLP BOX ATBL)
                                         (RW.EQTRACE-OKP TRACE BOX)
                                         (EQUAL CONCLUSION (RW.EQTRACE-FORMULA TRACE BOX))
                                         (NOT SUBPROOFS))))))

; (COMMON-LISP::DEFUN RW.EQTRACE-CONTRADICTION-BLDR-OKP (X ATBL)
               (LET ((METHOD (LOGIC.METHOD X))
                     (CONCLUSION (LOGIC.CONCLUSION X))
                     (SUBPROOFS (LOGIC.SUBPROOFS X))
                     (EXTRAS (LOGIC.EXTRAS X)))
                    (AND (EQUAL METHOD 'RW.EQTRACE-CONTRADICTION-BLDR)
                         (TUPLEP 2 EXTRAS)
                         (LET ((TRACE (FIRST EXTRAS))
                               (BOX (SECOND EXTRAS)))
                              (AND (RW.EQTRACEP TRACE)
                                   (RW.EQTRACE-CONTRADICTIONP TRACE)
                                   (RW.EQTRACE-ATBLP TRACE ATBL)
                                   (RW.HYPBOXP BOX)
                                   (RW.FAST-HYPBOX-ATBLP BOX ATBL)
                                   (RW.EQTRACE-OKP TRACE BOX)
                                   (EQUAL CONCLUSION (RW.HYPBOX-FORMULA BOX))
                                   (NOT SUBPROOFS)))))))


||#

(%autoadmit clause.aux-split-negated-if)


;; speed hint
(local (%disable default
                 AGGRESSIVE-EQUAL-OF-LOGIC.PNOTS
                 AGGRESSIVE-EQUAL-OF-LOGIC.PEQUALS
                 AGGRESSIVE-EQUAL-OF-LOGIC.PORS
                 FORCING-LOGIC.FUNCTION-OF-LOGIC.FUNCTION-NAME-AND-LOGIC.FUNCTION-ARGS-FREE
                 LOGIC.TERM-LISTP-OF-SUBSETP-WHEN-LOGIC.TERM-LISTP
                 LOGIC.TERM-LISTP-WHEN-LOGIC.VARIABLE-LISTP-CHEAP
                 FORCING-LOGIC.DISJOIN-FORMULAS-OF-TWO-ELEMENT-LIST
                 LOGIC.DISJOIN-FORMULAS-WHEN-NOT-CONSP

                 CONSP-WHEN-LOGIC.LAMBDAP-CHEAP
                 LOGIC.FUNCTIONP-WHEN-LOGIC.LAMBDAP-CHEAP
                 LOGIC.TERMP-WHEN-INVALID-MAYBE-EXPENSIVE

                 logic.termp-when-logic.formulap
                 same-length-prefixes-equal-cheap
                 expensive-arithmetic-rules
                 expensive-arithmetic-rules-two
                 unusual-subsetp-rules
                 car-when-not-consp
                 cdr-when-not-consp
                 type-set-like-rules
                 unusual-memberp-rules
                 ))

(%autoprove forcing-logic.appealp-of-clause.aux-split-negated-if
            (%enable default
                     logic.term-formula
                     clause.aux-split-goal
                     clause.aux-split-negated-if))

(%autoprove forcing-logic.conclusion-of-clause.aux-split-negated-if
            (%enable default
                     logic.term-formula
                     clause.aux-split-goal
                     clause.aux-split-negated-if))

(%autoprove forcing-logic.proofp-of-clause.aux-split-negated-if
            (%enable default
                     logic.term-formula
                     clause.aux-split-goal
                     clause.aux-split-negated-if))

