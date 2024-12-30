use super::{builder::CairoCodeBuilder, circuit::Circuit};

/// A testing function that directly generates a simple Cairo file
pub fn generate_cairo_code() -> String {
    let mut builder = CairoCodeBuilder::new();
    let t0 = r#"M::<S::<CI::<6>, CI::<2>>, M::<S::<CI::<4>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>"#;
    let t1 = r#"M::<S::<CI::<7>, CI::<3>>, M::<S::<CI::<5>, CI::<1>>, S::<S::<CI::<0>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>>"#;
    let a0_add_a1 = r#"A::<S::<CI::<6>, CI::<2>>, S::<CI::<7>, CI::<3>>>"#;
    let b0_add_b1 = r#"A::<M::<S::<CI::<4>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>,M::<S::<CI::<5>, CI::<1>>, S::<S::<CI::<0>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>>"#;
    let t0 = Circuit::new(t0);
    let t1 = Circuit::new(t1);
    let a0_add_a1 = Circuit::new(a0_add_a1);
    let b0_add_b1 = Circuit::new(b0_add_b1); 

    let t2 = Circuit::circuit_mul(&a0_add_a1,&b0_add_b1 );
    let t3 = Circuit::circuit_add(&t0, &t1);
    let t3 = Circuit::circuit_sub(&t2, &t3).format_circuit();
    let t4 = Circuit::circuit_sub(&t0, &t1).format_circuit();

    builder.assign_variable("slope_x", t4);
    builder.assign_variable("slope_y", t3);

    // let sopfq = CircuitBuilder::pt_on_slope_fq([0,1,2,3]);
    // builder.add_circuit(sopfq);

    // // Add a simple function
    // builder m
    //     .add_function_start("main", &["x: felt", "y: felt"])
    //     .add_function_body("let sum = x + y")
    //     .add_function_body("serialize_word(sum)")
    //     .add_function_end();
    builder.add_imports();
    builder.build()
}