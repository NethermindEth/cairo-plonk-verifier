use crate::fields::{affine::Affine, fq::Fq, fq12::Fq12, fq2::Fq2};

mod line;
mod ate_miller;

pub trait MillerPrecompute {
    type Precompute; 
    fn precompute(g1: Affine<Fq>, g2: Affine<Fq2>) -> (Self::Precompute, Affine<Fq2>);
}

pub trait MillerSteps {
    fn sqr_target(&mut self, i: u32, acc: &mut Affine<Fq2>, f: &mut Fq12);
    fn miller_first_second(&mut self, i1: u32, i2: u32, acc: &mut Affine<Fq2>) -> Fq12;
    fn miller_bit_o(&mut self, i: u32, acc: &mut Affine<Fq2>, f: &mut Fq12);
    fn miller_bit_p(&mut self, i: u32, acc: &mut Affine<Fq2>, f: &mut Fq12);
    fn miller_bit_n(&mut self, i: u32, acc: &mut Affine<Fq2>, f: &mut Fq12);
    fn miller_last(&mut self, acc: &mut Affine<Fq2>, f: &mut Fq12, pi_idx: [usize; 6]);
}

pub fn single_ate_pairing(p: Affine<Fq>, q: Affine<Fq2>) -> Fq12 {
    todo!()
}

// Todo: Make input idx into an option for unused indices instead of defaulting to 0. 