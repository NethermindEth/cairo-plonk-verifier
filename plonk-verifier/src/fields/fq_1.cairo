use core::num::traits::Zero;
use core::traits::TryInto;
use core::circuit::conversions::from_u256;
use debug::PrintTrait;

use integer::u512;
use core::circuit::{
    CircuitElement, CircuitInput, circuit_add, circuit_sub, circuit_mul, circuit_inverse,
    EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs,
    EvalCircuitResult,
};
use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::circuit_mod::{
    add_c, sub_c, neg_c, div_c, inv_c, mul_c, sqr_c, scl_c, one_384, zero_384
};
use plonk_verifier::curve::{FIELD, get_field_nz}; //, add, sub_field, mul, scl, sqr, div, neg, inv};
// use plonk_verifier::curve::{
//     add_u, sub_u, mul_u, sqr_u, scl_u, u512_reduce, u512_add_u256, u512_sub_u256
// };
use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
use plonk_verifier::traits::{FieldUtils, FieldOps, FieldShortcuts, FieldMulShortcuts};


#[derive(Copy, Drop, Debug)]
struct Fq {
    c0: u384
}

#[inline(always)]
fn fq(c0: u384) -> Fq {
    Fq { c0 }
}

impl FqShort of FieldShortcuts<Fq> {
    #[inline(always)]
    fn u_add(self: Fq, rhs: Fq) -> Fq {
        Fq { c0: add_c(self.c0, rhs.c0) }
    }

    #[inline(always)]
    fn u_sub(self: Fq, rhs: Fq) -> Fq {
        Fq { c0: sub_c(self.c0, rhs.c0), }
    }
}

impl FqMulShort of FieldMulShortcuts<Fq, u384> {
    #[inline(always)]
    fn u_mul(self: Fq, rhs: Fq) -> u384 {
        core::internal::revoke_ap_tracking();
        mul_c(self.c0, rhs.c0)
    }

    #[inline(always)]
    fn u_sqr(self: Fq) -> u384 {
        sqr_c(self.c0)
    }
}

impl FqUtils of FieldUtils<Fq, u128> {
    #[inline(always)]
    fn one() -> Fq {
        fq(one_384)
    }

    #[inline(always)]
    fn zero() -> Fq {
        fq(zero_384)
    }

    #[inline(always)]
    fn scale(self: Fq, by: u128) -> Fq {
        Fq { c0: scl_c(self.c0, by) }
    }


    #[inline(always)]
    fn mul_by_nonresidue(self: Fq,) -> Fq {
        if self.c0.is_zero() {
            self
        } else {
            -self
        }
    }

    #[inline(always)]
    fn conjugate(self: Fq) -> Fq {
        assert(false, 'no_impl: fq conjugate');
        FieldUtils::zero()
    }

    #[inline(always)]
    fn frobenius_map(self: Fq, power: usize) -> Fq {
        assert(false, 'no_impl: fq frobenius_map');
        FieldUtils::zero()
    }
}

impl FqOps of FieldOps<Fq> {
    #[inline(always)]
    fn add(self: Fq, rhs: Fq) -> Fq {
        fq(add_c(self.c0, rhs.c0))
    }

    #[inline(always)]
    fn sub(self: Fq, rhs: Fq) -> Fq {
        fq(sub_c(self.c0, rhs.c0))
    }

    #[inline(always)]
    fn mul(self: Fq, rhs: Fq) -> Fq {
        let a = CircuitElement::<CircuitInput<0>> {};
        let b = CircuitElement::<CircuitInput<1>> {};
        let mul = circuit_mul(a, b);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let a = self.c0;
        let b = rhs.c0;

        let outputs = match (mul,).new_inputs().next(a).next(b).done().eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let fq_c0 = Fq { c0: outputs.get_output(mul).try_into().unwrap() };
        fq_c0
    }

    #[inline(always)]
    fn div(self: Fq, rhs: Fq) -> Fq {
        fq(div_c(self.c0, rhs.c0))
    }

    #[inline(always)]
    fn neg(self: Fq) -> Fq {
        fq(neg_c(self.c0))
    }

    #[inline(always)]
    fn eq(lhs: @Fq, rhs: @Fq) -> bool {
        *lhs.c0 == *rhs.c0
    }

    #[inline(always)]
    fn sqr(self: Fq) -> Fq {
        let a0 = CircuitElement::<CircuitInput<0>> {};
        let sqr = circuit_mul(a0, a0);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let a = self.c0;

        let outputs = match (sqr,).new_inputs().next(a).done().eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        Fq { c0: outputs.get_output(sqr) }
    }

    #[inline(always)]
    fn inv(self: Fq, field_nz: NonZero<u256>) -> Fq {
        fq(inv_c(self.c0))
    }
}

impl FqIntoU256 of Into<Fq, u384> {
    #[inline(always)]
    fn into(self: Fq) -> u384 {
        self.c0
    }
}
impl U256IntoFq of Into<u384, Fq> {
    #[inline(always)]
    fn into(self: u384) -> Fq {
        fq(self)
    }
}
impl Felt252IntoFq of Into<felt252, Fq> {
    #[inline(always)]
    fn into(self: felt252) -> Fq {
        fq(self.into())
    }
}
