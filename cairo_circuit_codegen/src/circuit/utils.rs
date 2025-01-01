// Premade circuit generator functions
use crate::{fields::{affine::Affine, fq12::Fq12, fq2::Fq2, fq6::Fq6, FieldOps}, pairing::line::LineFn};
use super::builder::CairoCodeBuilder;

/// A testing function that directly generates a simple Cairo file
// pub fn generate_cairo_code() -> String {
//     let mut builder = CairoCodeBuilder::new();
//     let t0 = r#"M::<S::<CI::<6>, CI::<2>>, M::<S::<CI::<4>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>"#;
//     let t1 = r#"M::<S::<CI::<7>, CI::<3>>, M::<S::<CI::<5>, CI::<1>>, S::<S::<CI::<0>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>>"#;
//     let a0_add_a1 = r#"A::<S::<CI::<6>, CI::<2>>, S::<CI::<7>, CI::<3>>>"#;
//     let b0_add_b1 = r#"A::<M::<S::<CI::<4>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>,M::<S::<CI::<5>, CI::<1>>, S::<S::<CI::<0>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>>"#;
//     let t0 = Circuit::new(t0);
//     let t1 = Circuit::new(t1);
//     let a0_add_a1 = Circuit::new(a0_add_a1);
//     let b0_add_b1 = Circuit::new(b0_add_b1); 

//     let t2 = Circuit::circuit_mul(&a0_add_a1,&b0_add_b1 );
//     let t3 = Circuit::circuit_add(&t0, &t1);
//     let t3 = Circuit::circuit_sub(&t2, &t3).format_circuit();
//     let t4 = Circuit::circuit_sub(&t0, &t1).format_circuit();

//     builder.assign_variable("slope_x", t4);
//     builder.assign_variable("slope_y", t3);

//     builder.add_imports();
//     builder.build()
// }

pub fn generate_fq12_field_ops() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
    let idx_0: [usize; 12] = (0..=11).collect::<Vec<usize>>().try_into().unwrap();
    let idx_1: [usize; 12] = (12..=23).collect::<Vec<usize>>().try_into().unwrap();
    
    let in0 = &Fq12::new_input(idx_0);
    let in1 = &Fq12::new_input(idx_1); 
    
    builder.add_line("// Fq12 Add")
        .add_circuit(Fq12::add(in0, in1), None)
        .add_line("\n")
        .add_line("// Fq12 Sub")
        .add_circuit(Fq12::sub(in0, in1), None)
        .add_line("\n")

        // .add_line("// Fq12 Mul") // Too expensive (memory).
        // .add_circuit(Fq12::mul(in0, in1), None)
        // .add_line("\n")
        
        // .add_line("// Fq12 Sqr")
        // .add_circuit(Fq12::sqr(in0), None)
        // .add_line("\n")

        // .add_line("// Fq12 Div")
        // .add_circuit(Fq12::div(in0, in1), None)
        // .add_line("\n")

        // .add_line("// Fq12 Inv")
        // .add_circuit(Fq12::inv(in0), None)
        // .add_line("\n")

        .add_line("// Fq12 Neg")
        .add_circuit(Fq12::neg(in0), None)
        .add_line("\n");

    builder.build()
}

pub fn generate_fq6_field_ops() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
    let idx_0: [usize; 6] = (0..=5).collect::<Vec<usize>>().try_into().unwrap();
    let idx_1: [usize; 6] = (6..=11).collect::<Vec<usize>>().try_into().unwrap();
    
    let in0 = &Fq6::new_input(idx_0);
    let in1 = &Fq6::new_input(idx_1); 
    
    builder
        .add_line("// Fq6 Add")
        .add_circuit(Fq6::add(in0, in1), None)
        .add_line("\n");
    
    builder.add_line("// Fq6 Sub");
    builder.add_circuit(Fq6::sub(in0, in1), None);
    builder.add_line("\n");

    builder.add_line("// Fq6 Mul");
    builder.add_circuit(Fq6::mul(in0, in1), None);
    builder.add_line("\n");
    
    builder.add_line("// Fq6 Sqr");
    builder.add_circuit(Fq6::sqr(in0), None);
    builder.add_line("\n");

    builder.add_line("// Fq6 Div");
    builder.add_circuit(Fq6::div(in0, in1), None);
    builder.add_line("\n");

    builder.add_line("// Fq6 Inv");
    builder.add_circuit(Fq6::inv(in0), None);
    builder.add_line("\n");

    builder.add_line("// Fq6 Neg");
    builder.add_circuit(Fq6::neg(in0), None);
    builder.add_line("\n");

    builder.build()
}

// Line Functions
pub fn generate_step_dbl_add() -> String {
    let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
    let mut acc: Affine<Fq2> = Affine::<Fq2>::new_input([0, 1, 2, 3]);
    let q: Affine<Fq2> = Affine::<Fq2>::new_input([4, 5, 6, 7]);
    let lf1_names = vec!["l1_slope_c0", "l1_slope_c1", "l1_c0", "l1_c1"];
    let lf2_names = vec!["l2_slope_c0", "l2_slope_c1", "l2_c0", "l2_c1"];

    let (l1, l2) = LineFn::step_dbl_add(&mut acc, &q);

    builder.add_line("// step_dbl_add")
        .add_circuit(acc, None)
        .add_circuit(l1, Some(lf1_names))
        .add_circuit(l2, Some(lf2_names));
    
    builder.build()
}