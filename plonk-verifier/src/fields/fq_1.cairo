use core::circuit::{
    AddInputResultTrait, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
    CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, circuit_add, circuit_inverse,
    circuit_mul, circuit_sub, u384,
};
use core::num::traits::Zero;

use plonk_verifier::circuits::fq_circuits::{
    add_c, div_c, inv_c, mul_c, neg_c, ONE, scl_c, sqr_c, sub_c, ZERO,
};
use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::traits::{FieldEqs, FieldOps, FieldUtils};

#[derive(Copy, Drop, Debug)]
struct Fq {
    c0: u384
}

// #[inline(always)]
fn fq(c0: u384) -> Fq {
    Fq { c0 }
}

impl FqUtils of FieldUtils<Fq, u128, CircuitModulus> {
    // #[inline(always)]
    fn one() -> Fq {
        fq(ONE)
    }

    // #[inline(always)]
    fn zero() -> Fq {
        fq(ZERO)
    }

    // #[inline(always)]
    fn scale(self: Fq, by: u128, m: CircuitModulus) -> Fq {
        Fq { c0: scl_c(self.c0, by, m) }
    }


    // #[inline(always)]
    fn mul_by_nonresidue(self: Fq, m: CircuitModulus) -> Fq {
        if self.c0.is_zero() {
            self
        } else {
            self.neg(m)
        }
    }

    // #[inline(always)]
    fn conjugate(self: Fq, m: CircuitModulus) -> Fq {
        assert(false, 'no_impl: fq conjugate');
        FieldUtils::zero()
    }
}

impl FqOps of FieldOps<Fq, CircuitModulus> {
    // #[inline(always)]
    fn add(self: Fq, rhs: Fq, m: CircuitModulus) -> Fq {
        fq(add_c(self.c0, rhs.c0, m))
    }

    // #[inline(always)]
    fn sub(self: Fq, rhs: Fq, m: CircuitModulus) -> Fq {
        fq(sub_c(self.c0, rhs.c0, m))
    }

    // #[inline(always)]
    fn mul(self: Fq, rhs: Fq, m: CircuitModulus) -> Fq {
        fq(mul_c(self.c0, rhs.c0, m))

    }

    // #[inline(always)]
    fn div(self: Fq, rhs: Fq, m: CircuitModulus) -> Fq {
        fq(div_c(self.c0, rhs.c0, m))
    }

    // #[inline(always)]
    fn neg(self: Fq, m: CircuitModulus) -> Fq {
        fq(neg_c(self.c0, m))
    }


    // #[inline(always)]
    fn sqr(self: Fq, m: CircuitModulus) -> Fq {
        fq(sqr_c(self.c0, m))
    }

    // #[inline(always)]
    fn inv(self: Fq, m: CircuitModulus) -> Fq {
        fq(inv_c(self.c0, m))
    }
}

impl FqEqs of FieldEqs<Fq> {
    // #[inline(always)]
    fn eq(lhs: @Fq, rhs: @Fq) -> bool {
        *lhs.c0 == *rhs.c0
    }
}

impl FqIntoU256 of Into<Fq, u384> {
    // #[inline(always)]
    fn into(self: Fq) -> u384 {
        self.c0
    }
}

impl U256IntoFq of Into<u384, Fq> {
    // #[inline(always)]
    fn into(self: u384) -> Fq {
        fq(self)
    }
}

impl Felt252IntoFq of Into<felt252, Fq> {
    // #[inline(always)]
    fn into(self: felt252) -> Fq {
        fq(self.into())
    }
}
