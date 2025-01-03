trait FieldUtils<TFq, TFqChildren> {
    fn one() -> TFq;
    fn zero() -> TFq;
    fn conjugate(self: TFq) -> TFq;
    fn scale(self: TFq, by: TFqChildren) -> TFq;
    fn mul_by_nonresidue(self: TFq,) -> TFq;
    fn frobenius_map(self: TFq, power: usize) -> TFq;
}

trait FieldOps<TFq> {
    fn add(self: TFq, rhs: TFq) -> TFq;
    fn sub(self: TFq, rhs: TFq) -> TFq;
    fn mul(self: TFq, rhs: TFq) -> TFq;
    fn div(self: TFq, rhs: TFq) -> TFq;
    fn sqr(self: TFq) -> TFq;
    fn neg(self: TFq) -> TFq;
    fn eq(lhs: @TFq, rhs: @TFq) -> bool;
    fn inv(self: TFq) -> TFq;
}

trait MillerPrecompute<TG1, TG2, TPreComp> {
    fn precompute(self: (TG1, TG2), field_nz: NonZero<u256>) -> (TPreComp, TG2);
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
