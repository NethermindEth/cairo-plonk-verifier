// Helper Functions for Generating Cairo Circuits
use crate::fields::{affine::Affine, fq12::{Fq12, sqr_offset}, fq2::Fq2, fq6::Fq6, ECOperations, FieldOps};

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