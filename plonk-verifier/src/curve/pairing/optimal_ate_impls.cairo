use core::circuit::CircuitModulus;

use plonk_verifier::curve::groups::{
    Affine, AffineG1 as PtG1, AffineG2 as PtG2, ECGroup, ECOperationsCircuitFq2, g1, g2,
};
use plonk_verifier::curve::pairing::optimal_ate_utils::{
    PPrecompute, correction_step_to_f, p_precompute, step_dbl_add, step_dbl_add_to_f,
    step_double, step_double_to_f,
};
use plonk_verifier::fields::{
    Fq, Fq2, Fq6, Fq12, FqOps, Fq2Ops, Fq2Utils, Fq12Ops, Fq12Utils, Fq12Exponentiation,
    Fq12Sparse01234, Fq12Sparse034, FqSparse,
};
use plonk_verifier::fields::fq_sparse::FqSparseTrait;
use plonk_verifier::traits::{FieldUtils, MillerPrecompute, MillerSteps};

#[derive(Copy, Drop)]
struct PreCompute {
    p: PtG1,
    q: PtG2,
    neg_q: PtG2,
    ppc: PPrecompute,
    modulus: CircuitModulus,
}

impl SingleMillerPrecompute of MillerPrecompute<PtG1, PtG2, PreCompute, CircuitModulus> {
    fn precompute(self: (PtG1, PtG2), m: CircuitModulus) -> (PreCompute, PtG2) {
        let (p, q) = self;
        let ppc = p_precompute(p, m);
        // let precomp = PreCompute { ppc, neg_q: q.neg(), m, p, q, };
        let precomp = PreCompute {p, q, neg_q: q.neg(m), ppc, modulus: m };
        (precomp, q.clone(),)
    }
}

impl SingleMillerSteps of MillerSteps<PreCompute, PtG2, Fq12> {
    // #[inline(always)]
    fn sqr_target(self: @PreCompute, i: u32, ref acc: PtG2, ref f: Fq12) {
        f = f.sqr(*self.modulus);
    }

    fn miller_first_second(self: @PreCompute, i1: u32, i2: u32, ref acc: PtG2) -> Fq12 {
        let m = *self.modulus;
        // Handle O, N steps
        // step 0, run step double
        let l0 = step_double(ref acc, self.ppc, *self.p, m);
        // sqr with mul 034 by 034
        let f_01234 = l0.sqr_034(m);
        // step -1, the next negative one step
        let (l1, l2) = step_dbl_add(ref acc, self.ppc, *self.p, *self.neg_q, m);
        // let f = f_01234.mul_01234_034(l1, *self.field_nz);
        // f.mul_034(l2, *self.field_nz)
        f_01234.mul_01234_01234(l1.mul_034_by_034(l2, m), m)
    }

    // 0 bit
    fn miller_bit_o(self: @PreCompute, i: u32, ref acc: PtG2, ref f: Fq12) {
        step_double_to_f(ref acc, ref f, self.ppc, *self.p, *self.modulus);
    }

    // 1 bit
    fn miller_bit_p(self: @PreCompute, i: u32, ref acc: PtG2, ref f: Fq12) {
        step_dbl_add_to_f(ref acc, ref f, self.ppc, *self.p, *self.q, *self.modulus);
    }

    // -1 bit
    fn miller_bit_n(self: @PreCompute, i: u32, ref acc: PtG2, ref f: Fq12) {
        // use neg q
        step_dbl_add_to_f(ref acc, ref f, self.ppc, *self.p, *self.neg_q, *self.modulus);
    }

    // last step
    fn miller_last(self: @PreCompute, ref acc: PtG2, ref f: Fq12) {
        correction_step_to_f(ref acc, ref f, self.ppc, *self.p, *self.q, *self.modulus);
    }
}
