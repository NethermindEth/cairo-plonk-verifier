use plonk_verifier::fields::fq_2::Fq2FrobeniusTrait;
use plonk_verifier::fields::fq_sparse::FqSparseTrait;
use plonk_verifier::traits::{FieldUtils};
//use plonk_verifier::curve::groups::ECOperationsCircuitFq2;
use plonk_verifier::curve::groups::{g1, g2, ECGroup};
use plonk_verifier::curve::groups::{Affine, AffineG1 as PtG1, AffineG2 as PtG2};
// use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
use plonk_verifier::fields::{
    Fq, fq, Fq2, fq2, Fq6, Fq12, Fq12Utils, Fq12Ops, FqOps, Fq2Utils, Fq2Ops, Fq12Exponentiation,
};
use plonk_verifier::fields::{Fq12Sparse034, Fq12Sparse01234, FqSparse};
// use plonk_verifier::fields::print::{Fq2Display, Fq12Display, FqDisplay};
use plonk_verifier::fields::frobenius::pi;
use core::circuit::CircuitModulus; 

// This implementation follows the paper at https://eprint.iacr.org/2022/1162
// Pairings in Rank-1 Constraint Systems, Youssef El Housni et al.
// Section 6.1 Miller loop
//
// Parts about miller steps implementations and line function evaluations
//
// Miller steps
// ------------
//
// Double step:
// * acc + acc
//
// Double and Add step:
// * acc + Q + acc (to save on extra steps in doubling vs adding)
// * Skip intermediate (Acc + Q) y calculation and substitute in final slope calculation
//
// Line evaluations
// ----------------
// Line evaluations use a D-type twist,
// gψₛ(P) = 1 − λ·xₚ/yₚ·w + (λxₛ − yₛ)/yₚ·w³
// Represented by a 034 sparse element in Fq12 over Fq2
// (1, 0, 0, -λ·xₚ/yₚ, (λxₛ − yₛ)/yₚ, 0)
//

#[derive(Copy, Drop)]
struct PPrecompute {
    neg_x_over_y: Fq,
    y_inv: Fq,
}

fn p_precompute(p: PtG1, m: CircuitModulus) -> PPrecompute {
    let y_inv = (p.y).inv(m);
    PPrecompute { neg_x_over_y: p.x.neg(m).mul(y_inv, m), y_inv }
}

type PPre = PPrecompute;
type NZNum = NonZero<u256>;
type F034 = Fq12Sparse034;

#[derive(Copy, Drop)]
struct LineFn {
    slope: Fq2,
    c: Fq2,
}

mod line_fn {
    use core::circuit::conversions::from_u256;

    use plonk_verifier::fields::fq_2::Fq2FrobeniusTrait;
    use plonk_verifier::fields::fq_sparse::FqSparseTrait;
    use plonk_verifier::traits::{FieldUtils};
    use plonk_verifier::curve::groups::ECOperationsCircuitFq2;
    use plonk_verifier::curve::groups::{g1, g2, ECGroup};
    use plonk_verifier::curve::groups::{Affine, AffineG1 as PtG1, AffineG2 as PtG2};
    // use plonk_verifier::fields::fq_generics::{
    //     TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,
    // };
    use plonk_verifier::fields::{
        Fq, fq, Fq2, fq2, Fq6, Fq12, Fq12Utils, Fq12Ops, FqOps, Fq2Utils, Fq2Ops,
        Fq12Exponentiation,
    };
    use plonk_verifier::fields::{Fq12Sparse034, Fq12Sparse01234, FqSparse};
    // use plonk_verifier::fields::print::{Fq2Display, Fq12Display, FqDisplay};
    use plonk_verifier::fields::frobenius::pi;
    use super::{LineFn, PPre, NZNum, F034};
    use plonk_verifier::curve::constants::FIELD_U384;
    use core::circuit::CircuitModulus;
    
    #[inline(always)]
    fn line_fn(slope: Fq2, s: PtG2, m: CircuitModulus) -> LineFn {
        LineFn { slope, c: slope.mul(s.x, m).sub(s.y, m) }
    }

    // For πₚ frobeneus map
    // Multiply by Fp2::NONRESIDUE^(2((q^1) - 1)/6)
    #[inline(always)]
    fn fq2_mul_nr_1p_2(a: Fq2, m: CircuitModulus) -> Fq2 {
        a.mul(fq2(pi::Q1X2_C0, pi::Q1X2_C1), m)
    }


    // For πₚ frobeneus map
    // Multiply by Fp2::NONRESIDUE^(3((q^1) - 1)/6)
    #[inline(always)]
    fn fq2_mul_nr_1p_3(a: Fq2, m: CircuitModulus) -> Fq2 {
        a.mul(fq2(pi::Q1X3_C0, pi::Q1X3_C1), m)
    }

    // For πₚ² frobeneus map
    // Multiply by Fp2::NONRESIDUE^(2(p^2-1)/6)
    #[inline(always)]
    fn fq2_mul_nr_2p_2(a: Fq2, m: CircuitModulus) -> Fq2 {
        a.scale(pi::Q2X2_C0, m)
    }

    // For πₚ² frobeneus map
    // Multiply by Fp2::NONRESIDUE^(3(p^2-1)/6)
    #[inline(always)]
    fn fq2_mul_nr_2p_3(a: Fq2, m: CircuitModulus) -> Fq2 {
        a.scale(pi::Q2X3_C0, m)
    }

    // https://eprint.iacr.org/2022/1162 (Section 6.1)
    // computes acc = acc + q + acc and line evals for p
    // returns product of line evaluations to multiply with f
    // #[inline(always)]
    fn step_dbl_add(ref acc: PtG2, q: PtG2, m: CircuitModulus) -> (LineFn, LineFn) {
        let s = acc;
        // s + q
        let slope1 = s.chord_as_circuit(q, m);
        let x1 = s.x_on_slope(slope1, q.x, m);
        let line1 = line_fn(slope1, s, m);

        // we skip y1 calculation and sub slope1 directly in second slope calculation

        // s + (s + q)
        // λ2 = (y2-y1)/(x2-x1), subbing y2 = λ(x2-x1)+y1
        // λ2 = -λ1-2y1/(x3-x1)
        let slope2 = slope1.neg(m).sub((s.y.add(s.y, m)).div(x1.sub(s.x, m), m), m);
        acc = s.pt_on_slope_as_circuit(slope2, x1, m);
        let line2 = line_fn(slope2, s, m);

        // line functions
        (line1, line2)
    }

    // https://eprint.iacr.org/2022/1162 (Section 6.1)
    // computes acc = 2 * acc and line eval for p
    // returns line evaluation to multiply with f
    // #[inline(always)]
    fn step_double(ref acc: PtG2, m: CircuitModulus) -> LineFn {
        let s = acc;
        // λ = 3x²/2y
        let slope = s.tangent_as_circuit(m);
        // p = (λ²-2x, λ(x-xr)-y)
        acc = s.pt_on_slope_as_circuit(slope, acc.x, m);
        line_fn(slope, s, m)
    }
    // https://eprint.iacr.org/2022/1162 (Section 6.1)
    // computes acc = acc + q and line eval for p
    // returns line evaluation to multiply with f
    // #[inline(always)]
    fn step_add(ref acc: PtG2, q: PtG2, m: CircuitModulus) -> LineFn {
        let s = acc;
        // λ = (yS−yQ)/(xS−xQ)
        let slope = s.chord_as_circuit(q, m);
        // p = (λ²-2x, λ(x-xr)-y)
        acc = s.pt_on_slope_as_circuit(slope, q.x, m);
        line_fn(slope, s, m)
    }

    // Realm of pairings, Algorithm 1, lines 8, 9, 10
    // https://eprint.iacr.org/2013/722.pdf
    // Code inspired by gnark
    // https://github.com/Consensys/gnark/blob/v0.9.1/std/algebra/emulated/sw_bn254/pairing.go#L529
    // #[inline(always)]
    fn correction_step(ref acc: PtG2, q: PtG2, m: CircuitModulus) -> (LineFn, LineFn) {
        // Line 9: Q1 ← πₚ(Q),Q2 ← πₚ²(Q)
        // πₚ(x,y) = (xp,yp)
        // Q1 = π(Q)
        let q1 = Affine {
            x: fq2_mul_nr_1p_2(q.x.conjugate(m), m), y: fq2_mul_nr_1p_3(q.y.conjugate(m), m),
        };

        // Q2 = -π²(Q)
        let q2 = Affine { x: fq2_mul_nr_2p_2(q.x, m), y: fq2_mul_nr_2p_3(q.y, m).neg(m), };

        // Line 10: if u < 0 then T ← −T, f ← fp6
        // skip line 10, ∵ x > 0

        // Line 11: d ← (gT,Q1)(P), T ← T + Q1, e ← (gT,−Q2)(P), T ← T − Q2

        // d ← (gT,Q1)(P), T ← T + Q1
        let d = step_add(ref acc, q1, m);

        // e ← (gT,−Q2)(P), T ← T − Q2
        // we can skip the T ← T − Q2 step coz we don't need the final point, just the line
        // function
        let slope = acc.chord_as_circuit(q2, m);
        let e = line_fn(slope, acc, m);

        // f ← f·(d·e) is left for the caller

        // return line functions
        (d, e)
    }
}

#[inline(always)]
fn line_fn_at_p(line: LineFn, p_pre: @PPre, m: CircuitModulus) -> F034 {
    F034 {
        c3: line.slope.scale(*p_pre.neg_x_over_y.c0, m),
        c4: line.c.scale(*p_pre.y_inv.c0, m),
    }
}

fn line_evaluation_at_p(slope: Fq2, p_pre: @PPre, s: PtG2, m: CircuitModulus) -> F034 {
    F034 {
        c3: slope.scale(*p_pre.neg_x_over_y.c0, m),
        c4: (slope.mul(s.x, m).sub(s.y, m)).scale(*p_pre.y_inv.c0, m),
    }
}

#[inline(always)]
fn step_dbl_add_to_f(ref acc: PtG2, ref f: Fq12, p_pre: @PPre, p: PtG1, q: PtG2, m: CircuitModulus) {
    let (l1, l2) = step_dbl_add(ref acc, p_pre, p, q, m);
    f = f.mul_01234(l1.mul_034_by_034(l2, m), m);
}

fn step_dbl_add(ref acc: PtG2, p_pre: @PPre, p: PtG1, q: PtG2, m: CircuitModulus) -> (F034, F034) {
    let (lf1, lf2) = line_fn::step_dbl_add(ref acc, q, m);
    (line_fn_at_p(lf1, p_pre, m), line_fn_at_p(lf2, p_pre, m))
}

#[inline(always)]
fn step_double_to_f(ref acc: PtG2, ref f: Fq12, p_pre: @PPre, p: PtG1, m: CircuitModulus) {
    f = f.mul_034(step_double(ref acc, p_pre, p, m), m);
}

#[inline(always)]
fn step_double(ref acc: PtG2, p_pre: @PPre, p: PtG1, m: CircuitModulus) -> F034 {
    let lf = line_fn::step_double(ref acc, m);
    line_fn_at_p(lf, p_pre, m)
}

#[inline(always)]
fn step_add(ref acc: PtG2, p_pre: @PPre, p: PtG1, q: PtG2, m: CircuitModulus) -> F034 {
    let lf = line_fn::step_add(ref acc, q, m);
    line_fn_at_p(lf, p_pre, m)
}

#[inline(always)]
fn correction_step_to_f(
    ref acc: PtG2, ref f: Fq12, p_pre: @PPre, p: PtG1, q: PtG2, m: CircuitModulus
) {
    // Realm of pairings, Algorithm 1, lines 10 mul into f
    // f ← f·(d·e)
    let (l1, l2) = correction_step(ref acc, p_pre, p, q, m);
    f = f.mul_01234(l1.mul_034_by_034(l2, m), m);
}

#[inline(always)]
fn correction_step(ref acc: PtG2, p_pre: @PPre, p: PtG1, q: PtG2, m: CircuitModulus) -> (F034, F034) {
    let (lf1, lf2) = line_fn::correction_step(ref acc, q, m);
    (line_fn_at_p(lf1, p_pre, m), line_fn_at_p(lf2, p_pre, m))
}
