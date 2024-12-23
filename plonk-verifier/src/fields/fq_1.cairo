use core::traits::TryInto;
use core::circuit::conversions::from_u256;
use plonk_verifier::curve::constants::FIELD_U384;
use core::circuit::{
    CircuitElement, CircuitInput, circuit_add, circuit_sub, circuit_mul, circuit_inverse,
    EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs,
    EvalCircuitResult,
};
use plonk_verifier::curve::{FIELD, get_field_nz, add, sub_field, mul, scl, sqr, div, neg, inv};
use plonk_verifier::curve::{
    add_u, sub_u, mul_u, sqr_u, scl_u, u512_reduce, u512_add_u256, u512_sub_u256
};
use integer::u512;
use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
use plonk_verifier::traits::{FieldUtils, FieldOps, FieldShortcuts, FieldMulShortcuts};
use debug::PrintTrait;

#[derive(Copy, Drop, Serde, Debug)]
struct Fq {
    c0: u256
}

#[inline(always)]
fn fq(c0: u256) -> Fq {
    Fq { c0 }
}

impl FqIntoU512Tuple of Into<Fq, u512> {
    #[inline(always)]
    fn into(self: Fq) -> u512 {
        u512 { limb0: self.c0.low, limb1: self.c0.high, limb2: 0, limb3: 0, }
    }
}

impl FqShort of FieldShortcuts<Fq> {
    #[inline(always)]
    fn u_add(self: Fq, rhs: Fq) -> Fq {
        // Operation without modding can only be done like 4 times
        Fq { c0: add_u(self.c0, rhs.c0), }
    }

    #[inline(always)]
    fn u_sub(self: Fq, rhs: Fq) -> Fq {
        Fq { c0: sub_u(self.c0, rhs.c0), }
    }

    #[inline(always)]
    fn fix_mod(self: Fq) -> Fq {
        let (_q, c0, _) = integer::u256_safe_divmod(self.c0, get_field_nz());
        Fq { c0 }
    }
}

impl FqMulShort of FieldMulShortcuts<Fq, u512> {
    #[inline(always)]
    fn u_mul(self: Fq, rhs: Fq) -> u512 {
        core::internal::revoke_ap_tracking();
        mul_u(self.c0, rhs.c0)
    }

    #[inline(always)]
    fn u512_add_fq(self: u512, rhs: Fq) -> u512 {
        u512_add_u256(self, rhs.c0)
    }

    #[inline(always)]
    fn u512_sub_fq(self: u512, rhs: Fq) -> u512 {
        u512_sub_u256(self, rhs.c0)
    }

    #[inline(always)]
    fn u_sqr(self: Fq) -> u512 {
        sqr_u(self.c0)
    }

    #[inline(always)]
    fn to_fq(self: u512, field_nz: NonZero<u256>) -> Fq {
        fq(u512_reduce(self, field_nz))
    }
}

impl FqUtils of FieldUtils<Fq, u128> {
    #[inline(always)]
    fn one() -> Fq {
        fq(1)
    }

    #[inline(always)]
    fn zero() -> Fq {
        fq(0)
    }

    #[inline(always)]
    fn scale(self: Fq, by: u128) -> Fq {
        Fq { c0: scl(self.c0, by) }
    }

    #[inline(always)]
    fn mul_by_nonresidue(self: Fq,) -> Fq {
        if self.c0 == 0 {
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
        fq(0)
    }
}

impl FqOps of FieldOps<Fq> {
    #[inline(always)]
    fn add(self: Fq, rhs: Fq) -> Fq {
        fq(add(self.c0, rhs.c0))
    }

    #[inline(always)]
    fn sub(self: Fq, rhs: Fq) -> Fq {
        fq(sub_field(self.c0, rhs.c0))
    }

    #[inline(always)]
    fn mul(self: Fq, rhs: Fq) -> Fq {
        let a = CircuitElement::<CircuitInput<0>> {};
        let b = CircuitElement::<CircuitInput<1>> {};
        let mul = circuit_mul(a, b);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let a = from_u256(self.c0);
        let b = from_u256(rhs.c0);

        let outputs = match (mul,).new_inputs().next(a).next(b).done().eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let fq_c0 = Fq { c0: outputs.get_output(mul).try_into().unwrap() };
        fq_c0
    }

    #[inline(always)]
    fn div(self: Fq, rhs: Fq) -> Fq {
        fq(div(self.c0, rhs.c0))
    }

    #[inline(always)]
    fn neg(self: Fq) -> Fq {
        fq(neg(self.c0))
    }

    #[inline(always)]
    fn eq(lhs: @Fq, rhs: @Fq) -> bool {
        *lhs.c0 == *rhs.c0
    }

    #[inline(always)]
    fn sqr(self: Fq) -> Fq {
        let a0 = CircuitElement::<CircuitInput<0>> {};
        let a1 = CircuitElement::<CircuitInput<1>> {};
        let sqr = circuit_mul(a0, a1);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let a = from_u256(self.c0);

        let outputs = match (sqr,).new_inputs().next(a).next(a).done().eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let fq_c0 = Fq { c0: outputs.get_output(sqr).try_into().unwrap() };
        fq_c0
    }

    #[inline(always)]
    fn inv(self: Fq, field_nz: NonZero<u256>) -> Fq {
        fq(inv(self.c0))
    }
}

impl FqIntoU256 of Into<Fq, u256> {
    #[inline(always)]
    fn into(self: Fq) -> u256 {
        self.c0
    }
}
impl U256IntoFq of Into<u256, Fq> {
    #[inline(always)]
    fn into(self: u256) -> Fq {
        fq(self)
    }
}
impl Felt252IntoFq of Into<felt252, Fq> {
    #[inline(always)]
    fn into(self: felt252) -> Fq {
        fq(self.into())
    }
}
