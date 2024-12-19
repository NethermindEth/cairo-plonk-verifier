use std::ops::{Add, Sub, Mul, Neg};
use crate::circuit::*;
use crate::FieldOps;
use crate::fq::Fq;


#[derive(Debug, Clone)]
pub struct Fq2 {
    c0: Fq,
    c1: Fq,
    inp: Option<[usize; 2]>, 
}

impl Fq2 {
    pub fn new_input(idx: [usize; 2]) -> Self {
        Self {
            c0: Fq::new_input(idx[0]), 
            c1: Fq::new_input(idx[1]), 
            inp: Some(idx)
        }
    }
}


impl FieldOps for Fq2 {
    fn add(lhs: &Self, rhs: &Self) -> Self {
        Self {}
    }

    fn sub(lhs: &Self, rhs: &Self) -> Self {
    }

    fn mul(lhs: &Self, rhs: &Self) -> Self {
    }

    fn div(lhs: &Self, rhs: &Self) -> Self {
    }

    fn sqr(lhs: &Self) -> Self {
    }

    fn neg(lhs: &Self) -> Self {
    }

    fn inv(lhs: &Self) -> Self {
    }
}

pub struct AffineFq2 {
    x: Fq2,
    y: Fq2,
    inp: Option<[usize; 4]>,
}

 