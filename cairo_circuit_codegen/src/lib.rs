pub struct CairoCodeBuilder {
    code: String,
}

pub struct Fq2 {
    c0: String,
    c1: String,
    inp: [usize; 2], 
}

pub struct AffineFq2 {
    x_c0: Fq2,
    x_c1: Fq2,
    
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
    //     let fq_x = format!(r#"core::circuit::CircuitElement::<core::circuit::SubModGate::<core::circuit::SubModGate::<core::circuit::MulModGate::<core::circuit::CircuitInput::<{}>, core::circuit::CircuitInput::<{}>>, core::circuit::CircuitInput::<{}>>, core::circuit::CircuitInput::<{}>>> {{}};"#, inp[0], inp[0], inp[1], inp[3]);
    //     let fq_y = format!(r#"core::circuit::CircuitElement::<core::circuit::SubModGate::<core::circuit::MulModGate::<core::circuit::CircuitInput::<{}>, core::circuit::SubModGate::<core::circuit::CircuitInput::<{}>, core::circuit::SubModGate::<core::circuit::SubModGate::<core::circuit::MulModGate::<core::circuit::CircuitInput::<{}>, core::circuit::CircuitInput::<{}>>, core::circuit::CircuitInput::<{}>>, core::circuit::CircuitInput::<{}>>>>, core::circuit::CircuitInput::<{}>>> {{}};"#, inp[0], inp[1], inp[0], inp[0], inp[1], inp[3], inp[2]); 
        
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
    
    pub fn add_circuit(&mut self, circuit: CircuitBuilder) -> &mut Self {
        match circuit {
            // CircuitBuilder::PtOnSlopeFq { fq_x, fq_y, inp } => {
            //     self.code.push_str(&("let fq_x = ".to_string() + &fq_x));
            // },
        }

        self
    }

    /// Add a line of code as-is
    pub fn add_line<S: AsRef<str>>(&mut self, line: S) -> &mut Self {
        self.code.push_str(line.as_ref());
        self.code.push('\n');
        self
    }

    /// Add an import statement
    pub fn add_import<S: AsRef<str>>(&mut self, path: S) -> &mut Self {
        self.add_line(format!("from {} import *", path.as_ref()))
    }

    /// Start a function definition
    pub fn add_function_start<S: AsRef<str>>(&mut self, name: S, args: &[&str]) -> &mut Self {
        let args_str = args.join(", ");
        self.add_line(format!("func {}({}) -> ():", name.as_ref(), args_str))
    }

    /// Add code within a function body
    pub fn add_function_body<S: AsRef<str>>(&mut self, line: S) -> &mut Self {
        // Indent the function body line for better readability
        self.add_line(format!("    {}", line.as_ref()))
    }

    /// End a function block with a return statement
    pub fn add_function_end(&mut self) -> &mut Self {
        self.add_line("    return ()")
    }

    /// Get the final generated code as a &str
    pub fn as_str(&self) -> &str {
        &self.code
    }

    /// Consume the builder and return the final code
    pub fn build(self) -> String {
        self.code
    }
}

/// A convenience function that directly generates a simple Cairo file
pub fn generate_cairo_code() -> String {
    let mut builder = CairoCodeBuilder::new();

    // let sopfq = CircuitBuilder::pt_on_slope_fq([0,1,2,3]);
    // builder.add_circuit(sopfq);

    // // Add a simple function
    // builder
    //     .add_function_start("main", &["x: felt", "y: felt"])
    //     .add_function_body("let sum = x + y")
    //     .add_function_body("serialize_word(sum)")
    //     .add_function_end();

    builder.build()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_cairo_code() {
        let code = generate_cairo_code();
        assert!(code.contains("func main(x: felt, y: felt) -> ():"));
        assert!(code.contains("serialize_word(sum)"));
    }
}
