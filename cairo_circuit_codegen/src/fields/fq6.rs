use std::ops::{Add, Sub, Mul, Div, Neg};
use super::{fq::Fq, fq2::Fq2, FieldOps};
use super::sparse::Fq6Sparse01;

#[derive(Clone, Debug, Default)]
pub struct Fq6 {
    c0: Fq2,
    c1: Fq2,
    c2: Fq2,
    inp: Option<[usize; 6]>,
}

impl Fq6 {
    pub fn new(c0: Fq2, c1: Fq2, c2: Fq2, inp: Option<[usize; 6]>) -> Self {
        Self { c0, c1, c2, inp }
    }

    pub fn new_input(idx: [usize; 6]) -> Self {
        Self {
            c0: Fq2::new_input([idx[0], idx[1]]), 
            c1: Fq2::new_input([idx[2], idx[3]]), 
            c2: Fq2::new_input([idx[4], idx[5]]),
            inp: Some(idx)
        }
    }

    pub fn c0(&self) -> &Fq2 {
        &self.c0
    }

    pub fn c1(&self) -> &Fq2 {
        &self.c1
    }

    pub fn c2(&self) -> &Fq2 {
        &self.c2
    }

    pub fn mul_01(&self, rhs: &Fq6Sparse01) -> Fq6 {
        let (a0, a1, a2) = (self.c0(), self.c1(), self.c2());
        let (b0, b1) = (rhs.c0(), rhs.c1());

        let v0 = a0 * b0;
        let v1 = a1 * b1; 
        let c0 = &(&(&(a1 + a2) * b1) - &v1).mul_by_xi() + &v0;
        let c1 = &(&((a0 + a1) * (b0 + b1)) - &v0) - &v1;
        let c2 = (a2 * b0) + v1; 

        Self { c0, c1, c2, inp: None}
    }

    pub fn mul_by_v(&self) -> Self {
        Self { c0: self.c2().mul_by_xi(), c1: self.c0().clone(), c2: self.c1().clone(), inp: None } // todo: remove clone
    }
}

impl FieldOps for Fq6 {
    fn add(&self, rhs: &Self) -> Self {
        Self { c0: &self.c0 + &rhs.c0, c1: &self.c1 + &rhs.c1, c2: &self.c2 + &rhs.c2, inp: None }
    }

    fn sub(&self, rhs: &Self) -> Self {
        Self { c0: &self.c0 - &rhs.c0, c1: &self.c1 - &rhs.c1, c2: &self.c2 - &rhs.c2, inp: None }
    }

    // Todo: Clean code by using helper function for consecutive operations
    fn mul(&self, rhs: &Self) -> Self {
        let (a0, a1, a2) = (self.c0(), self.c1(), self.c2()); 
        let (b0, b1, b2) = (rhs.c0(), rhs.c1(), rhs.c2());
        
        let (v0, v1, v2) = &(a0 * b0, a1 * b1, a2 * b2);

        let c0 = v0 + &(&(&((a1 + a2) * (b1 + b2)) - v1) - v2).mul_by_xi();
        let c1 = &(&((a0 + a1) * (b0 + b1)) - v0) - v1 + v2.mul_by_xi();
        let c2 = &(&(&((a0 + a2) * (b0 + b2)) - v0) + v1) - v2;

        Self {c0, c1, c2, inp: None }
    }

    fn sqr(&self,) -> Self {
        let (c0, c1, c2) = (self.c0(), self.c1(), self.c2());

        let s0 = c0.sqr();
        let ab = c0 * c1;
        let s1 = &ab + &ab;
        let s2 = (&(c0 + c2) - c1).sqr();
        let bc = c1 * c2;
        let s3 = &bc + &bc;
        let s4 = c2.sqr();

        let c0 = &s0 + &s3.mul_by_xi();
        let c1 = &s1 + &s4.mul_by_xi();
        let c2 = s1 + s2 + s3 - s0 - s4;

        Self {c0, c1, c2, inp: None } 
    }

    fn neg(&self,) -> Self {
        Self { c0: -&self.c0, c1: -&self.c1, c2: -&self.c2, inp: None }
    }


    fn inv(&self,) -> Self {
        let (c0, c1, c2) = (self.c0(), self.c1(), self.c2());

        let v0 = c0.sqr() - (c1 * c2).mul_by_xi();
        let v1 = c2.sqr().mul_by_xi() - (c0 * c1); 
        let v2 = c1.sqr() - (c0 * c2);
        let t = (((c2 * &v1) + (c1 * &v2)).mul_by_xi() + (c0 * &v0)).inv();

        Self {c0: &v0 * &t, c1: &v1 * &t, c2: &v2 * &t, inp: None } 
    }
    
    fn div(&self, rhs: &Self) -> Self {
        FieldOps::mul(self, &rhs.inv())
    }
}


impl Add for Fq6 {
    type Output = Fq6;

    fn add(self, rhs: Self) -> Self::Output {
        FieldOps::add(&self, &rhs)
    }
}

impl<'a, 'b> Add<&'b Fq6> for &'a Fq6 {
    type Output = Fq6;

    fn add(self, rhs: &'b Fq6) -> Fq6 {
        FieldOps::add(self, rhs)
    }
}

impl Sub for Fq6 {
    type Output = Fq6;

    fn sub(self, rhs: Self) -> Self::Output {
        FieldOps::sub(&self, &rhs)
    }
}

impl<'a, 'b> Sub<&'b Fq6> for &'a Fq6 {
    type Output = Fq6;

    fn sub(self, rhs: &'b Fq6) -> Fq6 {
        FieldOps::sub(self, rhs)
    }
}

impl Mul for Fq6 {
    type Output = Fq6;

    fn mul(self, rhs: Self) -> Self::Output {
        FieldOps::mul(&self, &rhs)
    }
}

impl<'a, 'b> Mul<&'b Fq6> for &'a Fq6 {
    type Output = Fq6;

    fn mul(self, rhs: &'b Fq6) -> Fq6 {
        FieldOps::mul(self, rhs)
    }
}

impl Div for Fq6 {
    type Output = Fq6;

    fn div(self, rhs: Self) -> Self::Output {
        FieldOps::div(&self, &rhs)
    }
}

impl<'a, 'b> Div<&'b Fq6> for &'a Fq6 {
    type Output = Fq6;

    fn div(self, rhs: &'b Fq6) -> Fq6 {
        FieldOps::div(self, rhs)
    }
}

impl Neg for Fq6 {
    type Output = Fq6;

    fn neg(self) -> Self::Output {
        FieldOps::neg(&self)
    }
}

impl<'a> Neg for &'a Fq6 {
    type Output = Fq6;

    fn neg(self) -> Fq6 {
        FieldOps::neg(self)
    }
}
