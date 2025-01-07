use miller_utils::step_dbl_add;
use crate::fields::{affine::Affine, fq::Fq, fq12::Fq12, fq2::Fq2, sparse::Fq12Sparse034, ECOperations, FieldOps, FieldUtils};
use super::{MillerPrecompute, MillerSteps};

#[derive(Debug, Clone)]
pub struct Precompute {
    p: Affine<Fq>,
    q: Affine<Fq2>,
    neg_q: Affine<Fq2>,
    ppc: PPre,
    inp: Option<[usize; 6]>,
}

#[derive(Debug, Clone)]
pub struct PPre {
    neg_x_over_y: Fq,
    y_inv: Fq,
}

#[derive(Debug, Clone)]
pub struct LineFn {
    slope: Fq2,
    c: Fq2,
}

impl Precompute {
    pub fn p(&self) -> &Affine<Fq> {
        &self.p
    }

    pub fn q(&self) -> &Affine<Fq2> {
        &self.q
    }

    pub fn neg_q(&self) -> &Affine<Fq2> {
        &self.neg_q
    }

    pub fn ppc(&self) -> &PPre{
        &self.ppc
    }
}

impl MillerPrecompute for Precompute {
    type Precompute = Precompute;
    fn precompute(p: Affine<Fq>, q: Affine<Fq2>, inp: Option<[usize; 6]>) -> (Self, Affine<Fq2>) {
        let ppc = PPre::p_precompute(&p);
        let precompute = Self { p, q: q.clone(), neg_q: q.neg(), ppc, inp }; // refactor clones
        (precompute, q)
    }
}

impl PPre {
    pub fn neg_x_over_y(&self) -> &Fq {
        &self.neg_x_over_y
    }

    pub fn y_inv(&self) -> &Fq {
        &self.y_inv
    }

    pub fn p_precompute(p: &Affine<Fq>) -> Self {
        let y_inv = p.y().inv();
        Self { neg_x_over_y: -p.x() * y_inv.clone(), y_inv }
    }
}

impl MillerSteps for Precompute {    
    fn sqr_target(&mut self, i: u32, acc: &mut Affine<Fq2>, f: &mut Fq12) {
        *f = f.sqr();
    }

    fn miller_first_second(&mut self, i1: u32, i2: u32, acc: &mut Affine<Fq2>) -> Fq12 {
        let l0 = miller_utils::step_double(acc, &self.ppc, &self.p);
        let f_01234 = l0.sqr_034();

        let (l1, l2) = step_dbl_add(acc, &self.ppc, &self.p, &self.neg_q);
        // f_01234.mul_01234_01234(&l1.mul_034_by_034(&l2))
        Fq12::default()
    }

    fn miller_bit_o(&mut self, i: u32, acc: &mut Affine<Fq2>, f: &mut Fq12) {
        miller_utils::step_double_to_f(acc, f, &self.ppc, &self.p);
    }
    
    fn miller_bit_p(&mut self, i: u32, acc: &mut Affine<Fq2>, f: &mut Fq12) {
        miller_utils::step_dbl_add_to_f(acc, f, &self.ppc, &self.p, &self.q);
    }
    
    fn miller_bit_n(&mut self, i: u32, acc: &mut Affine<Fq2>, f: &mut Fq12) {
        miller_utils::step_dbl_add_to_f(acc, f, &self.ppc, &self.p, &self.neg_q);
    }
    
    fn miller_last(&mut self, acc: &mut Affine<Fq2>, f: &mut Fq12, pi_idx: [usize; 6]) {
        miller_utils::correction_step_to_f(acc, f, &self.ppc, &self.p, &self.q, pi_idx);
    }    
}

impl LineFn {
    pub fn slope(&self) -> &Fq2 {
        &self.slope
    }

    pub fn c(&self) -> &Fq2 {
        &self.c
    }

    pub fn line_fn(slope: &Fq2, s: &Affine<Fq2>) -> LineFn {
        LineFn { slope: slope.clone(), c: &(slope * s.x()) - s.y() } 
    }

    pub fn line_fn_at_p(&self, p_pre: &PPre) -> Fq12Sparse034 {
        Fq12Sparse034::new(self.slope().scale(&p_pre.neg_x_over_y()), self.c.scale(&p_pre.y_inv()))
    }

    // Fix the clone
    pub fn step_double(acc: &mut Affine<Fq2>) -> LineFn {
        // λ = (yS−yQ)/(xS−xQ)
        let slope = acc.tangent(); 
        // p = (λ²-2x, λ(x-xr)-y)
        let new_point = acc.pt_on_slope(&slope, &acc.x().clone());
        *acc = new_point; 
        Self::line_fn(&slope, acc) 
    }

    pub fn step_add(acc: &mut Affine<Fq2>, q: &Affine<Fq2>) -> LineFn {
        // λ = (yS−yQ)/(xS−xQ)
        let slope = acc.chord(q);
        // p = (λ²-2x, λ(x-xr)-y)
        let new_point = acc.pt_on_slope(&slope, &q.x());
        *acc = new_point; 

        Self::line_fn(&slope, acc)
    }    

    pub fn step_dbl_add(acc: &mut Affine<Fq2>, q: &Affine<Fq2>) -> (LineFn, LineFn) {
        let slope1 = acc.chord(q);
        let x1 = acc.x_on_slope(&slope1, &q.x());
        let line1 = Self::line_fn(&slope1, acc); 

        let slope2 = -slope1 - (acc.y() + acc.y()) / (&x1 - acc.x());
        *acc = acc.pt_on_slope(&slope2, &x1);
        let line2 = Self::line_fn(&slope2, acc); 

        (line1, line2)
    }

    pub fn correction_step(acc: &mut Affine<Fq2>, q: &Affine<Fq2>, pi_idx: [usize; 6]) -> (LineFn, LineFn) {
        // Circuit input indexes for constants
        let q1x2_idx: [usize; 2] = [pi_idx[0], pi_idx[1]];
        let q1x3_idx: [usize; 2] = [pi_idx[2], pi_idx[3]];
        let q2x2_idx: usize = pi_idx[4];
        let q2x3_idx: usize = pi_idx[5];
        let affine_q1_idx: [usize; 4] = [pi_idx[0], pi_idx[1], pi_idx[2], pi_idx[3]];
        let affine_q2_idx: [usize; 4] = [pi_idx[4], pi_idx[5], 0, 0];

        let q1 =  Affine::<Fq2>::new(q.x().conjugate().fq2_mul_nr(q1x2_idx), q.y().conjugate().fq2_mul_nr(q1x3_idx), affine_q1_idx);
        let q2 = Affine::<Fq2>::new(q.x().fq2_scale_nr(q2x2_idx), q.y().fq2_scale_nr(q2x3_idx).neg(), affine_q2_idx);

        let d = Self::step_add(acc, &q1);
        let slope = acc.chord(&q2);
        let e = LineFn::line_fn(&slope, acc);

        (d, e)
    }
}

mod miller_utils {
    use crate::fields::{affine::Affine, fq::Fq, fq12::Fq12, fq2::Fq2, sparse::Fq12Sparse034};
    use super::{LineFn, PPre};

    pub fn step_double_to_f(acc: &mut Affine<Fq2>, f: &mut Fq12, p_pre: &PPre, p: &Affine<Fq>) {
        *f = f.mul_034(&step_double(acc, p_pre, p));
    }

    pub fn step_double(acc: &mut Affine<Fq2>, p_pre: &PPre, p: &Affine<Fq>) -> Fq12Sparse034 {
        let lf = LineFn::step_double(acc);
        LineFn::line_fn_at_p(&lf, &p_pre)
    }

    pub fn step_dbl_add(acc: &mut Affine<Fq2>, p_pre: &PPre, p: &Affine<Fq>, q: &Affine<Fq2>) -> (Fq12Sparse034, Fq12Sparse034) {
        let (lf1, lf2) = LineFn::step_dbl_add(acc, q);
        (LineFn::line_fn_at_p(&lf1, p_pre), LineFn::line_fn_at_p(&lf2, p_pre))
    }

    pub fn step_dbl_add_to_f(acc: &mut Affine<Fq2>, f: &mut Fq12, p_pre: &PPre, p: &Affine<Fq>, q: &Affine<Fq2>) {
        let (l1, l2) = step_dbl_add(acc, p_pre, p, q);
        *f = f.mul_01234(l1.mul_034_by_034(&l2));
    }

    pub fn correction_step(acc: &mut Affine<Fq2>, p_pre: &PPre, p: &Affine<Fq>, q: &Affine<Fq2>, pi_idx: [usize; 6]) -> (Fq12Sparse034, Fq12Sparse034) {
        let (lf1, lf2) = LineFn::correction_step(acc, q, pi_idx);
        (LineFn::line_fn_at_p(&lf1, p_pre), LineFn::line_fn_at_p(&lf2, p_pre))
    }

    pub fn correction_step_to_f(acc: &mut Affine<Fq2>, f: &mut Fq12, p_pre: &PPre, p: &Affine<Fq>, q: &Affine<Fq2>, pi_idx: [usize; 6]) {
        let (l1, l2) = correction_step(acc, p_pre, p, q, pi_idx);
        *f = f.mul_01234(l1.mul_034_by_034(&l2));
    }
}

#[cfg(test)]
mod test {
    use crate::fields::{affine::Affine, fq::Fq, fq2::Fq2};

    #[test]
    fn ate_miller_test() {
        let inp: [usize; 6] = (0..=5).collect::<Vec<usize>>().try_into().unwrap();

        let p: Affine<Fq> = Affine::<Fq>::new_input([0, 1]);
        let q: Affine<Fq2> = Affine::<Fq2>::new_input([2, 3, 4, 5]);

        
    }
}