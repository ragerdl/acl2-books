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
(include-book "pequal-list-1")
(%interactive)

(%autoprove equal-of-logic.pequal-list-and-logic.pequal-list
            ;; BOZO this proof is really big.  We might do better to improve
            ;; our conditional eqsubst tactic by allowing it to take a list of
            ;; equalities to substitute in.  The autoelim tactic could then
            ;; look for multiple variables to substitute at once, and hit them
            ;; all together.
            ;; NOTE: This rewriting is kind of slow; consider using it for cache
            ;; analysis.
            (%four-cdrs-induction a b c d))

(%autoprove logic.pequal-list-of-app-and-app
            (%cdr-cdr-induction a c)
            (%disable default equal-of-logic.pequal-list-and-logic.pequal-list))

(%autoprove rev-of-logic.pequal-list
            (%cdr-cdr-induction a b)
            (%disable default
                      forcing-logic.formulap-of-logic.pequal
                      aggressive-equal-of-logic.pequals))

