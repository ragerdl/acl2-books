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
(include-book "gather")
(%interactive)

(%autoprove rw.theory-env-okp-of-lookup-when-rw.theory-list-env-okp-of-range
            (%cdr-induction theories))


(%defaggregate tactic.world
  (index
   forcingp
   betamode
   liftlimit
   splitlimit
   blimit
   rlimit
   rwn
   urwn
   noexec
   theories
   defs
   depth
   allrules
   assm-primaryp
   assm-secondaryp
   assm-directp
   assm-negativep
   )
  :require
  ((natp-of-tactic.world->index                         (natp index))
   (booleanp-of-tactic.world->forcingp                  (booleanp forcingp))
   (symbolp-of-tactic.world->betamode                   (symbolp betamode))
   (natp-of-tactic.world->liftlimit                     (natp liftlimit))
   (natp-of-tactic.world->splitlimit                    (natp splitlimit))
   (natp-of-tactic.world->blimit                        (natp blimit))
   (natp-of-tactic.world->rlimit                        (natp rlimit))
   (natp-of-tactic.world->rwn                           (natp rwn))
   (natp-of-tactic.world->urwn                          (natp urwn))
   (definition-listp-of-tactic.world->defs              (definition-listp defs))
   (natp-of-tactic.world->depth                         (natp depth))
   (rw.theory-mapp-of-tactic.world->theories            (rw.theory-mapp theories))
   (logic.function-symbol-listp-of-tactic.world->noexec (logic.function-symbol-listp noexec))
   (rw.rule-listp-of-tactic.world->allrules             (rw.rule-listp allrules))
   (booleanp-of-tactic.world->assm-primaryp             (booleanp assm-primaryp))
   (booleanp-of-tactic.world->assm-secondaryp           (booleanp assm-secondaryp))
   (booleanp-of-tactic.world->assm-directp              (booleanp assm-directp))
   (booleanp-of-tactic.world->assm-negativep            (booleanp assm-negativep))
   ))

(%deflist tactic.world-listp (x)
          (tactic.worldp x))

(%autoadmit tactic.world-atblp)

(%autoprove booleanp-of-tactic.world-atblp
            (%enable default tactic.world-atblp))

(%autoprove tactic.world-atblp-of-nil
            (%enable default tactic.world-atblp))

(%autoprove lemma-for-rw.theory-atblp-of-looked-up-theory
            (%cdr-induction theories))

(%autoprove rw.theory-atblp-of-looked-up-theory
            (%enable default
                     tactic.world-atblp
                     lemma-for-rw.theory-atblp-of-looked-up-theory))

(%autoprove tactic.world-atblp-of-tactic.world
            (%enable default tactic.world-atblp))

(%autoprove rw.theory-list-atblp-of-range-of-tactic.world->theories
            (%enable default tactic.world-atblp))

(%autoprove logic.formula-list-atblp-of-tactic.world->defs
            (%enable default tactic.world-atblp))

(%autoprove rw.rule-list-atblp-of-tactic.world->allrules
            (%enable default tactic.world-atblp))

(%deflist tactic.world-list-atblp (x atbl)
          (tactic.world-atblp x atbl))



(%autoadmit tactic.world-env-okp)

(%autoprove booleanp-of-tactic.world-env-okp
            (%enable default tactic.world-env-okp))

(%autoprove tactic.world-env-okp-of-nil
            (%enable default tactic.world-env-okp))

(%autoprove lemma-for-rw.theory-env-okp-of-looked-up-theory
            (%cdr-induction theories))

(%autoprove rw.theory-env-okp-of-looked-up-theory
            (%enable default
                     tactic.world-env-okp
                     lemma-for-rw.theory-env-okp-of-looked-up-theory))

(%autoprove tactic.world-env-okp-of-tactic.world
            (%enable default tactic.world-env-okp))

(%autoprove rw.theory-list-env-okp-of-range-of-tactic.world->theories
            (%enable default tactic.world-env-okp))

(%autoprove subsetp-of-tactic.world->defs-and-axioms
            (%enable default tactic.world-env-okp))

(%autoprove rw.rule-list-env-okp-of-tactic.world->allrules
            (%enable default tactic.world-env-okp))

(%deflist tactic.world-list-env-okp (x axioms thms)
  (tactic.world-env-okp x axioms thms))


(%autoprove subsetp-of-tactic.world->defs-when-memberp
            (%cdr-induction worlds))

(%autoprove subsetp-of-tactic.world->defs-when-memberp-alt)

(%autoprove rw.theory-env-okp-when-memberp
            (%cdr-induction worlds))

(%autoprove rw.theory-env-okp-when-memberp-alt
            (%cdr-induction worlds))





(%autoadmit tactic.find-world)

(%autoprove tactic.worldp-of-tactic.find-world-under-iff
            (%autoinduct tactic.find-world)
            (%restrict default tactic.find-world (equal worlds 'worlds)))

(%autoprove tactic.world-atblp-of-tactic.find-world-under-iff
            (%autoinduct tactic.find-world)
            (%restrict default tactic.find-world (equal worlds 'worlds)))

(%autoprove tactic.world-env-okp-of-tactic.find-world-under-iff
            (%autoinduct tactic.find-world)
            (%restrict default tactic.find-world (equal worlds 'worlds)))

(%autoprove tactic.world->index-of-tactic.find-world
            (%autoinduct tactic.find-world)
            (%restrict default tactic.find-world (equal worlds 'worlds)))

(%autoprove subsetp-of-tactic.world->defs-of-tactic.find-world-and-axioms
            (%disable default subsetp-of-tactic.world->defs-and-axioms)
            (%use (%instance (%thm subsetp-of-tactic.world->defs-and-axioms)
                             (world (tactic.find-world index worlds)))))

(%autoprove rw.theory-list-env-okp-of-range-of-tactic.world->theories-of-find-world
            (%disable default rw.theory-list-env-okp-of-range-of-tactic.world->theories)
            (%use (%instance (%thm rw.theory-list-env-okp-of-range-of-tactic.world->theories)
                             (world (tactic.find-world world worlds)))))


(%autoadmit tactic.increment-world-index)

(%autoprove tactic.worldp-of-tactic.increment-world-index
            (%enable default tactic.increment-world-index))

(%autoprove tactic.world-atblp-of-tactic.increment-world-index
            (%enable default tactic.increment-world-index))

(%autoprove tactic.world-env-okp-of-tactic.increment-world-index
            (%enable default tactic.increment-world-index))

(%autoprove tactic.world->index-of-tactic.increment-world-index
            (%enable default tactic.increment-world-index))


(%ensure-exactly-these-rules-are-missing "../../tactics/worldp")
