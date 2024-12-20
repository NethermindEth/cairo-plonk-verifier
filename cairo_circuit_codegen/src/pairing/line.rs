use crate::fields::{affine::Affine, fq::Fq, fq2::Fq2, ECOperations};

#[derive(Debug, Clone)]
struct PPrecompute {
    neg_x_over_y: Fq,
    y_inv: Fq,
}

#[derive(Debug, Clone)]
struct LineFn {
    slope: Fq2,
    c: Fq2,
}

impl LineFn {
    fn line_fn(slope: &Fq2, s: &Affine<Fq2>) -> LineFn {
        LineFn { slope: slope.clone(), c: &(slope * s.x()) - s.y() } 
    }

    // Fix the clone
    fn step_double(acc: &mut Affine<Fq2>) -> LineFn {
        // λ = (yS−yQ)/(xS−xQ)
        let slope = acc.tangent(); 
        // p = (λ²-2x, λ(x-xr)-y)
        let new_point = acc.pt_on_slope(&slope, &acc.x().clone());
        *acc = new_point; 
        Self::line_fn(&slope, acc) 
    }

    fn step_add(acc: &mut Affine<Fq2>, q: &Affine<Fq2>) -> LineFn {
        // λ = (yS−yQ)/(xS−xQ)
        let slope = acc.chord(q);
        // p = (λ²-2x, λ(x-xr)-y)
        let new_point = acc.pt_on_slope(&slope, &q.x());
        *acc = new_point; 
        Self::line_fn(&slope, acc)
    }

    
}