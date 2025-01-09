use core::circuit::{
    AddInputResultTrait, AddModGate as A, CircuitElement, CircuitElement as CE, CircuitInput,
    CircuitInput as CI, CircuitInputs, CircuitModulus, CircuitOutputsTrait, EvalCircuitResult,
    EvalCircuitTrait, InverseGate as I, MulModGate as M, SubModGate as S, circuit_add,
    circuit_inverse, circuit_mul, circuit_sub, u384,
};
use core::circuit::conversions::from_u256;
use core::traits::TryInto;

use debug::PrintTrait;

use plonk_verifier::circuits::fq_circuits::{one_384, zero_384};
use plonk_verifier::circuits::fq_6_circuits::{
    add_circuit, mul_circuit, neg_circuit, sqr_circuit, sub_circuit,
};
use plonk_verifier::curve::{constants::FIELD_U384, mul_by_xi_nz_as_circuit};
use plonk_verifier::fields::{
    fq, fq2, Fq, Fq2, Fq2Frobenius, Fq2Ops, Fq2Utils,
};
use plonk_verifier::fields::frobenius::fp6 as frob;
use plonk_verifier::fields::fq_generics::TFqPartialEq;
use plonk_verifier::traits::{FieldEqs, FieldOps, FieldUtils};

#[derive(Copy, Drop, Debug)]
struct Fq6 {
    c0: Fq2,
    c1: Fq2,
    c2: Fq2,
}

// #[inline(always)]
fn fq6(c0: u384, c1: u384, c2: u384, c3: u384, c4: u384, c5: u384) -> Fq6 {
    Fq6 { c0: fq2(c0, c1), c1: fq2(c2, c3), c2: fq2(c4, c5) }
}

#[generate_trait]
impl Fq6Frobenius of Fq6FrobeniusTrait {
    // #[inline(always)]
    fn frob0(self: Fq6) -> Fq6 {
        self
    }

    // #[inline(always)]
    fn frob1(self: Fq6, m: CircuitModulus) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 {
            c0: c0.frob1(m),
            c1: c1.frob1(m).mul(fq2(frob::Q_1_C0, frob::Q_1_C1), m),
            c2: c2.frob1(m).mul(fq2(frob::Q2_1_C0, frob::Q2_1_C1), m),
        }
    }

    // #[inline(always)]
    fn frob2(self: Fq6, m: CircuitModulus) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 { c0: c0, c1: c1.scale(frob::Q_2_C0, m), c2: c2.scale(frob::Q2_2_C0, m) }
    }

    // #[inline(always)]
    fn frob3(self: Fq6, m: CircuitModulus) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 {
            c0: c0.frob1(m),
            c1: c1.frob1(m).mul(fq2(frob::Q_3_C0, frob::Q_3_C1), m),
            c2: c2.frob1(m).mul(fq2(frob::Q2_3_C0, frob::Q2_3_C1), m),
        }
    }

    // #[inline(always)]
    fn frob4(self: Fq6, m: CircuitModulus) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 {
            c0: c0.frob0(),
            c1: c1.frob0().mul(fq2(frob::Q_4_C0, frob::Q_4_C1), m),
            c2: c2.frob0().mul(fq2(frob::Q2_4_C0, frob::Q2_4_C1), m),
        }
    }

    // #[inline(always)]
    fn frob5(self: Fq6, m: CircuitModulus) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 {
            c0: c0.frob1(m),
            c1: c1.frob1(m).mul(fq2(frob::Q_5_C0, frob::Q_5_C1), m),
            c2: c2.frob1(m).mul(fq2(frob::Q2_5_C0, frob::Q2_5_C1), m),
        }
    }
}

impl Fq6Utils of FieldUtils<Fq6, Fq2, CircuitModulus> {
    // #[inline(always)]
    fn one() -> Fq6 {
        fq6(one_384, zero_384, zero_384, zero_384, zero_384, zero_384)
    }

    // #[inline(always)]
    fn zero() -> Fq6 {
        fq6(zero_384, zero_384, zero_384, zero_384, zero_384, zero_384)
    }

    // #[inline(always)]
    fn scale(self: Fq6, by: Fq2, m: CircuitModulus) -> Fq6 {
        Fq6 { c0: self.c0.mul(by, m), c1: self.c1.mul(by, m), c2: self.c2.mul(by, m) }
    }

    // #[inline(always)]
    fn conjugate(self: Fq6, m: CircuitModulus) -> Fq6 {
        assert(false, 'no_impl: fq6 conjugate');
        FieldUtils::zero()
    }

    // #[inline(always)]
    fn mul_by_nonresidue(self: Fq6, m: CircuitModulus) -> Fq6 {
        Fq6 { c0: self.c2.mul_by_nonresidue(m), c1: self.c0, c2: self.c1, }
    }
}

impl Fq6Ops of FieldOps<Fq6, CircuitModulus> {
    // #[inline(always)]
    fn add(self: Fq6, rhs: Fq6, m: CircuitModulus) -> Fq6 {
        Fq6 { c0: self.c0.add(rhs.c0, m), c1: self.c1.add(rhs.c1, m), c2: self.c2.add(rhs.c2, m), }
    }

    // #[inline(always)]
    fn sub(self: Fq6, rhs: Fq6, m: CircuitModulus) -> Fq6 {
        Fq6 { c0: self.c0.sub(rhs.c0, m), c1: self.c1.sub(rhs.c1, m), c2: self.c2.sub(rhs.c2, m), }
    }

    // #[inline(always)]
    fn mul(self: Fq6, rhs: Fq6, m: CircuitModulus) -> Fq6 {
        let (c0, c1, c2, c3, c4, c5) = mul_circuit(); 

        let outputs = match (c0, c1, c2, c3, c4, c5).new_inputs()
            .next(self.c0.c0.c0)
            .next(self.c0.c1.c0)
            .next(self.c1.c0.c0)
            .next(self.c1.c1.c0)
            .next(self.c2.c0.c0)
            .next(self.c2.c1.c0)
            .next(rhs.c0.c0.c0)
            .next(rhs.c0.c1.c0)
            .next(rhs.c1.c0.c0)
            .next(rhs.c1.c1.c0)
            .next(rhs.c2.c0.c0)
            .next(rhs.c2.c1.c0)
            .done().eval(m) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        Fq6 { 
            c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
            c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
            c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } 
        }
    }
    // #[inline(always)]
    fn div(self: Fq6, rhs: Fq6, m: CircuitModulus) -> Fq6 {
        self.mul(rhs.inv(m), m)
    }

    // #[inline(always)]
    fn neg(self: Fq6, m: CircuitModulus) -> Fq6 {
        Fq6 { c0: self.c0.neg(m), c1: self.c1.neg(m), c2: self.c2.neg(m) }
    }

    // #[inline(always)]
    fn sqr(self: Fq6, m: CircuitModulus) -> Fq6 {
        let (c0, c1, c2, c3, c4, c5) = sqr_circuit(); 

        let outputs = match (c0, c1, c2, c3, c4, c5).new_inputs()
            .next(self.c0.c0.c0)
            .next(self.c0.c1.c0)
            .next(self.c1.c0.c0)
            .next(self.c1.c1.c0)
            .next(self.c2.c0.c0)
            .next(self.c2.c1.c0)
            .done().eval(m) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        Fq6 { 
            c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
            c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
            c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } 
        }
    }

    // #[inline(always)]
    fn inv(self: Fq6, m: CircuitModulus) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        let c1_mul_c2 = Fq2Ops::mul(c1, c2, m);
        let v0 = Fq2Ops::sqr(c0, m).sub(mul_by_xi_nz_as_circuit(c1_mul_c2, m), m);
        let c2_sqr = Fq2Ops::sqr(c2, m);
        let v1 = Fq2Ops::sub(mul_by_xi_nz_as_circuit(c2_sqr, m), Fq2Ops::mul(c0, c1, m), m);
        let v2 = Fq2Ops::sub(Fq2Ops::sqr(c1, m), Fq2Ops::mul(c0, c2, m), m);
        let c2_mul_v1 = Fq2Ops::mul(c2, v1, m);
        let c1_mul_v2 = Fq2Ops::mul(c1, v2, m);
        let c2_mul_v1_add_c1_mul_v2 = Fq2Ops::add(c2_mul_v1, c1_mul_v2, m);
        let t = mul_by_xi_nz_as_circuit(c2_mul_v1_add_c1_mul_v2, m).add(Fq2Ops::mul(c0, v0, m), m);
        let t_inv = t.inv(m); 
        let c0 = Fq2Ops::mul(v0, t_inv, m);
        let c1 = Fq2Ops::mul(v1, t_inv, m);
        let c2 = Fq2Ops::mul(v2, t_inv, m);
        Fq6 { c0: c0, c1: c1, c2: c2 }
    }
}

// fn fq6_karatsuba_sqr(a: Fq6, rhs: Fq6, m: CircuitModulus) -> (Fq2, Fq2, Fq2) {
//     let Fq6 { c0: a0, c1: a1, c2: a2 } = a;
//     // Karatsuba squaring
//     // v0 = a0a0, v1 = a1a1, v2 = a2a2
//     let (V0, V1, V2,) = (a0.sqr(m), a1.sqr(m), a2.sqr(m),);

//     // c0 = v0 + ξ((a1 + a2)(a1 + a2) - v1 - v2)
//     let C0 = V0.add(mul_by_xi_nz_as_circuit(a1.add(a2, m), m).sqr(m).sub(V1, m).sub(V2, m), m);
//     // c1 =(a0 + a1)(a0 + a1) - v0 - v1 + ξv2
//     let C1 = (a0.add(a1, m)).sqr(m).sub(V0, m).sub(V1, m).add(mul_by_xi_nz_as_circuit(V2, m), m);
//     // c2 = (a0 + a2)(a0 + a2) - v0 + v1 - v2,
//     let C2 = (a0.add(a2, m)).sqr(m).sub(V0, m).add(V1, m).sub(V2, m);
//     (C0, C1, C2)
// }

impl FqEqs of FieldEqs<Fq6> {
    // #[inline(always)]
    fn eq(lhs: @Fq6, rhs: @Fq6) -> bool {
        lhs.c0 == rhs.c0 && lhs.c1 == rhs.c1 && lhs.c2 == rhs.c2
    }
}