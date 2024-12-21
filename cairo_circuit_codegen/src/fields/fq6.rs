use super::{fq::Fq, fq2::Fq2, FieldOps};

#[derive(Clone, Debug)]
pub struct Fq6 {
    c0: Fq2,
    c1: Fq2,
    c2: Fq2,
    inp: Option<[usize; 6]>,
}

impl Fq6 {
    pub fn new_input(idx: [usize; 6]) -> Self {
        Self {
            c0: Fq2::new_input([idx[0], idx[1]]), 
            c1: Fq2::new_input([idx[2], idx[3]]), 
            c2: Fq2::new_input([idx[4], idx[5]]),
            inp: Some(idx)
        }
    }

    pub fn c0(&self) -> &Fq2 {
        &self.c0
    }

    pub fn c1(&self) -> &Fq2 {
        &self.c1
    }

    pub fn c2(&self) -> &Fq2 {
        &self.c2
    }
}

impl FieldOps for Fq6 {
    fn add(&self, rhs: &Self) -> Self {
        Self { c0: &self.c0 + &rhs.c0, c1: &self.c1 + &rhs.c1, c2: &self.c2 + &rhs.c2, inp: None }
    }

    fn sub(&self, rhs: &Self) -> Self {
        Self { c0: &self.c0 - &rhs.c0, c1: &self.c1 - &rhs.c1, c2: &self.c2 - &rhs.c2, inp: None }
    }

    // Todo: Clean code by using helper function for consecutive operations
    fn mul(&self, rhs: &Self) -> Self {
        let (a0, a1, a2) = (self.c0(), self.c1(), self.c2()); 
        let (b0, b1, b2) = (rhs.c0(), rhs.c1(), rhs.c2());
        
        let (v0, v1, v2) = &(a0 * b0, a1 * b1, a2 * b2);

        let c0 = v0 + &(&(&((a1 + a2) * (b1 + b2)) - v1) - v2).mul_by_xi();
        let c1 = &(&((a0 + a1) * (b0 + b1)) - v0) - v1 + v2.mul_by_xi();
        let c2 = &(&(&((a0 + a2) * (b0 + b2)) - v0) + v1) - v2;

        Self {c0, c1, c2, inp: None }
    }

    fn sqr(&self,) -> Self {
        let (c0, c1, c2) = (self.c0(), self.c1(), self.c2());

        let s0 = c0.sqr();
        let ab = c0 * c1;
        let s1 = &ab + &ab;
        let s2 = (&(c0 + c2) - c1).sqr();
        let bc = c1 * c2;
        let s3 = &bc + &bc;
        let s4 = c2.sqr();

        let c0 = &s0 + &s3.mul_by_xi();
        let c1 = &s1 + &s4.mul_by_xi();
        let c2 = s1 + s2 + s3 - s0 - s4;

        Self {c0, c1, c2, inp: None } 
    }

    fn neg(&self,) -> Self {
        Self { c0: -&self.c0, c1: -&self.c1, c2: -&self.c2, inp: None }
    }


    fn inv(&self,) -> Self {
        let (c0, c1, c2) = (self.c0(), self.c1(), self.c2());

        let v0 = c0.sqr() - (c1 * c2).mul_by_xi();
        let v1 = c2.sqr().mul_by_xi() - (c0 * c1); 
        let v2 = c1.sqr() - (c0 * c2);
        let t = (((c2 * &v1) + (c1 * &v2)).mul_by_xi() + (c0 * &v0)).inv();

        Self {c0: &v0 * &t, c1: &v1 * &t, c2: &v2 * &t, inp: None } 
    }
    
    fn div(&self, rhs: &Self) -> Self {
        Self::mul(self, &rhs.inv())
    }
}