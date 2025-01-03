use plonk_verifier::curve::{FIELD, get_field_nz};
// use plonk_verifier::curve::{
//     U512Fq2Ops, u512, U512BnAdd, Tuple2Add, U512BnSub, Tuple2Sub, mul_by_xi, mul_by_xi_nz,
//     mul_by_xi_nz_as_circuit, u512_reduce, u512_add, u512_sub
// };
use plonk_verifier::curve::{mul_by_xi_nz_as_circuit};
// use plonk_verifier::fields::print::{FqPrintImpl, Fq2PrintImpl, Fq6PrintImpl, Fq12PrintImpl};
use plonk_verifier::fields::{Fq, Fq2, Fq2Ops, Fq2Utils, fq, fq2, Fq2Frobenius};
use plonk_verifier::traits::{FieldUtils, FieldOps};
use plonk_verifier::fields::frobenius::fp6 as frob;
use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::circuit_mod::{
    add_c, sub_c, neg_c, div_c, inv_c, mul_c, sqr_c, one_384, zero_384
};
use core::traits::TryInto;
use core::circuit::conversions::from_u256;
use core::circuit::{
    CircuitElement, CircuitInput, circuit_add, circuit_sub, circuit_mul, circuit_inverse,
    EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs,
    EvalCircuitResult,
};

use debug::PrintTrait;
use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use plonk_verifier::circuits::fq_6_circuits::{add_circuit, mul_circuit, sqr_circuit, neg_circuit, sub_circuit};
#[derive(Copy, Drop, Debug)]
struct Fq6 {
    c0: Fq2,
    c1: Fq2,
    c2: Fq2,
}

#[inline(always)]
fn fq6(c0: u384, c1: u384, c2: u384, c3: u384, c4: u384, c5: u384) -> Fq6 {
    Fq6 { c0: fq2(c0, c1), c1: fq2(c2, c3), c2: fq2(c4, c5) }
}

#[generate_trait]
impl Fq6Frobenius of Fq6FrobeniusTrait {
    #[inline(always)]
    fn frob0(self: Fq6) -> Fq6 {
        self
    }

    #[inline(always)]
    fn frob1(self: Fq6) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 {
            c0: c0.frob1(),
            c1: c1.frob1() * fq2(frob::Q_1_C0, frob::Q_1_C1),
            c2: c2.frob1() * fq2(frob::Q2_1_C0, frob::Q2_1_C1),
        }
    }

    #[inline(always)]
    fn frob2(self: Fq6) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 { c0: c0, c1: c1.scale(frob::Q_2_C0), c2: c2.scale(frob::Q2_2_C0) }
    }

    #[inline(always)]
    fn frob3(self: Fq6) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 {
            c0: c0.frob1(),
            c1: c1.frob1() * fq2(frob::Q_3_C0, frob::Q_3_C1),
            c2: c2.frob1() * fq2(frob::Q2_3_C0, frob::Q2_3_C1),
        }
    }

    #[inline(always)]
    fn frob4(self: Fq6) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 {
            c0: c0.frob0(),
            c1: c1.frob0() * fq2(frob::Q_4_C0, frob::Q_4_C1),
            c2: c2.frob0() * fq2(frob::Q2_4_C0, frob::Q2_4_C1),
        }
    }

    #[inline(always)]
    fn frob5(self: Fq6) -> Fq6 {
        let Fq6 { c0, c1, c2 } = self;
        Fq6 {
            c0: c0.frob1(),
            c1: c1.frob1() * fq2(frob::Q_5_C0, frob::Q_5_C1),
            c2: c2.frob1() * fq2(frob::Q2_5_C0, frob::Q2_5_C1),
        }
    }
}

impl Fq6Utils of FieldUtils<Fq6, Fq2> {
    #[inline(always)]
    fn one() -> Fq6 {
        fq6(one_384, zero_384, zero_384, zero_384, zero_384, zero_384)
    }

    #[inline(always)]
    fn zero() -> Fq6 {
        fq6(zero_384, zero_384, zero_384, zero_384, zero_384, zero_384)
    }

    #[inline(always)]
    fn scale(self: Fq6, by: Fq2) -> Fq6 {
        Fq6 { c0: self.c0 * by, c1: self.c1 * by, c2: self.c2 * by, }
    }

    #[inline(always)]
    fn conjugate(self: Fq6) -> Fq6 {
        assert(false, 'no_impl: fq6 conjugate');
        FieldUtils::zero()
    }

    #[inline(always)]
    fn mul_by_nonresidue(self: Fq6,) -> Fq6 {
        // https://github.com/paritytech/bn/blob/master/src/fields/fq6.rs#L110
        Fq6 { c0: self.c2.mul_by_nonresidue(), c1: self.c0, c2: self.c1, }
    }

    #[inline(always)]
    fn frobenius_map(self: Fq6, power: usize) -> Fq6 {
        let rem = power % 6;
        if rem == 0 {
            self.frob0()
        } else if rem == 1 {
            self.frob1()
        } else if rem == 2 {
            self.frob2()
        } else if rem == 3 {
            self.frob3()
        } else if rem == 4 {
            self.frob4()
        } else {
            self.frob5()
        }
    }
}

// impl Fq6Short of FieldShortcuts<Fq6> {
//     #[inline(always)]
//     fn u_add(self: Fq6, rhs: Fq6) -> Fq6 {
//         // Operation without modding can only be done like 4 times
//         Fq6 { //
//             c0: self.c0.u_add(rhs.c0), //
//             c1: self.c1.u_add(rhs.c1), //
//             c2: self.c2.u_add(rhs.c2), //
//         }
//     }
//     #[inline(always)]
//     fn u_sub(self: Fq6, rhs: Fq6) -> Fq6 {
//         // Operation without modding can only be done like 4 times
//         Fq6 { //
//             c0: self.c0.u_sub(rhs.c0), //
//             c1: self.c1.u_sub(rhs.c1), //
//             c2: self.c2.u_sub(rhs.c2), //
//         }
//     }
// }

// type SixU512 = ((u512, u512), (u512, u512), (u512, u512),);

// fn u512_dud() -> u512 {
//     u512 { limb0: 1, limb1: 0, limb2: 0, limb3: 0, }
// }

impl Fq6Ops of FieldOps<Fq6> {
    #[inline(always)]
    fn add(self: Fq6, rhs: Fq6) -> Fq6 {
        Fq6 { c0: self.c0 + rhs.c0, c1: self.c1 + rhs.c1, c2: self.c2 + rhs.c2, }
    }

    #[inline(always)]
    fn sub(self: Fq6, rhs: Fq6) -> Fq6 {
        Fq6 { c0: self.c0 - rhs.c0, c1: self.c1 - rhs.c1, c2: self.c2 - rhs.c2, }
    }

    #[inline(always)]
    fn mul(self: Fq6, rhs: Fq6) -> Fq6 {
        //
        // let Fq6 { c0: a0, c1: a1, c2: a2 } = self;
        // let Fq6 { c0: b0, c1: b1, c2: b2 } = rhs;
        // let field_nz = get_field_nz();

        // // v0 = a0b0, v1 = a1b1, v2 = a2b2
        // let (V0, V1, V2,) = (a0.u_mul(b0), a1.u_mul(b1), a2.u_mul(b2),);

        // // c0 = v0 + ξ((a1 + a2)(b1 + b2) - v1 - v2)
        // let C0 = V0 + mul_by_xi_nz(a1.u_add(a2).u_mul(b1.u_add(b2)) - V1 - V2, field_nz);
        // // c1 =(a0 + a1)(b0 + b1) - v0 - v1 + ξv2
        // let C1 = a0.u_add(a1).u_mul(b0.u_add(b1)) - V0 - V1 + mul_by_xi_nz(V2, field_nz);
        // // c2 = (a0 + a2)(b0 + b2) - v0 + v1 - v2,
        // let C2 = a0.u_add(a2).u_mul(b0.u_add(b2)) - V0 + V1 - V2;

        // (C0, C1, C2)

        // let v0 = Fq2Ops::mul(self.c0, rhs.c0);
        // let v1 = Fq2Ops::mul(self.c1, rhs.c1);
        // let v2 = Fq2Ops::mul(self.c2, rhs.c2);

        // let a1_add_a2 = Fq2Ops::add(self.c1, self.c2);
        // let b1_add_b2 = Fq2Ops::add(rhs.c1, rhs.c2);
        // let t0 = Fq2Ops::mul(a1_add_a2, b1_add_b2);
        // let t0 = Fq2Ops::sub(t0, v1);
        // let t0 = Fq2Ops::sub(t0, v2);
        // let t0_scaled = mul_by_xi_nz_as_circuit(t0);
        // let c0 = Fq2Ops::add(v0, t0_scaled);

        // let a0_add_a1 = Fq2Ops::add(self.c0, self.c1);
        // let b0_add_b1 = Fq2Ops::add(rhs.c0, rhs.c1);
        // let t1 = Fq2Ops::mul(a0_add_a1, b0_add_b1);
        // let t1 = Fq2Ops::sub(t1, v0);
        // let t1 = Fq2Ops::sub(t1, v1);
        // let t1_scaled = mul_by_xi_nz_as_circuit(v2);
        // let c1 = Fq2Ops::add(t1, t1_scaled);

        // let a0_add_a2 = Fq2Ops::add(self.c0, self.c2);
        // let b0_add_b2 = Fq2Ops::add(rhs.c0, rhs.c2);
        // let t2 = Fq2Ops::mul(a0_add_a2, b0_add_b2);
        // let t2 = Fq2Ops::sub(t2, v0);
        // let t2 = Fq2Ops::add(t2, v1);
        // let c2 = Fq2Ops::sub(t2, v2);

        // let res = Fq6 { c0: c0, c1: c1, c2: c2 };
        // res

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

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
            .done().eval(modulus) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        Fq6 { 
            c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
            c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
            c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } 
        }
    }
    #[inline(always)]
    fn div(self: Fq6, rhs: Fq6) -> Fq6 {
        self.mul(rhs.inv())
    }

    #[inline(always)]
    fn neg(self: Fq6) -> Fq6 {
        Fq6 { c0: -self.c0, c1: -self.c1, c2: -self.c2, }
    }

    #[inline(always)]
    fn eq(lhs: @Fq6, rhs: @Fq6) -> bool {
        lhs.c0 == rhs.c0 && lhs.c1 == rhs.c1 && lhs.c2 == rhs.c2
    }

    #[inline(always)]
    fn sqr(self: Fq6) -> Fq6 {
        // let s0 = Fq2Ops::sqr(self.c0);
        // let ab = Fq2Ops::mul(self.c0, self.c1);
        // let s1 = Fq2Ops::add(ab, ab);
        // let s2 = Fq2Ops::sqr(Fq2Ops::sub(Fq2Ops::add(self.c0, self.c2), self.c1));
        // let bc = Fq2Ops::mul(self.c1, self.c2);
        // let s3 = Fq2Ops::add(bc, bc);
        // let s4 = Fq2Ops::sqr(self.c2);
        // let c0 = Fq2Ops::add(s0, Fq2Utils::mul_by_nonresidue(s3));
        // let c1 = Fq2Ops::add(s1, Fq2Utils::mul_by_nonresidue(s4));
        // let c2 = Fq2Ops::sub(Fq2Ops::add(Fq2Ops::add(s1, s2), s3), Fq2Ops::add(s0, s4));
        // let res = Fq6 { c0: c0, c1: c1, c2: c2 };
        // res

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let (c0, c1, c2, c3, c4, c5) = sqr_circuit(); 

        let outputs = match (c0, c1, c2, c3, c4, c5).new_inputs()
            .next(self.c0.c0.c0)
            .next(self.c0.c1.c0)
            .next(self.c1.c0.c0)
            .next(self.c1.c1.c0)
            .next(self.c2.c0.c0)
            .next(self.c2.c1.c0)
            .done().eval(modulus) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        Fq6 { 
            c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
            c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
            c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } 
        }
    }

    #[inline(always)]
    fn inv(self: Fq6) -> Fq6 {
        core::internal::revoke_ap_tracking();
        // let field_nz = FIELD.try_into().unwrap();
        // let Fq6 { c0, c1, c2 } = self;
        // let v0 = c0.u_sqr() - mul_by_xi_nz(c1.u_mul(c2), field_nz);
        // let v0 = v0.to_fq(field_nz);
        // let V1 = mul_by_xi_nz(c2.u_sqr(), field_nz) - c0.u_mul(c1);
        // let v1 = V1.to_fq(field_nz);
        // let V2 = c1.u_sqr() - c0.u_mul(c2);
        // let v2 = V2.to_fq(field_nz);

        // let t = (mul_by_xi_nz(c2.u_mul(v1) + c1.u_mul(v2), field_nz) + c0.u_mul(v0))
        //     .to_fq(field_nz)
        //     .inv(field_nz);

        // Fq6 { c0: t * v0, c1: t * v1, c2: t * v2, }
        let Fq6 { c0, c1, c2 } = self;
        let c1_mul_c2 = Fq2Ops::mul(c1, c2);
        let v0 = Fq2Ops::sqr(c0) - mul_by_xi_nz_as_circuit(c1_mul_c2);
        let c2_sqr = Fq2Ops::sqr(c2);
        let v1 = Fq2Ops::sub(mul_by_xi_nz_as_circuit(c2_sqr), Fq2Ops::mul(c0, c1));
        let v2 = Fq2Ops::sub(Fq2Ops::sqr(c1), Fq2Ops::mul(c0, c2));
        let c2_mul_v1 = Fq2Ops::mul(c2, v1);
        let c1_mul_v2 = Fq2Ops::mul(c1, v2);
        let c2_mul_v1_add_c1_mul_v2 = Fq2Ops::add(c2_mul_v1, c1_mul_v2);
        let t = mul_by_xi_nz_as_circuit(c2_mul_v1_add_c1_mul_v2) + Fq2Ops::mul(c0, v0);
        let t_inv = t.inv(); 
        let c0 = Fq2Ops::mul(v0, t_inv);
        let c1 = Fq2Ops::mul(v1, t_inv);
        let c2 = Fq2Ops::mul(v2, t_inv);
        Fq6 { c0: c0, c1: c1, c2: c2 }
    }
}

fn fq6_karatsuba_sqr(a: Fq6, rhs: Fq6) -> (Fq2, Fq2, Fq2) {
    core::internal::revoke_ap_tracking();
    let Fq6 { c0: a0, c1: a1, c2: a2 } = a;
    // Karatsuba squaring
    // v0 = a0a0, v1 = a1a1, v2 = a2a2
    let (V0, V1, V2,) = (a0.sqr(), a1.sqr(), a2.sqr(),);

    // c0 = v0 + ξ((a1 + a2)(a1 + a2) - v1 - v2)
    let C0 = V0 + mul_by_xi_nz_as_circuit((a1 + a2).sqr() - V1 - V2);
    // c1 =(a0 + a1)(a0 + a1) - v0 - v1 + ξv2
    let C1 = (a0 + a1).sqr() - V0 - V1 + mul_by_xi_nz_as_circuit(V2);
    // c2 = (a0 + a2)(a0 + a2) - v0 + v1 - v2,
    let C2 = (a0 + a2).sqr() - V0 + V1 - V2;
    (C0, C1, C2)
}
