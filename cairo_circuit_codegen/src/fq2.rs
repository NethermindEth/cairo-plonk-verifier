use crate::circuit::*;

pub struct Fq {
    c0: Circuit,
}

impl Fq {

}

pub struct Fq2 {
    c0: Circuit,
    c1: Circuit,
    inp: Option<[usize; 2]>, 
}

pub struct AffineFq2 {
    x: Fq2,
    y: Fq2,
    inp: Option<[usize; 4]>,
}

// TODO: create trait and overload operators
trait FieldOps<TFq> {
    fn add(lhs: &TFq, rhs: &TFq) -> TFq;
    fn sub(self: TFq, rhs: TFq) -> TFq;
    fn mul(self: TFq, rhs: TFq) -> TFq;
    fn div(self: TFq, rhs: TFq) -> TFq;
    fn sqr(self: TFq) -> TFq;
    fn neg(self: TFq) -> TFq;
    fn inv(self: TFq) -> TFq;
}

