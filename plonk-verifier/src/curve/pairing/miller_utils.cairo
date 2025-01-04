use core::debug::PrintTrait;
use core::circuit::u384;
use plonk_verifier::fields::{Fq12, Fq12Utils};
use plonk_verifier::curve::groups::{Affine, AffineG1, AffineG2};
use plonk_verifier::fields::{FieldUtils, FieldOps, fq, Fq, Fq2, Fq6};
use plonk_verifier::curve::constants::FIELD_U384;
use core::circuit::CircuitModulus;

trait LineEvaluationsTrait<P1, P2> {
    /// The sloped line function for doubling a point
    fn at_tangent(self: P1, p: P2) -> Fq12;
    /// The sloped line function for adding two points
    fn at_chord(self: P1, p1: P2, p2: P2) -> Fq12;
}

impl G2LineEvals of LineEvaluationsTrait<AffineG2, AffineG1> {
    /// The sloped line function for doubling a point
    #[inline(always)]
    fn at_tangent(self: AffineG2, p: AffineG1) -> Fq12 {
        let m = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
        // -3px^2
        let cx = fq(u384 { limb0: 3, limb1: 0, limb2: 0, limb3: 0 }).neg().mul(p.x.sqr());
        // 2p.y
        let cy = p.y.add(p.y, m);
        sparse_fq12(
            p.y.mul(p.y).sub(fq(u384 { limb0: 9, limb1: 0, limb2: 0, limb3: 0 })),
            self.x.scale((cx.c0).try_into().unwrap()),
            self.y.scale((cy.c0).try_into().unwrap())
        )
    }

    /// The sloped line function for adding two points
    #[inline(always)]
    fn at_chord(self: AffineG2, p1: AffineG1, p2: AffineG1) -> Fq12 {
        let cx = p2.y.sub(p1.y);
        let cy = p1.x.sub(p2.x);
        sparse_fq12(
            p1.y.mul(p2.x).sub(p2.y.mul(p1.x)),
            self.x.scale((cx.c0).try_into().unwrap()),
            self.y.scale((cy.c0).try_into().unwrap())
        )
    }
}

/// The tangent and cord functions output sparse Fp12 elements.
/// This map embeds the nonzero coefficients into an Fp12.
fn sparse_fq12(g000: Fq, g01: Fq2, g11: Fq2) -> Fq12 {
    Fq12 {
        c0: Fq6 { c0: Fq2 { c0: g000, c1: FieldUtils::zero(), }, c1: g01, c2: FieldUtils::zero(), },
        c1: Fq6 { c0: FieldUtils::zero(), c1: g11, c2: FieldUtils::zero(), }
    }
}
