use crate::fields::{affine::Affine, fq12::Fq12, FieldOps};

use super::{adder::CairoCodeAdder, circuit::Circuit, constants::get_imports};

pub struct CairoCodeBuilder {
    code: String,
}

impl CairoCodeBuilder {
    /// Create a new builder instance
    pub fn new() -> Self {
        Self {
            code: String::new(),
        }
    }

    /// Get the final generated code as a &str
    pub fn as_str(&self) -> &str {
        &self.code
    }

    pub fn assign_variable(&mut self, name: &str, circuit: Circuit) -> &mut Self {
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

    pub fn add_imports(&mut self) -> &mut Self {
        let imports = get_imports(); 
        self.code = imports + self.as_str();
        self
    }

    pub fn add_circuit<A: CairoCodeAdder>(&mut self, out: A, names: Option<Vec<&str>>) -> &mut Self {
        out.add_circuit(self, names);
        self
    }

    /// Consume the builder and return the final code
    pub fn build(self) -> String {
        self.code
    }
}