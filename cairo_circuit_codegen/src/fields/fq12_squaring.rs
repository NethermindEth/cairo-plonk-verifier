use super::{fq::Fq, fq2::Fq2, fq6::Fq6, sparse::{Fq12Sparse01234, Fq12Sparse034, Fq6Sparse01}, FieldConstants, FieldOps, FieldUtils};

#[derive(Clone, Debug, Default)]
pub struct Krbn2345 {
    g2: Fq2,
    g3: Fq2,
    g4: Fq2,
    g5: Fq2,
    inp: Option<[usize; 8]>,
}

impl Krbn2345 {
    pub fn new(g2: Fq2, g3: Fq2, g4: Fq2, g5: Fq2, inp: Option<[usize; 8]>) -> Self {
        Self { g2, g3, g4, g5, inp }
    }

    pub fn new_input(idx: [usize; 8]) -> Self {
        Self {
            g2: Fq2::new_input([idx[0], idx[1]]), 
            g3: Fq2::new_input([idx[2], idx[3]]), 
            g4: Fq2::new_input([idx[4], idx[5]]),
            g5: Fq2::new_input([idx[6], idx[7]]),
            inp: Some(idx)
        }
    }

    pub fn g2(&self) -> &Fq2 {
        &self.g2
    }

    pub fn g3(&self) -> &Fq2 {
        &self.g3
    }

    pub fn g4(&self) -> &Fq2 {
        &self.g4
    }

    pub fn g5(&self) -> &Fq2 {
        &self.g5
    }

    pub fn sqr_krbn(&self) -> Self {
        // Scaling factor optimized to add instead (2x = x + x)

        let (g2, g3, g4, g5)= (self.g2(), self.g3(), self.g4(), self.g5());

        let S2 = g2.sqr();
        let S3 = g3.sqr();
        let S4 = g4.sqr();
        let S5 = g5.sqr();
        let S4_5 = g4.add(g5).sqr();
        let S2_3 = g2.add(g3).sqr();

        let Tmp = S4_5.sub(&S4.add(&S5)).mul_by_xi();
        let h2 = Tmp.add(g2);
        let h2 = &h2 + &h2 + Tmp;

        let Tmp = S4.add(&S5.mul_by_xi());
        let h3 = Tmp.sub(g3);
        let h3 = &h3 + &h3 + Tmp;

        let Tmp = S2.add(&S3.mul_by_xi());
        let h4 = Tmp.sub(g4);
        let h4 = &h4 + &h4 + Tmp;

        let Tmp = S2_3.sub(&S2).sub(&S3);
        let h5 = Tmp.add(g5);
        let h5 = &h5 + &h5 + Tmp;

        Self { g2: h2, g3: h3, g4: h4, g5: h5, inp: None }
    }
}