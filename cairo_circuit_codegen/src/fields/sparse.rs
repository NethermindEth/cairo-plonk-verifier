use super::{fq::Fq, fq12::Fq12, fq2::Fq2, fq6::Fq6, FieldConstants, FieldOps};

#[derive(Debug, Clone,)]
pub struct Fq12Sparse034 {
    c3: Fq2,
    c4: Fq2,
}

pub struct Fq12Sparse01234 {
    c0: Fq6,
    c1: Fq6Sparse01,
}

#[derive(Debug, Clone,)]
pub struct Fq6Sparse01 {
    c0: Fq2,
    c1: Fq2,
}

impl Fq12Sparse01234 {
    pub fn new(c0: Fq6, c1: Fq6Sparse01) -> Self {
        Self { c0, c1 }
    }

    pub fn c0(&self) -> &Fq6 {
        &self.c0
    }

    pub fn c1(&self) -> &Fq6Sparse01 {
        &self.c1
    }

    pub fn mul_01234_01234(&self, rhs: &Self) -> Fq12 {
        let (a0, a1) = (self.c0(), self.c1());
        let (b0, b1) = (rhs.c0(), rhs.c1());
        
        let b = Fq6::new(b0.c0() + b1.c0(), b0.c1() + b1.c1(), b0.c2().clone(), None);
        let c1 = Fq6::new(a0.c0() + a1.c0(), a0.c1() + a1.c1(), a0.c2().clone(), None);
        let c1 = c1 * b;

        let u = a0 * b0;
        let v = a1.mul_01_by_01(b1);

        let c0 = &v.mul_by_v() + &u;
        let c1 = c1 - (u + v);

        Fq12::new(c0, c1, None)
    }
}

impl Fq6Sparse01 {
    pub fn new(c0: Fq2, c1: Fq2) -> Self {
        Self { c0, c1 }
    }

    pub fn c0(&self) -> &Fq2 {
        &self.c0
    }

    pub fn c1(&self) -> &Fq2 {
        &self.c1
    }

    pub fn mul_01_by_01(&self, rhs: &Self) -> Fq6 {
        let (a0, a1)  = (self.c0(), self.c1());
        let (b0, b1)  = (rhs.c0(), rhs.c1());

        let v0 = a0 * b0;
        let v1 = a1 * b1;
        let c1 = &(&((a0 + a1) * (b0 + b1)) - &v0) - &v1;

        Fq6::new(v0, c1, v1, None)
           
    }
}

impl Fq12Sparse034 {
    pub fn new(c3: Fq2, c4: Fq2) -> Self {
        Self { c3, c4 }
    }

    pub fn c3(&self) -> &Fq2 {
        &self.c3
    }

    pub fn c4(&self) -> &Fq2 {
        &self.c4
    }

    pub fn mul_034_by_034(&self, rhs: &Self) -> Fq12Sparse01234 {
        let (c3, c4) = (self.c3(), self.c4());
        let (d3, d4) = (rhs.c3(), rhs.c4());
        
        let c3d3 = c3 * d3;
        let c4d4 = c4 * d4; 
        let x04 = c4 + d4;
        let x03 = c3 + d3;
        let x34 = (d3 + d4) * (c3 + c4);
        let x34 = &x34 - &c3d3;
        let x34 = &x34 - &c4d4;

        let zc0b0 = c4d4.mul_by_xi();
        let zc0b0 = Fq2::new(zc0b0.c0() + &Fq::one(), zc0b0.c1().clone(), None);
        
        Fq12Sparse01234::new(Fq6::new(zc0b0, c3d3, x34, None), Fq6Sparse01::new(x03, x04))        
    }

    pub fn sqr_034(&self) -> Fq12Sparse01234 {
        let (c3, c4) = (self.c3(), self.c4());

        let c3_sq = c3.sqr();
        let c4_sq = c4.sqr();
        let x04 = c4 + c4;
        let x03 = c3 + c3; 
        let x34 = (c3 + c4).sqr();
        let x34 = &x34 - &c3_sq;
        let x34 = &x34 - &c4_sq;

        let zc0b0 = c4_sq.mul_by_xi();
        let zc0b0 = Fq2::new(zc0b0.c0() + &Fq::one(), zc0b0.c1().clone(), None);
        
        Fq12Sparse01234::new(Fq6::new(zc0b0, c3_sq, x34, None), Fq6Sparse01::new(x03, x04))
    } 
}

