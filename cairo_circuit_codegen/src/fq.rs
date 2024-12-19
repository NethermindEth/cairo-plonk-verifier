use std::ops::{Add, Sub, Mul, Neg};
use crate::circuit::*;
use crate::FieldOps;

#[derive(Debug, Clone)]
pub struct Fq {
    c0: Circuit,
    inp: Option<usize>,
}

impl Fq {
    pub fn new_input(idx: usize) -> Self {
        Self {
            c0: Circuit::circuit_input(idx), 
            inp: Some(idx)
        } 
    }
}

impl FieldOps for Fq {
    fn add(lhs: &Self, rhs: &Self) -> Self {
        Self {c0: Circuit::circuit_add(&lhs.c0, &rhs.c0), inp: None}
    }

    fn sub(lhs: &Self, rhs: &Self) -> Self {
        Self {c0: Circuit::circuit_sub(&lhs.c0, &rhs.c0), inp: None}
    }

    fn mul(lhs: &Self, rhs: &Self) -> Self {
        Self {c0: Circuit::circuit_mul(&lhs.c0, &rhs.c0), inp: None}
    }

    fn div(lhs: &Self, rhs: &Self) -> Self {
        Self {c0: Circuit::circuit_mul(&lhs.c0, &Circuit::circuit_inv(&rhs.c0)), inp: None}
    }

    fn sqr(lhs: &Self) -> Self {
        Self {c0: Circuit::circuit_mul(&lhs.c0, &lhs.c0), inp: None}
    }

    fn neg(lhs: &Self) -> Self {
        let tmp = Self::new_input(0); // Guaranteed because valid circuits have atleast 1 input
        Self {c0: Circuit::circuit_sub(&Circuit::circuit_sub(&tmp.c0, &tmp.c0), &lhs.c0), inp: None}
    }

    fn inv(lhs: &Self) -> Self {
        Self {c0: Circuit::circuit_inv(&lhs.c0), inp: None}
    }
}

impl Add for Fq {
    
}