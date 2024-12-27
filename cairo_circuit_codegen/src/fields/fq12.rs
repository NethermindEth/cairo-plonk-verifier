use super::{fq::Fq, fq2::Fq2, fq6::Fq6, sparse::{Fq12Sparse01234, Fq12Sparse034, Fq6Sparse01}, FieldConstants};

#[derive(Clone, Debug)]
pub struct Fq12 {
    c0: Fq6,
    c1: Fq6,
    inp: Option<[usize; 12]>,
}

impl Fq12 {
    pub fn new(c0: Fq6, c1: Fq6, inp: Option<[usize; 12]>) -> Self {
        Self { c0, c1, inp }
    }

    pub fn new_input(idx: [usize; 12]) -> Self {
        Self {
            c0: Fq6::new_input(idx[0..6].try_into().unwrap()), 
            c1: Fq6::new_input(idx[6..12].try_into().unwrap()), 
            inp: Some(idx)
        }
    }

    pub fn c0(&self) -> &Fq6 {
        &self.c0
    }

    pub fn c1(&self) -> &Fq6 {
        &self.c1
    }

    pub fn mul(&self, rhs: &Self) -> Self {
        let (a0, a1) = (self.c0(), self.c1());
        let (b0, b1) = (rhs.c0(), rhs.c1());
        
        let u = a0 * b0;
        let v = a1 * b1;
        let c0 = &v.mul_by_v() + &u;
        let c1 = (a0 + a1) * (b0 + b1) - u - v;

        Self { c0, c1, inp: None }
    }

    pub fn sqr(&self) -> Self {
        let (a0, a1) = (self.c0(), self.c1()); 
        let v = a0 * a1;
        let c0 = &(&((a0 + a1) * (a0 + &a1.mul_by_v())) - &v) - &v.mul_by_v();
        let c1 = &v + &v;

        Fq12 { c0, c1, inp: None }
    }

    pub fn mul_034(&self, rhs: &Fq12Sparse034) -> Fq12 {
        let (a0, a1) = (self.c0(), self.c1());
        let (c3, c4) = (rhs.c3(), rhs.c4());

        let b = a1.mul_01(&Fq6Sparse01::new(c3.clone(), c4.clone())); // todo: remove clone
        
        // Circuit div(x/x) = 1 
        let tmp = c3.c0() + &Fq::one();
        let c3 = Fq2::new(tmp, c3.c1().clone(), None);
        let d = a0 + a1;
        let d = d.mul_01(&Fq6Sparse01::new(c3, c4.clone()));

        let c1 = d - (&b + &a0);
        let c0 = &b.mul_by_v() + a0;

        Fq12 { c0, c1, inp: None }
    }

    pub fn mul_01234(&self, rhs: Fq12Sparse01234) -> Self {
        let (a0, a1) = (self.c0(), self.c1());
        let (b0, b1) = (rhs.c0(), rhs.c1());

        let b = Fq6::new(b0.c0() + b1.c0(), b0.c1() + b1.c1(), b0.c2().clone(), None);
        let c1 = (a0 + a1) * b;

        let u = a0 * b0;
        let v = a1.mul_01(b1);

        let c0 = &v.mul_by_v() + &u;
        let c1 = c1 - (u + v);

        Self { c0, c1, inp: None }
    }
}

#[cfg(test)]
mod test {
    use super::{Fq12, Fq2};
    use crate::circuit::CairoCodeBuilder;
    use crate::utils::utils::write_stdout; 
    #[test]
    pub fn test_fq12() {
        let idx_0: [usize; 12] = (0..=11).collect::<Vec<usize>>().try_into().unwrap();
        let idx_1: [usize; 12] = (12..=23).collect::<Vec<usize>>().try_into().unwrap();
        
        let in0 = &Fq12::new_input(idx_0);
        let in1 = &Fq12::new_input(idx_1); 
        
        let out = Fq12::mul(in0, in1);

        let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
        builder.add_fq12(out);

        let code = builder.build();
        write_stdout("out.cairo", code);
    }

    #[test]
    pub fn test_fq12_sqr() {
        let idx_0: [usize; 12] = (0..=11).collect::<Vec<usize>>().try_into().unwrap();
        
        let in0 = &Fq12::new_input(idx_0);
        let out = Fq12::sqr(in0);

        let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
        builder.add_fq12(out);

        let code = builder.build();
        write_stdout("out.cairo", code);
    }
}
