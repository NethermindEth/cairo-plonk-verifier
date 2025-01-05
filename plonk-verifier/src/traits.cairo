
trait FieldEqs<TFq> {
    fn eq(lhs: @TFq, rhs: @TFq) -> bool;
}

trait FieldOps<TFq, M> {
    fn add(self: TFq, rhs: TFq, m: M) -> TFq;
    fn sub(self: TFq, rhs: TFq, m: M) -> TFq;
    fn mul(self: TFq, rhs: TFq, m: M) -> TFq;
    fn div(self: TFq, rhs: TFq, m: M) -> TFq;
    fn sqr(self: TFq, m: M) -> TFq;
    fn neg(self: TFq, m: M) -> TFq;
    fn inv(self: TFq, m: M) -> TFq;
}

trait FieldUtils<TFq, TFqChildren, M> {
    fn one() -> TFq;
    fn zero() -> TFq;
    fn conjugate(self: TFq, m: M) -> TFq;
    fn scale(self: TFq, by: TFqChildren, m: M) -> TFq;
    fn mul_by_nonresidue(self: TFq, m: M) -> TFq;
    fn frobenius_map(self: TFq, power: usize, m: M) -> TFq;
}

trait MillerPrecompute<TG1, TG2, TPreComp, M> {
    fn precompute(self: (TG1, TG2), m: M) -> (TPreComp, TG2);
}

trait MillerSteps<TPreComp, TG2, TFq> {
    // square target group element
    fn sqr_target(self: @TPreComp, i: u32, ref acc: TG2, ref f: TFq);
    // first and second step
    fn miller_first_second(self: @TPreComp, i1: u32, i2: u32, ref acc: TG2) -> TFq;
    // 0 bit
    fn miller_bit_o(self: @TPreComp, i: u32, ref acc: TG2, ref f: TFq);
    // 1 bit
    fn miller_bit_p(self: @TPreComp, i: u32, ref acc: TG2, ref f: TFq);
    // -1 bit
    fn miller_bit_n(self: @TPreComp, i: u32, ref acc: TG2, ref f: TFq);
    // last step
    fn miller_last(self: @TPreComp, ref acc: TG2, ref f: TFq);
}
