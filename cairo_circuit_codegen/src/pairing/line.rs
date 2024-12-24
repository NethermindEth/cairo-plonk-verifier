use crate::fields::{affine::Affine, fq::Fq, fq12::Fq12, fq2::Fq2, sparse::Fq12Sparse034, ECOperations, FieldUtils};

use super::MillerSteps;


#[derive(Debug, Clone)]
struct PreCompute {
    p: Affine<Fq>,
    q: Affine<Fq2>,
    neg_q: Affine<Fq2>,
    ppc: PPre,
}

#[derive(Debug, Clone)]
struct PPre {
    neg_x_over_y: Fq,
    y_inv: Fq,
}

impl PPre {
    pub fn neg_x_over_y(&self) -> &Fq {
        &self.neg_x_over_y
    }

    pub fn y_inv(&self) -> &Fq {
        &self.y_inv
    }
}

impl MillerSteps for PreCompute {
    fn miller_bit_o(&mut self, i: u32, acc: &mut Affine<Fq2>, f: &mut Fq12) {
        miller_utils::step_double_to_f(acc, f, &self.ppc, &self.p);
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
}


#[derive(Debug, Clone)]
struct LineFn {
    slope: Fq2,
    c: Fq2,
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

    
}