use std::ops::{Add, Sub, Mul, Div, Neg};
use crate::circuit::Circuit;
use super::{FieldOps, fq::Fq};
#[derive(Debug, Clone)]
pub struct Fq2 {
    c0: Fq,
    c1: Fq,
    inp: Option<[usize; 2]>, 
}

impl Fq2 {
    pub fn new(c0: Fq, c1: Fq, inp: Option<[usize; 2]>) -> Self {
        Fq2 {c0, c1, inp }
    }

    pub fn new_input(idx: [usize; 2]) -> Self {
        Self {
            c0: Fq::new_input(idx[0]), 
            c1: Fq::new_input(idx[1]), 
            inp: Some(idx)
        }
    }

    pub fn c0(&self) -> &Fq {
        &self.c0
    }

    pub fn c1(&self) -> &Fq {
        &self.c1
    }
    
    // Todo: Optimize by passing in 9 as circuit input and remove scaling 9 function
    pub fn mul_by_xi(&self) -> Self {
        Self {c0: &self.c0().scl_9() - &self.c1(), c1: &self.c1().scl_9() + &self.c0(), inp: None }
    }
}


impl FieldOps for Fq2 {
    fn add(&self, rhs: &Self) -> Self {
        Self { c0: &self.c0 + &rhs.c0, c1: &self.c1 + &rhs.c1, inp: None }
    }

    fn sub(&self, rhs: &Self) -> Self {
        Self { c0: &self.c0 - &rhs.c0, c1: &self.c1 - &rhs.c1, inp: None }
    }

    fn mul(&self, rhs: &Self) -> Self {
        let (a0, a1) = (&self.c0, &self.c1);
        let (b0, b1) = (&rhs.c0, &rhs.c1);

        let t0 = &(a0 * b0);
        let t1 = &(a1 * b1);
        let t2 = &((a0 + a1) * (b0 + b1));
        let t3 = t2 -&(t0 + t1);
        let t4 = t0 - t1;

        Self { c0: t4, c1: t3, inp: None }
    }

    fn div(&self, rhs: &Self) -> Self {
        let rhs_inv = &rhs.inv();

        FieldOps::mul(self, rhs_inv) 
    }
    
    fn sqr(&self,) -> Self {
        let (a0, a1) = (&self.c0, &self.c1);

        let t0 = (a0 + a1) * (a0 - a1);
        let t1 = &(a0 + a0) * a1;

        Self { c0: t0, c1: t1, inp: None }

    }
    
    fn neg(&self,) -> Self {
        Self { c0: -&self.c0, c1: -&self.c1, inp: None }
    }

    fn inv(&self) -> Self {
        let t = &(&self.c0.sqr() + &self.c1.sqr()).inv();
        Self { c0: &self.c0 * t, c1: &self.c1 * &(-t), inp: None }
    }
    
}


impl Add for Fq2 {
    type Output = Fq2;

    fn add(self, rhs: Self) -> Self::Output {
        FieldOps::add(&self, &rhs)
    }
}

impl<'a, 'b> Add<&'b Fq2> for &'a Fq2 {
    type Output = Fq2;

    fn add(self, rhs: &'b Fq2) -> Fq2 {
        FieldOps::add(self, rhs)
    }
}

impl Sub for Fq2 {
    type Output = Fq2;

    fn sub(self, rhs: Self) -> Self::Output {
        FieldOps::sub(&self, &rhs)
    }
}

impl<'a, 'b> Sub<&'b Fq2> for &'a Fq2 {
    type Output = Fq2;

    fn sub(self, rhs: &'b Fq2) -> Fq2 {
        FieldOps::sub(self, rhs)
    }
}

impl Mul for Fq2 {
    type Output = Fq2;

    fn mul(self, rhs: Self) -> Self::Output {
        FieldOps::mul(&self, &rhs)
    }
}

impl<'a, 'b> Mul<&'b Fq2> for &'a Fq2 {
    type Output = Fq2;

    fn mul(self, rhs: &'b Fq2) -> Fq2 {
        FieldOps::mul(self, rhs)
    }
}

impl Div for Fq2 {
    type Output = Fq2;

    fn div(self, rhs: Self) -> Self::Output {
        FieldOps::div(&self, &rhs)
    }
}

impl<'a, 'b> Div<&'b Fq2> for &'a Fq2 {
    type Output = Fq2;

    fn div(self, rhs: &'b Fq2) -> Fq2 {
        FieldOps::div(self, rhs)
    }
}

impl Neg for Fq2 {
    type Output = Fq2;

    fn neg(self) -> Self::Output {
        FieldOps::neg(&self)
    }
}

impl<'a> Neg for &'a Fq2 {
    type Output = Fq2;

    fn neg(self) -> Fq2 {
        FieldOps::neg(self)
    }
}

#[cfg(test)]
mod test {
    use super::Fq2;
    use crate::circuit::CairoCodeBuilder;
    use crate::utils::utils::write_stdout; 
    #[test]
    pub fn test_fq2() {
        let in0 = &Fq2::new_input([0, 1]);
        let in1 = &Fq2::new_input([2, 3]); 
        
        let mut out = in0 * in1;
        let out_0 = out.c0().c0().format_circuit();
        let out_1 = out.c1().c0().format_circuit();
        let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
        builder.add_circuit("out_0", out_0);
        builder.add_circuit("out_1", out_1);

        let code = builder.build();
        write_stdout("out.cairo", code);
    }
}