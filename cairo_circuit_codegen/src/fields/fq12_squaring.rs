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

    // Decompress krbn into fq12 except final g0 add 1 (Fq12 { c0: Fq6 { c0: g0, c1: g4, c2: g3 }, c1: Fq6 { c0: g2, c1: g1, c2: g5 } })
    // Note:
    // 1. Does not use g2, offset all circuit inputs by fq2
    // 2. Scale is replaced by addition circuit
    pub fn krbn_decompress_if_zero(&self) -> (Fq2, Fq2) {
        let (g3, g4, g5)= (self.g2(), self.g3(), self.g4());

        let g4mg5 = g4.mul(g5);
        let tg24g5 = &g4mg5 + &g4mg5;
        let g1 = tg24g5.mul(&g3.inv());

        // g0 = (2S1 - 3g3g4)ξ + 1
        let S1 = g1.sqr();
        let T_g3g4 = g3.mul(g4);
        let Tmp = (S1.sub(&T_g3g4));
        let Tmp = &Tmp + &Tmp; //.scale(TWO);
        let g0 = Tmp.sub(&T_g3g4.mul_by_xi());

        (g0, g1)
    }


    // Note:
    // 1. Scale is replaced by addition circuit
    pub fn krbn_decompress_else(&self) -> (Fq2, Fq2) {
        let (g2, g3, g4, g5)= (self.g2(), self.g3(), self.g4(), self.g5());

        let S5xi = g5.sqr().mul_by_xi();
        let S4 = g4.sqr();
        let Tmp = S4.sub(g3);
        let g1 = S5xi.add(&S4.add(&Tmp.add(&Tmp)));
        let x4g2 = &(&(g2 + g2) + g2) + g2;
        let g1 = g1.mul(&x4g2.inv());

        // // g0 = (2S1 + g2g5 - 3g3g4)ξ + 1
        let S1 = g1.sqr();
        let T_g3g4 = g3.mul(g4);
        let T_g2g5 = g2.mul(g5);
        let s1sg3g4 = S1.sub(&T_g3g4);
        let Tmp = &s1sg3g4 + &s1sg3g4;
        let g0 = Tmp.add(&T_g2g5.sub(&T_g3g4)).mul_by_xi();

        (g0, g1)
    }
}