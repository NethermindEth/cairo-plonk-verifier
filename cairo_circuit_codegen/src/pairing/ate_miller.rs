use crate::fields::{affine::Affine, fq::Fq, fq12::Fq12, fq2::Fq2};

use super::MillerPrecompute;

pub fn ate_miller_loop(p: Affine<Fq>, q: Affine<Fq2>) -> Fq12 {
    let (precompute, mut q_acc) = MillerPrecompute::precompute(p, q);

}

pub fn ate_miller_loop_steps(precompute: Precompute, q_acc: &mut Affine<Fq2>) -> Fq12 {

}

mod miller_loop_circuit {

}