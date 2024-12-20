use std::ops::Sub;

use crate::fields::{FieldOps, fq::Fq};
use crate::fields::fq2::Fq2;
use crate::fields::ECOperations;

#[derive(Debug, Clone)]
pub struct Affine<F: FieldOps> {
    x: F,
    y: F,
    inp: Option<[usize; 4]>, // Switch to vec
}

impl<F: FieldOps> Affine<F> {
    pub fn x(&self) -> &F {
        &self.x
    }

    pub fn y(&self) -> &F {
        &self.y
    }
}

impl Affine<Fq> {
    pub fn new(x: Fq, y: Fq, inp: [usize; 2]) -> Self{
        Self {x, y, inp: Some([inp[0], inp[1], 0, 0])}
    }

    pub fn new_input(idx: [usize; 2]) -> Self {
        Self {
            x: Fq::new_input(idx[0]), 
            y: Fq::new_input(idx[1]), 
            inp: Some([idx[0], idx[1], 0, 0])
        }
    }
}

impl Affine<Fq2> {
    pub fn new(x: Fq2, y: Fq2, inp: [usize; 4]) -> Self{
        Self {x, y, inp: Some([inp[0], inp[1], inp[2], inp[3]])}
    }

    pub fn new_input(idx: [usize; 4]) -> Self {
        Self {
            x: Fq2::new_input([idx[0], idx[1]]), 
            y: Fq2::new_input([idx[2], idx[3]]), 
            inp: Some(idx)
        }
    }
}

impl<F: FieldOps> ECOperations<F> for Affine<F> 
    where F: Clone
{
    fn x_on_slope(&self, slope: &F, x2: &F) -> F {
        // x = λ^2 - x1 - x2
        slope.sqr().sub(&self.x).sub(x2)
    }

    fn y_on_slope(&self, slope: &F, x: &F) -> F {
        // y = λ(x1 - x) - y1
        slope.mul(&self.x.sub(x)).sub(&self.y)
    }

    fn pt_on_slope(&self, slope: &F, x2: &F) -> Self {
        let x = self.x_on_slope(slope, x2);
        let y = self.y_on_slope(slope, &x);

        Affine {x, y, inp: None}
    }

    fn chord(&self, rhs: &Self) -> F {
        let (x0, y0) = (&self.x, &self.y);
        let (x1, y1) = (&rhs.x, &rhs.y);
        // λ = (y2-y1) / (x2-x1)
        (y1.sub(y0)).div(&x1.sub(x0))
    }

    fn add(&self, rhs: &Self) -> Self {
        self.pt_on_slope(&self.chord(rhs), &rhs.x)
    }

    fn tangent(&self) -> F {
        let (x, y) = (&self.x, &self.y);
        // λ = 3x^2 / 2y
        let x_sqr = &x.sqr();
        x_sqr.add(x_sqr).add(x_sqr).div(&y.add(y))
    }

    fn double(&self) -> Self {
        self.pt_on_slope(&self.tangent(), &self.x)
    }

    fn neg(&self) -> Self {
        Self { x: self.x.clone(), y: self.y.neg(), inp: None }
    }
}

#[cfg(test)]
mod test {
    use super::{Affine, ECOperations, Fq2};
    use crate::circuit::CairoCodeBuilder;
    use crate::utils::utils::write_stdout;
    #[test]
    pub fn test_affine() {
        let in0 = &Affine::<Fq2>::new_input([0, 1, 2, 3]);
        let in1 = &Affine::<Fq2>::new_input([4, 5, 6, 7]);
        
        let mut out = in0.chord(in1);
        let out_0 = out.c0().c0().format_circuit();
        let out_1 = out.c1().c0().format_circuit();
        let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
        builder.add_circuit("out_0", out_0);
        builder.add_circuit("out_1", out_1);

        let code = builder.build();
        write_stdout("out.cairo", code);
    }
}