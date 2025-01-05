// use plonk_verifier::curve::{add, sub, mul, div, neg};
use plonk_verifier::traits::{FieldOps, FieldEqs};
use plonk_verifier::fields::{Fq, Fq2, Fq6, Fq12};
use core::circuit::CircuitModulus;
use plonk_verifier::curve::constants::FIELD_U384;

impl TFqPartialEq<TFq, +FieldEqs<TFq>> of PartialEq<TFq> {
    #[inline(always)]
    fn eq(lhs: @TFq, rhs: @TFq) -> bool {
        FieldEqs::eq(lhs, rhs)
    }

    #[inline(always)]
    fn ne(lhs: @TFq, rhs: @TFq) -> bool {
        !FieldEqs::eq(lhs, rhs)
    }
}

