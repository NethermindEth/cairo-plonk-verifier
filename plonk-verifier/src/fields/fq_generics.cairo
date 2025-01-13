use core::circuit::CircuitModulus;

use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::fields::{Fq, Fq2, Fq6, Fq12};
use plonk_verifier::traits::{FieldEqs, FieldOps};

impl TFqPartialEq<TFq, +FieldEqs<TFq>> of PartialEq<TFq> {
    // #[inline(always)]
    fn eq(lhs: @TFq, rhs: @TFq) -> bool {
        FieldEqs::eq(lhs, rhs)
    }

    // #[inline(always)]
    fn ne(lhs: @TFq, rhs: @TFq) -> bool {
        !FieldEqs::eq(lhs, rhs)
    }
}

