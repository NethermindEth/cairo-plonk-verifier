use std::ops::{Add, Sub, Mul, Div, Neg};
use crate::circuit::circuit::Circuit;

use super::{FieldConstants, FieldOps};

#[derive(Clone, Debug, Default)]
pub struct Fq {
    c0: Circuit,
    inp: Option<usize>,
}

impl Fq {
    pub fn new(c0: Circuit, inp: Option<usize>) -> Self {
        Fq {c0, inp }
    }

    pub fn new_input(idx: usize) -> Self {
        Self {
            c0: Circuit::circuit_input(idx), 
            inp: Some(idx)
        } 
    }

    pub fn c0(&self) -> &Circuit {
        &self.c0
    }

    pub fn scl_9(&self) -> Self {
        let two = &(self + self);
        let four = &(two + two);
        let eight = &(four + four);
        eight + self
    }

    // A scale 9 function without any additions, instead passes 9 in as a circuit input 0
    // Note: In order to use this function, your circuit inputs must be offset by 1.
    pub fn scl_9_no_add(&self) -> Self {
        self * &Self::new_input(0)
    }
}

impl FieldOps for Fq {
    fn add(&self, rhs: &Self) -> Self {
        Self { c0: Circuit::circuit_add(&self.c0, &rhs.c0), inp: None }
    }

    fn sub(&self, rhs: &Self) -> Self {
        Self { c0: Circuit::circuit_sub(&self.c0, &rhs.c0), inp: None }
    }

    fn mul(&self, rhs: &Self) -> Self {
        Self { c0: Circuit::circuit_mul(&self.c0, &rhs.c0), inp: None }
    }

    fn div(&self, rhs: &Self) -> Self {
        Self { c0: Circuit::circuit_mul(&self.c0, &Circuit::circuit_inv(&rhs.c0)), inp: None }
    }

    fn sqr(&self) -> Self {
        Self { c0: Circuit::circuit_mul(&self.c0, &self.c0), inp: None }
    }

    fn neg(&self) -> Self {
        let tmp = Self::new_input(0); // Guaranteed because valid circuits have atleast 1 input
        Self { c0: Circuit::circuit_sub(&Circuit::circuit_sub(&tmp.c0, &tmp.c0), &self.c0), inp: None }
    }

    fn inv(&self) -> Self {
        Self { c0: Circuit::circuit_inv(&self.c0), inp: None }
    }
}

impl FieldConstants for Fq {
    // DANGEROUS, ASSUMES C0 IS NON-ZERO
    fn one() -> Self {
        let c0 = Self::new_input(0); 
        &c0 / &c0
    }

    fn zero() -> Self {
        let c0 = Self::new_input(0); 
        &c0 - &c0
    }
}

impl Add for Fq {
    type Output = Fq;

    fn add(self, rhs: Self) -> Self::Output {
        FieldOps::add(&self, &rhs)
    }
}

impl<'a, 'b> Add<&'b Fq> for &'a Fq {
    type Output = Fq;

    fn add(self, rhs: &'b Fq) -> Fq {
        FieldOps::add(self, rhs)
    }
}

impl Sub for Fq {
    type Output = Fq;

    fn sub(self, rhs: Self) -> Self::Output {
        FieldOps::sub(&self, &rhs)
    }
}

impl<'a, 'b> Sub<&'b Fq> for &'a Fq {
    type Output = Fq;

    fn sub(self, rhs: &'b Fq) -> Fq {
        FieldOps::sub(self, rhs)
    }
}

impl Mul for Fq {
    type Output = Fq;

    fn mul(self, rhs: Self) -> Self::Output {
        FieldOps::mul(&self, &rhs)
    }
}

impl<'a, 'b> Mul<&'b Fq> for &'a Fq {
    type Output = Fq;

    fn mul(self, rhs: &'b Fq) -> Fq {
        FieldOps::mul(self, rhs)
    }
}

impl Div for Fq {
    type Output = Fq;

    fn div(self, rhs: Self) -> Self::Output {
        FieldOps::div(&self, &rhs)
    }
}

impl<'a, 'b> Div<&'b Fq> for &'a Fq {
    type Output = Fq;

    fn div(self, rhs: &'b Fq) -> Fq {
        FieldOps::div(self, rhs)
    }
}

impl Neg for Fq {
    type Output = Fq;

    fn neg(self) -> Self::Output {
        FieldOps::neg(&self)
    }
}

impl<'a> Neg for &'a Fq {
    type Output = Fq;

    fn neg(self) -> Fq {
        FieldOps::neg(self)
    }
}

#[cfg(test)]
mod test {
    use crate::{circuit::builder::CairoCodeBuilder, utils::utils::write_stdout};
    use super::Fq; 

    #[test]
    pub fn test_fq() {
        let in0 = Fq::new_input(0);
        let in1 = Fq::new_input(1); 

        let out = (in0 + in1).c0().format_circuit();
        let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
        builder.assign_variable("out", out);
        
        let code = builder.build();
        write_stdout("out.cairo", code);
    }
}