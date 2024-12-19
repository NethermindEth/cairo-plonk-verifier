
use crate::fq2::*; 

#[derive(Clone, Default, Debug)]
pub struct Circuit {
    inner: String,
}

impl Circuit {
    pub fn new<S: Into<String>>(inner: S) -> Self {
        Circuit {inner: inner.into()}
    }

    // Formats a circuit with the circuit element wrapper and terminating brackets
    pub fn format_circuit(&mut self) -> Circuit {
        Circuit::new(format!(r#"CE::<{}> {{}};"#, self.inner))
    }

    pub fn circuit_input(idx: usize) -> Self {
        Circuit::new(format!(r#"CI::<{}>"#, idx))
    }

    // Helper functions for building sub circuits (without circuit elemement wrapper and terminating brackets)
    pub fn circuit_add(lhs: &Circuit, rhs: &Circuit) -> Self {
        Circuit::new(format!(r#"A::<{}, {}>"#, lhs.inner, rhs.inner))
    }

    pub fn circuit_sub(lhs: &Circuit, rhs: &Circuit) -> Self {
        Circuit::new(format!(r#"S::<{}, {}>"#, lhs.inner, rhs.inner))
    }

    pub fn circuit_mul(lhs: &Circuit, rhs: &Circuit) -> Self {
        Circuit::new(format!(r#"M::<{}, {}>"#, lhs.inner, rhs.inner))
    }

    pub fn circuit_inv(lhs: &Circuit) -> Circuit {
        Circuit::new(format!(r#"I::<{}>"#, lhs.inner))
    }

    pub fn inner(self) -> String {
        self.inner
    }
}



pub struct CairoCodeBuilder {
    code: String,
}

pub enum CircuitBuilder {
    // PtOnSlopeFq {
    //     fq_x: String,
    //     fq_y: String,
    //     inp: [usize; 4],
    // },
    ChordFq2 {
        fq_x: String,
        fq_y: String,
        inp: [usize; 8],
    }
}

impl CircuitBuilder {
    // pub fn pt_on_slope_fq(inp: [usize; 4]) -> CircuitBuilder {
    //     let fq_x = format!(r#"core::circuit::CircuitElement::<S::<S::<M::<CI::<{}>, CI::<{}>>, CI::<{}>>, CI::<{}>>> {{}};"#, inp[0], inp[0], inp[1], inp[3]);
    //     let fq_y = format!(r#"core::circuit::CircuitElement::<S::<M::<CI::<{}>, S::<CI::<{}>, S::<S::<M::<CI::<{}>, CI::<{}>>, CI::<{}>>, CI::<{}>>>>, CI::<{}>>> {{}};"#, inp[0], inp[1], inp[0], inp[0], inp[1], inp[3], inp[2]); 
        
    //     CircuitBuilder::PtOnSlopeFq {
    //         fq_x,
    //         fq_y,
    //         inp,
    //     }
    // }
    
    // lhs: Fq2 - rhs: Fq2
    // lhs_x_0 = inp[0]
    // lhs_x_1
    // lhs_y_0
    // lhs_y_1 ...
    // rhs_x_0 
    // rhs_x_1
    // rhs_y_0
    // rhs_y_1 = inp[7]
    pub fn ChordFq2(lhs: Option<AffineFq2>, rhs: Option<AffineFq2>, inp: [usize; 8]) -> CircuitBuilder {
        

        CircuitBuilder::ChordFq2 { fq_x: "".to_string(), fq_y: "".to_string(), inp }
    }
}

impl CairoCodeBuilder {
    /// Create a new builder instance
    pub fn new() -> Self {
        Self {
            code: String::new(),
        }
    }

    pub fn add_circuit(&mut self, name: &str, circuit: Circuit) -> &mut Self {
        // match circuit {
        //     // CircuitBuilder::PtOnSlopeFq { fq_x, fq_y, inp } => {
        //     //     self.code.push_str(&("let fq_x = ".to_string() + &fq_x));
        //     // },
        // }
        let line = "let ".to_string() + name + " = " + &circuit.inner();
        self.add_line(line);
        self
    }

    /// Add a line of code as-is
    pub fn add_line<S: AsRef<str>>(&mut self, line: S) -> &mut Self {
        self.code.push_str(line.as_ref());
        self.code.push('\n');
        self
    }

    /// Get the final generated code as a &str
    pub fn as_str(&self) -> &str {
        &self.code
    }

    pub fn add_imports(&mut self) -> &mut Self {
        let imports = "use core::circuit::{\n\t\
            AddModGate as A,\n\t\
            SubModGate as S,\n\t\
            MulModGate as M,\n\t\
            InverseGate as I,\n\t\
            CircuitInput as CI,\n\t\
            CircuitElement as CE,\n\
            };\n".to_string();
        self.code = imports + self.as_str();
        self
    }

    /// Consume the builder and return the final code
    pub fn build(self) -> String {
        self.code
    }
}

/// A convenience function that directly generates a simple Cairo file
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

    builder.add_circuit("slope_x", t4);
    builder.add_circuit("slope_y", t3);

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