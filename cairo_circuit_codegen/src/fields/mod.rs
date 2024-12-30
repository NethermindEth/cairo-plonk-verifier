pub(crate) mod fq;
pub(crate) mod fq2;
pub(crate) mod fq6;
pub(crate) mod fq12;
pub(crate) mod affine;
pub(crate) mod sparse;

pub trait FieldUtils {
    type FieldChild; 
    fn scale(&self, by: &Self::FieldChild) -> Self; 
}

pub trait FieldOps {
    fn add(&self, rhs: &Self) -> Self;
    fn sub(&self, rhs: &Self) -> Self;
    fn mul(&self, rhs: &Self) -> Self;
    fn div(&self, rhs: &Self) -> Self;
    fn sqr(&self,) -> Self;
    fn neg(&self,) -> Self;
    fn inv(&self,) -> Self;
}

pub trait FieldConstants {
    fn one() -> Self;
    fn zero() -> Self; 
}

pub trait ECOperations<F> {
    fn x_on_slope(&self, slope: &F, x2: &F) -> F;
    fn y_on_slope(&self, slope: &F, x: &F) -> F;
    fn pt_on_slope(&self, slope: &F, x2: &F) -> Self;
    fn chord(&self, rhs: &Self) -> F;
    fn add(&self, rhs: &Self) -> Self;
    fn tangent(&self) -> F;
    fn double(&self) -> Self;
    //fn multiply(&self, multiplier: u256) -> &Self; // Is there a way to guarantee multiply with circuits?
    fn neg(&self) -> Self;
}