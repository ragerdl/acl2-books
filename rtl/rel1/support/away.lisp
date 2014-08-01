;;;***************************************************************
;;;An ACL2 Library of Floating Point Arithmetic

;;;David M. Russinoff
;;;Advanced Micro Devices, Inc.
;;;February, 1998
;;;***************************************************************

(in-package "ACL2")

(include-book "trunc")

(defun away (x n)
  (* (sgn x) (cg (* (expt 2 (1- n)) (sig x))) (expt 2 (- (1+ (expo x)) n))))

(defthm away-pos
    (implies (and (rationalp x)
		  (> x 0)
		  (integerp n)
		  (> n 0))
	     (> (away x n) 0))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo sig fl-weakly-monotonic)
		  :use ((:instance sig-lower-bound)
			(:instance pos* 
				   (x (cg (* (sig x) (expt 2 (1- n))))) 
				   (y (expt 2 (- (1+ (expo x)) n))))
			(:instance sgn+1)
			(:instance expo-monotone (x 1) (y (1- n)))
			(:instance cg-def (x (sig x)))))))

(defthm away-neg
    (implies (and (rationalp x)
		  (< x 0)
		  (integerp n)
		  (> n 0))
	     (< (away x n) 0))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo sig)
		  :use ((:instance sig-lower-bound)
			(:instance pos* 
				   (x (cg (* (sig x) (expt 2 (1- n))))) 
				   (y (expt 2 (- (1+ (expo x)) n))))
			(:instance sgn-1)
			(:instance expo-monotone (x 1) (y (1- n)))
			(:instance cg-def (x (sig x)))))))

(defthm away-zero
    (implies (and (integerp n)
		  (> n 0))
	     (= (away 0 n) 0))
  :rule-classes ())

(defthm sgn-away
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (equal (sgn (away x n))
		    (sgn x)))
  :hints (("Goal" :in-theory (disable away)
		  :use ((:instance away-pos)
			(:instance away-neg)
			(:instance away-zero)))))

(defthm abs-away
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (equal (abs (away x n)) (* (cg (* (expt 2 (1- n)) (sig x))) (expt 2 (- (1+ (expo x)) n)))))
  :hints (("Goal" :in-theory (disable expo sig)
		  :use ((:instance sig-lower-bound)
			(:instance pos* 
				   (x (cg (* (sig x) (expt 2 (1- n))))) 
				   (y (expt 2 (- (1+ (expo x)) n))))
			(:instance sgn-1)
			(:instance sgn+1)
			(:instance expo-monotone (x 1) (y (1- n)))
			(:instance cg-def (x (sig x)))))))

(in-theory (disable cg))

(defthm away-lower-bound
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (>= (abs (away x n)) (abs x)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable sig away)
		  :use ((:instance cg-def (x (* (expt 2 (1- n)) (sig x))))
			(:instance sig-lower-bound)
			(:instance fp-abs)
			(:instance expo+ (m (1- n)) (n (- (1+ (expo x)) n)))))))

(defthm rationalp-away
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (rationalp (away x n))))

(defthm away-0-0
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (iff (= (away x n) 0)
		  (= x 0)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable away)
		  :use ((:instance away-pos)
			(:instance away-neg)
			(:instance away-zero)))))

(defthm away-lower-pos
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (> n 0))
	     (>= (away x n) x))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable abs-away away)
		  :use ((:instance away-lower-bound)
			(:instance away-pos)
			(:instance away-0-0)))))

(defthm expo-away-lower-bound
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (>= (expo (away x n)) (expo x)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo sig away)
		  :use ((:instance away-lower-bound)
			(:instance away-0-0)
			(:instance expo-monotone (y (away x n)))))))

(defthm away-upper-1
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (< (abs (away x n)) (+ (abs x) (expt 2 (- (1+ (expo x)) n)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable abs expo sig away a15)
		  :use ((:instance trunc-lower-1-1)
			(:instance trunc-lower-1-3
				   (u (* (sig x) (expt 2 (1- n))))
				   (v (fl (* (sig x) (expt 2 (1- n)))))
				   (r (expt 2 (- (1+ (expo x)) n))))
			(:instance cg-def (x (* (expt 2 (1- n)) (sig x))))))))

(defthm away-upper-2
    (implies (and (rationalp x)
		  (not (= x 0))
		  (integerp n)
		  (> n 0))
	     (< (abs (away x n)) (* (abs x) (+ 1 (expt 2 (- 1 n))))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable abs expo sig away a15)
		  :use ((:instance away-upper-1)
			(:instance trunc-lower-2-1)))))

(defthm away-upper-pos
    (implies (and (rationalp x)
		  (> x 0)
		  (integerp n)
		  (> n 0))
	     (< (away x n) (* x (+ 1 (expt 2 (- 1 n))))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable abs-pos abs-away expo sig away a15)
		  :use ((:instance away-upper-2)
			(:instance away-pos)))))

(defthm away-upper-3
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (<= (abs (away x n)) (* (abs x) (+ 1 (expt 2 (- 1 n))))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable abs expo sig away a15)
		  :use ((:instance away-upper-1)
			(:instance away-0-0)
			(:instance trunc-lower-2-1)))))

(defthm away-diff
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (< (abs (- (away x n) x)) (expt 2 (- (1+ (expo x)) n))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable away expo abs-away)
		  :use ((:instance trunc-diff-1 (y (away x n)))
			(:instance away-neg)
			(:instance away-pos)
			(:instance away-0-0)
			(:instance away-lower-bound)
			(:instance away-upper-1)))))

(defthm away-diff-pos
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (> n 0))
	     (< (- (away x n) x) (expt 2 (- (1+ (expo x)) n))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable away expo abs-away)
		  :use ((:instance away-diff)
			(:instance away-pos)
			(:instance away-lower-bound)))))

(defthm away-diff-expo-1
    (implies (and (rationalp x)
		  (not (= x (away x n)))
		  (integerp n)
		  (> n 0))
	     (<= (expo (- (away x n) x)) (- (expo x) n)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable away abs expo abs-away)
		  :use ((:instance away-diff)
			(:instance expo-lower-bound (x (- (away x n) x)))
			(:instance expt-strong-monotone 
				   (n (expo (- (away x n) x)))
				   (m (- (1+ (expo x)) n)))))))

(defthm away-rewrite
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (equal (away x n)
		    (* (sgn x) 
		       (cg (* (expt 2 (- (1- n) (expo x))) (abs x))) 
		       (expt 2 (- (1+ (expo x)) n))))))

(in-theory (disable away))

(defthm away-exactp-1
    (implies (and (rationalp x)
		  (integerp n))
	     (= x (* (sgn x) (* (expt 2 (- (1- n) (expo x))) (abs x)) (expt 2 (- (1+ (expo x)) n)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo)
		  :use ((:instance expo+ (n (- (1- n) (expo x))) (m (- (1+ (expo x)) n)))))))

(defthm away-exactp-2
    (implies (and (rationalp x)
		  (rationalp y)
		  (rationalp z)
		  (not (= x 0))
		  (not (= z 0)))
	     (iff (= (* x y z) (* x (cg y) z))
		  (integerp y)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable cg-int cg-int-2 fl)
		  :use ((:instance cg-int-2 (x y))
			(:instance *cancell (x (cg y)) (z (* x z)))))))

(defthm away-exactp-3
    (implies (integerp x) (integerp (- x)))
  :rule-classes ())

(defthm away-exactp-4
    (implies (rationalp x)
	     (equal (- (- x)) x)))

(defthm away-exactp-5
    (implies (rationalp x)
	     (iff (integerp x) (integerp (- x))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable a2)
		  :use ((:instance away-exactp-3)
			(:instance away-exactp-3 (x (- x)))))))

(defthm away-exactp-6
    (implies (and (rationalp x)
		  (integerp n))
	     (iff (exactp x n)
		  (integerp (* (abs x) (expt 2 (- (1- n) (expo x)))))))
  :rule-classes ()
  :hints (("Goal" :use ((:instance away-exactp-5 (x (* x (expt 2 (- (1- n) (expo x))))))))))

(defthm away-exactp-a
    (implies (and (rationalp x)
		  (integerp n) 
		  (> n 0))
	     (iff (= x (away x n))
		  (exactp x n)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo)
		  :use ((:instance away-exactp-1)
			(:instance away-exactp-6)
			(:instance away-exactp-2
				   (x (sgn x))
				   (y (* (expt 2 (- (1- n) (expo x))) (abs x)))
				   (z (expt 2 (- (1+ (expo x)) n))))))))

(defthm away-diff-expo
    (implies (and (rationalp x)
		  (not (exactp x n))
		  (integerp n)
		  (> n 0))
	     (<= (expo (- (away x n) x)) (- (expo x) n)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable away abs exactp2 expo abs-away)
		  :use ((:instance away-diff-expo-1)
			(:instance away-exactp-a)))))

(defthm away-exactp-b-1    
    (implies (and (rationalp x)
		  (rationalp y)
		  (integerp n)
		  (> n 0))
	     (integerp (* (* (sgn x) (cg y) (expt 2 (- (1- n) (expo x)))) (expt 2 (- (1+ (expo x)) n)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo)
		  :use ((:instance integerp-x-y 
				   (x (sgn x))
				   (y (cg (* (expt 2 (- (1- n) (expo x))) (abs x)))))
			(:instance expo+ (n (- (1- n) (expo x))) (m (- (1+ (expo x)) n)))))))

(defthm away-exactp-b-2
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (integerp (* (away x n) (expt 2 (- (1- n) (expo x))))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo sgn)
		  :use ((:instance away-exactp-b-1 (y (* (expt 2 (- (1- n) (expo x))) (abs x))))))))

(defthm away-exactp-b-3
    (implies (and (rationalp x)
		  (not (= x 0))
		  (integerp n)
		  (> n 0))
	     (<= (* (expt 2 (1- n)) (sig x)) (expt 2 n)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo sig abs)
		  :use ((:instance sig-upper-bound)
			(:instance expo+ (n (1- n)) (m 1))))))

(defthm away-exactp-b-4
    (implies (and (rationalp c)
		  (integerp n)
		  (integerp m)
		  (<= c (expt 2 n)))
	     (<= (* c (expt 2 (- m n))) (expt 2 m)))
  :rule-classes ())

(defthm away-exactp-b-5
    (implies (and (rationalp x)
		  (not (= x 0))
		  (integerp n)
		  (> n 0))
	     (<= (abs (away x n)) (expt 2 (1+ (expo x)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable a15 expo sig abs away-rewrite)
		  :use ((:instance away-exactp-b-3)
			(:instance away-exactp-b-4 (c (cg (* (sig x) (expt 2 (1- n))))) (m (1+ (expo x))))
			(:instance n>=cg (n (expt 2 n)) (x (* (expt 2 (1- n)) (sig x))))))))

(defthm away-exactp-b-6
    (implies (and (rationalp x)
		  (not (= x 0))
		  (integerp n)
		  (> n 0)
		  (not (= (abs (away x n)) (expt 2 (1+ (expo x))))))
	     (<= (expo (away x n)) (expo x)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo abs away-rewrite)
		  :use ((:instance away-exactp-b-5)
			(:instance expo-lower-bound (x (away x n)))
			(:instance away-0-0)
			(:instance expt-strong-monotone (n (expo (away x n))) (m (1+ (expo x))))))))

(defthm away-exactp-b-7
    (implies (and (rationalp x)
		  (not (= x 0))
		  (integerp n)
		  (> n 0)
		  (not (= (abs (away x n)) (expt 2 (1+ (expo x))))))
	     (exactp (away x n) n))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo abs away-rewrite)
		  :use ((:instance away-exactp-b-2)
			(:instance away-exactp-b-6)
			(:instance away-0-0)
			(:instance exactp->=-expo (x (away x n)) (e (expo x)))))))

(defthm away-exactp-b-8
    (implies (rationalp x)
	     (= (expo x) (expo (- x))))
  :rule-classes ())

(defthm away-exactp-b-9
    (implies (and (rationalp x)
		  (integerp n)
		  (integerp m)
		  (> m 0)
		  (= (abs x) (expt 2 n)))
	     (exactp x m))
  :rule-classes ()
  :hints (("Goal" :use ((:instance away-exactp-b-8)
			(:instance exactp-2**n)
			(:instance trunc-exactp-5 (x (* x (expt 2 (- (1- m) (expo x))))))))))

(defthm away-exactp-b-10    
    (implies (and (rationalp x)
		  (not (= x 0))
		  (integerp n)
		  (> n 0))
	     (exactp (away x n) n))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo abs abs-away away-rewrite)
		  :use ((:instance away-exactp-b-7)
			(:instance away-exactp-b-9 (x (away x n)) (m n) (n (1+ (expo x))))))))

(defthm away-exactp-b
    (implies (and (rationalp x)
		  (integerp n)
		  (> n 0))
	     (exactp (away x n) n))
  :hints (("Goal" :in-theory (disable expo away-rewrite)
		  :use ((:instance away-exactp-b-10)
			(:instance away-0-0)))))

(defthm away-exactp-c-1
    (implies (and (rationalp x)
		  (> x 0)
		  (integerp n)
		  (> n 0)
		  (rationalp a)
		  (exactp a n)
		  (>= a x)
		  (< a (away x n)))
	     (>= (away x n) (+ x (expt 2 (- (1+ (expo x)) n)))))
  :hints (("Goal" :in-theory (disable expo exactp2 abs-away away-rewrite)
		  :use ((:instance away-exactp-b)
			(:instance fp+1 (x a) (y (away x n)))
			(:instance expo-monotone (y a))
			(:instance expt-monotone (n (- (1+ (expo x)) n)) (m (- (1+ (expo a)) n)))))))

(defthm away-exactp-c
    (implies (and (rationalp x)
		  (> x 0)
		  (integerp n)
		  (> n 0)
		  (rationalp a)
		  (exactp a n)
		  (>= a x))
	     (>= a (away x n)))
  :hints (("Goal" :in-theory (disable expo exactp2 abs-away away-rewrite)
		  :use ((:instance away-exactp-c-1)
			(:instance away-upper-1)
			(:instance away-pos)))))

(defthm away-monotone
    (implies (and (rationalp x)
		  (rationalp y)
		  (integerp n)
		  (> x 0)
		  (> y 0)
		  (> n 0)
		  (<= x y))
	     (<= (away x n) (away y n)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo exactp2 abs-away away-rewrite)
		  :use ((:instance away-exactp-b (x y))
			(:instance away-lower-pos (x y))
			(:instance away-exactp-c (a (away y n)))))))

(defthm away-exactp-d
    (implies (and (rationalp x)
		  (not (= x 0))
		  (integerp n)
		  (> n 0))
	     (<= (abs (away x n)) (expt 2 (1+ (expo x)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo abs away-rewrite)
		  :use ((:instance away-exactp-b-5)))))

(defthm away-pos-rewrite
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (> n 0))
	     (equal (away x n)
		    (* (cg (* (expt 2 (- (1- n) (expo x))) x))
		       (expt 2 (- (1+ (expo x)) n))))))

(in-theory (disable away-rewrite))

(defthm expo-away
    (implies (and (rationalp x)
		  (not (= x 0))
		  (integerp n)
		  (> n 0)
		  (not (= (abs (away x n)) (expt 2 (1+ (expo x))))))
	     (= (expo (away x n)) (expo x)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo abs abs-away away-pos-rewrite)
		  :use ((:instance away-exactp-b-6)
			(:instance expo-monotone (y (away x n)))
			(:instance away-lower-bound)))))

(defthm away-away-1
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (not (= (away x n) (expt 2 (1+ (expo x)))))
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (= (away (away x n) m)
		(* (cg (* (expt 2 (- (1- m) (expo x)))
			  (* (cg (* (expt 2 (- (1- n) (expo x))) x))
			     (expt 2 (- (1+ (expo x)) n)))))
		   (expt 2 (- (1+ (expo x)) m)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo)
		  :use ((:instance away-pos)
			(:instance expo-away)))))

(defthm away-away-2
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (not (= (away x n) (expt 2 (1+ (expo x)))))
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (= (away (away x n) m)
		(* (cg (* (cg (* (expt 2 (- (1- n) (expo x))) x)) (expt 2 (- m n)))) 
		   (expt 2 (- (1+ (expo x)) m)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo away-pos-rewrite away-rewrite)
		  :use ((:instance away-away-1)
			(:instance expo+ (n (- (1- m) (expo x))) (m (- (1+ (expo x)) n)))))))

(defthm away-away-3
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (not (= (away x n) (expt 2 (1+ (expo x)))))
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (= (away (away x n) m)
		(* (cg (/ (cg (* (expt 2 (- (1- n) (expo x))) x)) (expt 2 (- n m)))) 
		   (expt 2 (- (1+ (expo x)) m)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo away-pos-rewrite away-rewrite)
		  :use ((:instance away-away-2)))))

(defthm away-away-4
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (not (= (away x n) (expt 2 (1+ (expo x)))))
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (= (away (away x n) m)
		(* (cg (/ (* (expt 2 (- (1- n) (expo x))) x) (expt 2 (- n m)))) 
		   (expt 2 (- (1+ (expo x)) m)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable cg/int expo away-pos-rewrite away-rewrite)
		  :use ((:instance away-away-3)
			(:instance cg/int 
				   (x (* (expt 2 (- (1- n) (expo x))) x))
				   (n (expt 2 (- n m))))))))

(defthm away-away-5
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (not (= (away x n) (expt 2 (1+ (expo x)))))
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (= (away (away x n) m)
		(* (cg (* (expt 2 (- (1- m) (expo x))) x))
		   (expt 2 (- (1+ (expo x)) m)))))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo away-pos-rewrite away-rewrite)
		  :use ((:instance away-away-4)))))

(defthm away-away-6
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (not (= (away x n) (expt 2 (1+ (expo x)))))
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (equal (away (away x n) m)
		    (away x m)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo)
		  :use ((:instance away-away-5)))))

(defthm away-away-7
    (implies (and (rationalp x)
		  (> x 0)
		  (integerp n)
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (>= (away x m) (away x n)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo exactp2 away-rewrite)
		  :use ((:instance away-exactp-c (a (away x m)))
			(:instance away-exactp-b (n m))
			(:instance away-lower-pos (n m))
			(:instance exactp-<= (x (away x m)))))))

(defthm away-away-8
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (>= (away x m) (away x n)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo exactp2 away-rewrite)
		  :use ((:instance away-away-7)
			(:instance away-0-0)
			(:instance away-0-0 (n m))))))

(defthm away-away-9
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (= (away x n) (expt 2 (1+ (expo x))))
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (equal (away (away x n) m)
		    (away x m)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo away-rewrite exactp2)
		  :use ((:instance away-away-8)
			(:instance exactp-2**n (n (1+ (expo x))))
			(:instance away-exactp-a (x (expt 2 (1+ (expo x)))) (n m))
			(:instance away-exactp-d (n m))))))

(defthm away-away
    (implies (and (rationalp x)
		  (>= x 0)
		  (integerp n)
		  (integerp m)
		  (> m 0)
		  (>= n m))
	     (equal (away (away x n) m)
		    (away x m)))
  :rule-classes ()
  :hints (("Goal" :in-theory (disable expo away-rewrite exactp2)
		  :use ((:instance away-away-9)
			(:instance away-away-6)))))
