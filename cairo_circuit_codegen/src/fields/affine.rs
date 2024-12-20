use std::ops::Sub;

use crate::{fields::fq2::Fq2, FieldOps};

trait ECOperations<F> {
    fn x_on_slope(&self, slope: F, x2: F) -> F;
    fn y_on_slope(&self, slope: F, x: F) -> F;
    fn pt_on_slope(&self, slope: F, x2: F) -> &Self;
    fn chord(&self, rhs: &Self) -> F;
    fn add(&self, rhs: &Self) -> &Self;
    fn tangent(&self,) -> F;
    fn double(&self,) -> &Self;
    //fn multiply(&self, multiplier: u256) -> &Self; // Is there a way to guarantee multiply with circuits?
    fn neg(&self) -> &Self;
}
pub struct Affine<F: FieldOps> {
    x: F,
    y: F,
    inp: Option<[usize; 4]>,
}

impl<F: FieldOps> ECOperations<F> for Affine<F> 
    where F: Clone
{
    fn x_on_slope(&self, slope: F, x2: F) -> F {
        slope.sqr().sub(&self.x).sub(&x2)
    }

    fn y_on_slope(&self, slope: F, x: F) -> F {
        todo!()
    }

    fn pt_on_slope(&self, slope: F, x2: F) -> &Self {
        todo!()
    }

    fn chord(&self, rhs: &Self) -> F {
        todo!()
    }

    fn add(&self, rhs: &Self) -> &Self {
        todo!()
    }

    fn tangent(&self,) -> F {
        todo!()
    }

    fn double(&self,) -> &Self {
        todo!()
    }

    fn neg(&self) -> &Self {
        todo!()
    }
}

 