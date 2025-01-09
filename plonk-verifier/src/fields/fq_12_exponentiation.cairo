use core::array::ArrayTrait;
use core::circuit::{
    AddInputResultTrait, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
    CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, circuit_add, circuit_inverse,
    circuit_mul, circuit_sub, u384,
};
use core::traits::TryInto;

use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::fields::{
    fq, fq12, Fq, Fq2, Fq6, Fq12, Fq12Frobenius, Fq12Squaring, Fq12SquaringCircuit, FieldOps,
    FieldUtils,
};

// Computes FQ12 exponentiated by -t = -4965661367192848881 = 0x44e992b44a6909f1
// #[inline(always)]
fn addchain_exp_by_neg_t(x: Fq12, m: CircuitModulus) -> Fq12 {
    // internal::revoke_ap_tracking();
    // Inversion computation is derived from the addition chain:
    //
    //      _10     = 2*1
    //      _100    = 2*_10
    //      _1000   = 2*_100
    //      _10000  = 2*_1000
    //      _10001  = 1 + _10000
    //      _10011  = _10 + _10001
    //      _10100  = 1 + _10011
    //      _11001  = _1000 + _10001
    //      _100010 = 2*_10001
    //      _100111 = _10011 + _10100
    //      _101001 = _10 + _100111
    //      i27     = (_100010 << 6 + _100 + _11001) << 7 + _11001
    //      i44     = (i27 << 8 + _101001 + _10) << 6 + _10001
    //      i70     = ((i44 << 8 + _101001) << 6 + _101001) << 10
    //      return    (_100111 + i70) << 6 + _101001 + _1000
    //
    // Operations: 62 squares 17 multiplies
    //
    // Generated by github.com/mmcloughlin/addchain v0.4.0.

    let t3 = x.cyclotomic_sqr_circuit(m); // Step 1: t3 = x^0x2
    let t5 = t3.cyclotomic_sqr_circuit(m); // Step 2: t5 = x^0x4
    let z = t5.cyclotomic_sqr_circuit(m); // Step 3: z = x^0x8
    let t0 = z.cyclotomic_sqr_circuit(m); // Step 4: t0 = x^0x10
    let t2 = x.mul(t0, m); // Step 5: t2 = x^0x11
    let t0 = t3.mul(t2, m); // Step 6: t0 = x^0x13
    let t1 = x.mul(t0, m); // Step 7: t1 = x^0x14
    let t4 = z.mul(t2, m); // Step 8: t4 = x^0x19
    let t6 = t2.cyclotomic_sqr_circuit(m); // Step 9: t6 = x^0x22
    let t1 = t0.mul(t1, m); // Step 10: t1 = x^0x27
    let t0 = t3.mul(t1, m); // Step 11: t0 = x^0x29
    let t6 = t6.sqr_n_times(6, m); // Step 17: t6 = x^0x880
    let t5 = t5.mul(t6, m); // Step 18: t5 = x^0x884
    let t5 = t4.mul(t5, m); // Step 19: t5 = x^0x89d
    let t5 = t5.sqr_n_times(7, m); // Step 26: t5 = x^0x44e80
    let t4 = t4.mul(t5, m); // Step 27: t4 = x^0x44e99
    let t4 = t4.sqr_n_times(8, m); // Step 35: t4 = x^0x44e9900
    let t4 = t0.mul(t4, m); // Step 36: t4 = x^0x44e9929
    let t3 = t3.mul(t4, m); // Step 37: t3 = x^0x44e992b
    let t3 = t3.sqr_n_times(6, m); // Step 43: t3 = x^0x113a64ac0
    let t2 = t2.mul(t3, m); // Step 44: t2 = x^0x113a64ad1
    let t2 = t2.sqr_n_times(8, m); // Step 52: t2 = x^0x113a64ad100
    let t2 = t0.mul(t2, m); // Step 53: t2 = x^0x113a64ad129
    let t2 = t2.sqr_n_times(6, m); // Step 59: t2 = x^0x44e992b44a40
    let t2 = t0.mul(t2, m); // Step 60: t2 = x^0x44e992b44a69
    let t2 = t2.sqr_n_times(10, m); // Step 70: t2 = x^0x113a64ad129a400
    let t1 = t1.mul(t2, m); // Step 71: t1 = x^0x113a64ad129a427
    let t1 = t1.sqr_n_times(6, m); // Step 77: t1 = x^0x44e992b44a6909c0
    let t0 = t0.mul(t1, m); // Step 78: t0 = x^0x44e992b44a6909e9
    let z = z.mul(t0, m); // Step 79: z = x^0x44e992b44a6909f1

    z.conjugate(m)
}

#[generate_trait]
impl Fq12Exponentiation of PairingExponentiationTrait {
    // #[inline(always)]
    fn exp_by_neg_t(self: Fq12, m: CircuitModulus) -> Fq12 {
        addchain_exp_by_neg_t(self, m)
    }

    // Software Implementation of the Optimal Ate Pairing
    // Page 9, 4.2 Final exponentiation

    // #[inline(always)]
    fn final_exponentiation_easy_part(self: Fq12, m: CircuitModulus) -> Fq12 {
        // f^(p^6-1) = conjugate(f) · f^(-1)
        // returns cyclotomic Fp12
        let self = self.conjugate(m).div(self, m);
        // Software Implementation of the Optimal Ate Pairing
        // Page 9, 4.2 Final exponentiation
        // Page 5 - 6, 3.2 Frobenius Operator
        // f^(p^2+1) = f^(p^2) * f = f.frob2() * f
        self.frob2(m).mul(self, m)
    }

    fn final_exponentiation(self: Fq12, m: CircuitModulus) -> Fq12 {
        self.final_exponentiation_easy_part(m).final_exponentiation_hard_part(m)
    }

    // p^4 - p^2 + 1
    // This seems to be the most efficient counting operations performed
    // https://github.com/paritytech/bn/blob/master/src/fields/fq12.rs#L75
    // #[inline(always)]
    fn final_exponentiation_hard_part(self: Fq12, m: CircuitModulus) -> Fq12 {
        // internal::revoke_ap_tracking();
        let a = self.exp_by_neg_t(m);
        let b = a.cyclotomic_sqr_circuit(m);
        let c = b.cyclotomic_sqr_circuit(m);
        let d = c.mul(b, m);

        let e = d.exp_by_neg_t(m);
        let f = e.cyclotomic_sqr_circuit(m);
        let g = f.exp_by_neg_t(m);
        let h = d.conjugate(m);
        let i = g.conjugate(m);

        let j = i.mul(e, m);
        let k = j.mul(h, m);
        let l = k.mul(b, m);
        let m_tmp = k.mul(e, m);
        let n = self.mul(m_tmp, m);

        let o = l.frob1(m);
        let p = o.mul(n, m);

        let q = k.frob2(m);
        let r = q.mul(p, m);

        let s = self.conjugate(m);
        let t = s.mul(l, m);
        let u = t.frob3(m);
        let v = u.mul(r, m);

        v
    }
}