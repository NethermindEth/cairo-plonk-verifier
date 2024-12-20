pub mod circuit;
mod utils;
mod fields; 

trait FieldOps {
    fn add(&self, rhs: &Self) -> Self;
    fn sub(&self, rhs: &Self) -> Self;
    fn mul(&self, rhs: &Self) -> Self;
    fn div(&self, rhs: &Self) -> Self;
    fn sqr(&self,) -> Self;
    fn neg(&self,) -> Self;
    fn inv(&self,) -> Self;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_cairo_code() {

    }
}
