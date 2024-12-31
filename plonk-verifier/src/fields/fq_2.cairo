use core::traits::TryInto;
use core::circuit::{
    CircuitElement, CircuitInput, AddMod, circuit_add, circuit_sub, circuit_mul, circuit_inverse,
    EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs,
    EvalCircuitResult
};
use core::circuit::conversions::{from_u128, from_u256};
use debug::PrintTrait;

use plonk_verifier::circuit_mod::{
    add_c, sub_c, neg_c, div_c, inv_c, mul_c, sqr_c, one_384, zero_384
};
use plonk_verifier::traits::{FieldUtils, FieldOps, FieldShortcuts};
// use plonk_verifier::fast_mod::{u512_high_add};
// use plonk_verifier::curve::{u512, U512BnAdd, U512BnSub, u512_reduce, u512_add, u512_sub};
use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
use plonk_verifier::curve::{FIELD, get_field_nz, scale_9, circuit_scale_9};
use plonk_verifier::fields::{Fq, fq, FqOps};
// use plonk_verifier::fields::print::u512Display;
use plonk_verifier::curve::constants::FIELD_U384;
// use plonk_verifier::fields::utils::conversions::into_u512;

#[derive(Copy, Drop, Debug)]
struct Fq2 {
    c0: Fq,
    c1: Fq,
}

#[inline(always)]
fn fq2(c0: u384, c1: u384) -> Fq2 {
    Fq2 { c0: fq(c0), c1: fq(c1), }
}


#[generate_trait]
impl Fq2Frobenius of Fq2FrobeniusTrait {
    #[inline(always)]
    fn frob0(self: Fq2) -> Fq2 {
        self
    }

    #[inline(always)]
    fn frob1(self: Fq2) -> Fq2 {
        self.conjugate()
    }
}

impl Fq2Utils of FieldUtils<Fq2, u256> {
    #[inline(always)]
    fn one() -> Fq2 {
        fq2(one_384, zero_384)
    }

    #[inline(always)]
    fn zero() -> Fq2 {
        fq2(zero_384, zero_384)
    }

    #[inline(always)]
    fn scale(self: Fq2, by: u256) -> Fq2 {
        let a_c0 = CircuitElement::<CircuitInput<0>> {};
        let a_c1 = CircuitElement::<CircuitInput<1>> {};
        let scalar = CircuitElement::<CircuitInput<2>> {};

        let a_c0_scale = circuit_mul(a_c0, scalar);
        let a_c1_scale = circuit_mul(a_c1, scalar);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let a0 = self.c0.c0;
        let a1 = self.c1.c0;
        let scalar = from_u256(by);

        let outputs =
            match (a_c0_scale, a_c1_scale,)
                .new_inputs()
                .next(a0)
                .next(a1)
                .next(scalar)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let fq_c0 = Fq { c0: outputs.get_output(a_c0_scale).try_into().unwrap() };
        let fq_c1 = Fq { c0: outputs.get_output(a_c1_scale).try_into().unwrap() };

        let res = Fq2 { c0: fq_c0, c1: fq_c1 };
        res
    }

    #[inline(always)]
    fn conjugate(self: Fq2) -> Fq2 {
        Fq2 { c0: self.c0, c1: -self.c1, }
    }

    #[inline(always)]
    fn mul_by_nonresidue(self: Fq2,) -> Fq2 {
        let Fq2 { c0: a0, c1: a1 } = self;
        // fq2(9, 1)
        Fq2 { //  a0 * b0 + a1 * βb1,
            c0: circuit_scale_9(a0) - a1, //  
             // c1: a0 * b1 + a1 * b0,
            c1: a0 + circuit_scale_9(a1), //
        }
    }

    #[inline(always)]
    fn frobenius_map(self: Fq2, power: usize) -> Fq2 {
        if power % 2 == 0 {
            self
        } else {
            // Fq2 { c0: self.c0, c1: self.c1.mul_by_nonresidue(), }
            self.conjugate()
        }
    }
}

impl Fq2Short of FieldShortcuts<Fq2> {
    #[inline(always)]
    fn u_add(self: Fq2, rhs: Fq2) -> Fq2 {
        // Operation without modding can only be done like 4 times
        Fq2 { //
         c0: self.c0.u_add(rhs.c0), //
         c1: self.c1.u_add(rhs.c1), //
         }
    }

    #[inline(always)]
    fn u_sub(self: Fq2, rhs: Fq2) -> Fq2 {
        // Operation without modding can only be done like 4 times
        Fq2 { //
         c0: self.c0.u_sub(rhs.c0), //
         c1: self.c1.u_sub(rhs.c1), //
         }
    }
}

impl Fq2Ops of FieldOps<Fq2> {
    #[inline(always)]
    fn add(self: Fq2, rhs: Fq2) -> Fq2 {
        Fq2 { c0: self.c0 + rhs.c0, c1: self.c1 + rhs.c1, }
    }

    #[inline(always)]
    fn sub(self: Fq2, rhs: Fq2) -> Fq2 {
        Fq2 { c0: self.c0 - rhs.c0, c1: self.c1 - rhs.c1, }
    }

    #[inline(always)]
    fn mul(self: Fq2, rhs: Fq2) -> Fq2 {
        let a0 = CircuitElement::<CircuitInput<0>> {};
        let a1 = CircuitElement::<CircuitInput<1>> {};
        let b0 = CircuitElement::<CircuitInput<2>> {};
        let b1 = CircuitElement::<CircuitInput<3>> {};

        let t0 = circuit_mul(a0, b0);
        let t1 = circuit_mul(a1, b1);
        let a0_add_a1 = circuit_add(a0, a1);
        let b0_add_b1 = circuit_add(b0, b1);
        let t2 = circuit_mul(a0_add_a1, b0_add_b1);
        let t3 = circuit_add(t0, t1);
        let t3 = circuit_sub(t2, t3);
        let t4 = circuit_sub(t0, t1);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let a0 = self.c0.c0;
        let a1 = self.c1.c0;
        let b0 = rhs.c0.c0;
        let b1 = rhs.c1.c0;

        let outputs =
            match (t3, t4,).new_inputs().next(a0).next(a1).next(b0).next(b1).done().eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let fq_c0 = Fq { c0: outputs.get_output(t4).try_into().unwrap() };
        let fq_c1 = Fq { c0: outputs.get_output(t3).try_into().unwrap() };

        let fq_t = Fq2 { c0: fq_c0, c1: fq_c1 };
        fq_t
    }

    #[inline(always)]
    fn div(self: Fq2, rhs: Fq2) -> Fq2 {
        let inv_rhs = rhs.inv(get_field_nz());
        let res = Self::mul(self, inv_rhs);
        res
    }

    #[inline(always)]
    fn neg(self: Fq2) -> Fq2 {
        Fq2 { c0: -self.c0, c1: -self.c1, }
    }

    #[inline(always)]
    fn eq(lhs: @Fq2, rhs: @Fq2) -> bool {
        lhs.c0 == rhs.c0 && lhs.c1 == rhs.c1
    }

    #[inline(always)]
    fn sqr(self: Fq2) -> Fq2 {
        // // Aranha sqr_u + 2r
        let a0 = CircuitElement::<CircuitInput<0>> {};
        let a1 = CircuitElement::<CircuitInput<1>> {};
        let t0 = circuit_add(a0, a1);
        let t1 = circuit_sub(a0, a1);
        let T0 = circuit_mul(t0, t1);
        let t0 = circuit_add(a0, a0);
        let T1 = circuit_mul(t0, a1);
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
        let a0 = self.c0.c0;
        let a1 = self.c1.c0;

        let outputs = match (T0, T1,).new_inputs().next(a0).next(a1).done().eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let fq_t0 = Fq { c0: outputs.get_output(T0).try_into().unwrap() };
        let fq_t1 = Fq { c0: outputs.get_output(T1).try_into().unwrap() };

        let fq_t = Fq2 { c0: fq_t0, c1: fq_t1 };
        fq_t
    }


    #[inline(always)]
    fn inv(self: Fq2, field_nz: NonZero<u256>) -> Fq2 {
        let Fq2 { c0, c1 } = self;
        let t = FqOps::inv(c0.sqr() + c1.sqr(), field_nz);
        Fq2 { c0: c0.mul(t), c1: c1.mul(-t) }
    }
}

// Inverse unreduced Fq2
#[inline(always)]
fn ufq2_inv(self: Fq2, field_nz: NonZero<u256>) -> Fq2 {
    let Fq2 { c0, c1 } = self;
    let t = FqOps::inv((c0.sqr() + c1.sqr()), field_nz);

    Fq2 { c0: c0.mul(t), c1: c1.mul(-t) }
}

