// Helper Functions for Generating Cairo Circuits
use crate::{fields::{affine::Affine, fq::Fq, fq12::{sqr_offset, Fq12}, fq12_squaring::Krbn2345, fq2::Fq2, fq6::Fq6, ECOperations, FieldOps}, pairing::line::LineFn};

use super::{builder::CairoCodeBuilder, circuit::Circuit};

pub fn generate_fq12_field_ops() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
    let idx_0: [usize; 12] = (0..=11).collect::<Vec<usize>>().try_into().unwrap();
    let idx_1: [usize; 12] = (12..=23).collect::<Vec<usize>>().try_into().unwrap();
    
    let lhs = &Fq12::new_input(idx_0);
    let rhs = &Fq12::new_input(idx_1); 
    
    builder
        .add_line("// Fq12 Add")
        .add_circuit(Fq12::add(lhs, rhs), None)
        .add_line("// Fq12 Sub")
        .add_circuit(Fq12::sub(lhs, rhs), None)
        // .add_line("// Fq12 Mul")
        // .add_circuit(Fq12::mul(lhs, rhs), None)
        // .add_line("// Fq12 Sqr")
        // .add_circuit(Fq12::sqr(lhs), None)
        // .add_line("// Fq12 Div")
        // .add_circuit(Fq12::div(lhs, rhs), None)
        // .add_line("// Fq12 Inv")
        // .add_circuit(Fq12::inv(lhs), None)
        .add_line("// Fq12 Neg")
        .add_circuit(Fq12::neg(lhs), None);

    builder.build()
}

pub fn generate_fq6_field_ops() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
    let idx_0: [usize; 6] = (0..=5).collect::<Vec<usize>>().try_into().unwrap();
    let idx_1: [usize; 6] = (6..=11).collect::<Vec<usize>>().try_into().unwrap();
    
    let lhs = &Fq6::new_input(idx_0);
    let rhs = &Fq6::new_input(idx_1); 
    
    builder
        .add_line("// Fq6 Add")
        .add_circuit(Fq6::add(lhs, rhs), None)
        .add_line("// Fq6 Sub")
        .add_circuit(Fq6::sub(lhs, rhs), None)
        .add_line("// Fq6 Mul")
        .add_circuit(Fq6::mul(lhs, rhs), None)
        .add_line("// Fq6 Sqr")
        .add_circuit(Fq6::sqr(lhs), None)
        .add_line("// Fq6 Div")
        .add_circuit(Fq6::div(lhs, rhs), None)
        .add_line("// Fq6 Inv")
        .add_circuit(Fq6::inv(lhs), None)
        .add_line("// Fq6 Neg")
        .add_circuit(Fq6::neg(lhs), None);

    builder.build()
}

pub fn generate_fq2_field_ops() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
    let idx_0: [usize; 2] = (0..=1).collect::<Vec<usize>>().try_into().unwrap();
    let idx_1: [usize; 2] = (2..=3).collect::<Vec<usize>>().try_into().unwrap();
    
    let lhs = &Fq2::new_input(idx_0);
    let rhs = &Fq2::new_input(idx_1); 
    
    builder
        .add_line("// Fq2 Add")
        .add_circuit(Fq2::add(lhs, rhs), None)
        .add_line("// Fq2 Sub")
        .add_circuit(Fq2::sub(lhs, rhs), None)
        .add_line("// Fq2 Mul")
        .add_circuit(Fq2::mul(lhs, rhs), None)
        .add_line("// Fq2 Sqr")
        .add_circuit(Fq2::sqr(lhs), None)
        .add_line("// Fq2 Div")
        .add_circuit(Fq2::div(lhs, rhs), None)
        .add_line("// Fq2 Inv")
        .add_circuit(Fq2::inv(lhs), None)
        .add_line("// Fq2 Neg")
        .add_circuit(Fq2::neg(lhs), None);

    builder.build()
}

pub fn generate_affine_fq2_ops() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();

    let lhs: Affine<Fq2> = Affine::<Fq2>::new_input([0, 1, 2, 3]);
    let rhs: Affine<Fq2> = Affine::<Fq2>::new_input([4, 5, 6, 7]);
    let slope: Fq2 = Fq2::new_input([4, 5]);
    let x: Fq2 = Fq2::new_input([6, 7]);    

    builder
        .add_line("// Affine Fq2")
        .add_line("// x_on_slope")
        .add_circuit(lhs.x_on_slope(&slope, &x), None)
        .add_line("// y_on_slope")
        .add_circuit(lhs.y_on_slope(&slope, &x), None)
        .add_line("// pt_on_slope")
        .add_circuit(lhs.pt_on_slope(&slope, &x), None)
        .add_line("// chord")
        .add_circuit(lhs.chord(&rhs), None)
        .add_line("// add")
        .add_circuit(lhs.add(&rhs), None)
        .add_line("// tangent")
        .add_circuit(lhs.tangent(), None)
        .add_line("// double")
        .add_circuit(lhs.double(), None);
        
    builder.build()
}

pub fn generate_fq12_optimized_field_ops() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
    
    // idx are offset by 1 to use the offset scaling function
    let idx_0: [usize; 12] = (1..=12).collect::<Vec<usize>>().try_into().unwrap();
    let idx_1: [usize; 12] = (13..=24).collect::<Vec<usize>>().try_into().unwrap();
    
    let lhs = &Fq12::new_input(idx_0);
    let rhs = &Fq12::new_input(idx_1); 
    
    builder
        // .add_line("// Fq12 Add")
        // .add_circuit(Fq12::add(lhs, rhs), None)
        // .add_line("// Fq12 Sub")
        // .add_circuit(Fq12::sub(lhs, rhs), None)
        // .add_line("// Fq12 Mul")
        // .add_circuit(Fq12::mul(lhs, rhs), None)
        .add_line("// Fq12 Sqr")
        .add_circuit(sqr_offset(lhs), None);
        // .add_line("// Fq12 Div")
        // .add_circuit(Fq12::div(lhs, rhs), None)
        // .add_line("// Fq12 Inv")
        // .add_circuit(Fq12::inv(lhs), None)
        // .add_line("// Fq12 Neg")
        // .add_circuit(Fq12::neg(lhs), None);

    builder.build()
}

pub fn generate_line_fn_step_dbl_add() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();

    let mut acc: Affine<Fq2> = Affine::<Fq2>::new_input([0, 1, 2, 3]);
    let q: Affine<Fq2> = Affine::<Fq2>::new_input([4, 5, 6, 7]);
    
    let (lf1, lf2) = LineFn::step_dbl_add(&mut acc, &q);
    builder
        .add_line("// step_dbl_add")
        .add_line("// lf1")
        .add_circuit(lf1, Some(vec!["Lf1SlopeC0", "Lf1SlopeC1", "Lf1C0", "Lf1C1"]))
        .add_line("// lf1")
        .add_circuit(lf2, Some(vec!["Lf2SlopeC0", "Lf2SlopeC1", "Lf2C0", "Lf2C1"]))
        .add_line("// acc ")
        .add_circuit(acc, None);
        
    builder.build()
}

pub fn generate_krbn_sqr() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();

    let kr = Krbn2345::new_input([0, 1, 2, 3, 4, 5, 6, 7]);;
    
    builder
        .add_line("// krbn_sqr2345")
        .add_circuit(kr.sqr_krbn(), None);
        
    builder.build()
}

pub fn generate_krbn_decompress() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();

    let kr = Krbn2345::new_input([0, 1, 2, 3, 4, 5, 6, 7]);;
    let (g0, g1) = kr.krbn_decompress_if_zero();
    builder
        .add_line("// krbn_decompress")
        .add_line("// g0")
        .add_circuit(g0, Some(["KbrnDecompZeroG0C0", "KbrnDecompZeroG0C1"].to_vec()))
        .add_line("// g1")
        .add_circuit(g1, Some(["KbrnDecompZeroG1C0", "KbrnDecompZeroG1C1"].to_vec()));
        
    builder.build()
}

pub fn generate_krbn_non_zero_decompress() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();

    let kr = Krbn2345::new_input([0, 1, 2, 3, 4, 5, 6, 7]);;
    let (g0, g1) = kr.krbn_decompress_else();
    builder
        .add_line("// krbn_decompress")
        .add_line("// g0")
        .add_circuit(g0, Some(["KbrnDecompNonZeroG0C0", "KbrnDecompNonZeroG0C1"].to_vec()))
        .add_line("// g1")
        .add_circuit(g1, Some(["KbrnDecompNonZeroG1C0", "KbrnDecompNonZeroG1C1"].to_vec()));
        
    builder.build()
}

pub fn generate_compute_D_partial() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();

    let beta: Fq = Fq::new_input(0);
    let xi: Fq = Fq::new_input(1);
    let eval_a: Fq = Fq::new_input(2);
    let gamma: Fq = Fq::new_input(3);
    let vk_k1: Fq = Fq::new_input(4);
    let eval_b: Fq = Fq::new_input(5);
    let vk_k2: Fq = Fq::new_input(6);
    let eval_c: Fq = Fq::new_input(7);
    let alpha: Fq = Fq::new_input(8);
    let l1: Fq = Fq::new_input(9);
    let u: Fq = Fq::new_input(10);
    let eval_s1: Fq = Fq::new_input(11);
    let eval_s2: Fq = Fq::new_input(12);
    let eval_zw: Fq = Fq::new_input(13);

    let betaxi = Fq::mul(&beta, &xi);
    let mut d2a1 = Fq::add(&eval_a, &betaxi);
    d2a1 = Fq::add(&d2a1, &gamma);

    let mut d2a2 = Fq::mul(&betaxi, &vk_k1);
    d2a2 = Fq::add(&eval_b, &d2a2);
    d2a2 = Fq::add(&d2a2, &gamma);

    let mut d2a3 = Fq::mul(&betaxi, &vk_k2);
    d2a3 = Fq::add(&eval_c, &d2a3);
    d2a3 = Fq::add(&d2a3, &gamma);

    let d2a = Fq::mul(&Fq::mul(&Fq::mul(&d2a1, &d2a2), &d2a3), &alpha);

    let d2b = Fq::mul(&l1, &Fq::sqr(&alpha));
    let d2ab = Fq::add(&Fq::add(&d2a, &d2b), &u);
    
    let d3a = Fq::add(
        &Fq::add(&eval_a, &Fq::mul(&beta, &eval_s1)),
        &gamma,
    );

    let d3b = Fq::add(
        &Fq::add(&eval_b, &Fq::mul(&beta, &eval_s2)),
        &gamma
    );

    let d3c = Fq::mul(&Fq::mul(&alpha, &beta), &eval_zw);
    let d3ab = Fq::mul(&Fq::mul(&d3a, &d3b), &d3c);

    builder
    .add_line("// d_partial")
    .add_line("// D2AB")
    .add_circuit(d2ab, Some(["D2AB"].to_vec()))
    .add_line("// D3AB")
    .add_circuit(d3ab, Some(["D3AB"].to_vec()));
    
    builder.build()
}