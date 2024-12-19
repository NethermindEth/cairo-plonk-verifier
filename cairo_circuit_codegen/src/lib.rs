mod circuit;
mod fq;
mod fq2;

trait FieldOps {
    fn add(lhs: &Self, rhs: &Self) -> Self;
    fn sub(lhs: &Self, rhs: &Self) -> Self;
    fn mul(lhs: &Self, rhs: &Self) -> Self;
    fn div(lhs: &Self, rhs: &Self) -> Self;
    fn sqr(lhs: &Self) -> Self;
    fn neg(lhs: &Self) -> Self;
    fn inv(lhs: &Self) -> Self;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_cairo_code() {

    }
}
