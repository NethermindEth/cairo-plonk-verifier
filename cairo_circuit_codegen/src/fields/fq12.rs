use super::{fq2::Fq2, fq6::Fq6, sparse::{Fq12Sparse034, Fq6Sparse01}};

#[derive(Clone, Debug)]
pub struct Fq12 {
    c0: Fq6,
    c1: Fq6,
    inp: Option<[usize; 12]>,
}

impl Fq12 {
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

    pub fn mul_034(&self, rhs: &Fq12Sparse034) -> Fq12 {
        let (a0, a1) = (self.c0(), self.c1());
        let (c3, c4) = (rhs.c3(), rhs.c4());

        let b = a1.mul_01(Fq6Sparse01::new(c3.clone(), c4.clone())); // todo: remove clone
        
        // Circuit div(x/x) = 1
        let tmp = c3.c0() + &(c3.c0() / c3.c0());
        let c3 = Fq2::new(tmp, c3.c1().clone(), None);
        let d = a0 + a1;
        let d = d.mul_01(Fq6Sparse01::new(c3, c4.clone()));

        let c1 = d - (&b + &a0);
        let c0 = &b.mul_by_v() + a0;

        Fq12 { c0, c1, inp: None }
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
}

#[cfg(test)]
mod test {
    use super::{Fq12, Fq2};
    use crate::circuit::CairoCodeBuilder;
    use crate::utils::utils::write_stdout; 
    #[test]
    pub fn test_fq12() {
        let idx_0: [usize; 12] = (1..=12).collect::<Vec<usize>>().try_into().unwrap();
        let idx_1: [usize; 12] = (12..=24).collect::<Vec<usize>>().try_into().unwrap();
        
        let in0 = &Fq12::new_input(idx_0);
        let in1 = &Fq12::new_input(idx_1); 
        
        let out = Fq12::mul(in0, in1);

        let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
        builder.add_fq12(out);

        let code = builder.build();
        write_stdout("out.cairo", code);
    }
}
