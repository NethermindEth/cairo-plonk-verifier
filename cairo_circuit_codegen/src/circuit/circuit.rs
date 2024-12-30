use std::fmt::Write;

#[derive(Clone, Default, Debug)]
pub struct Circuit {
    inner: String,
}

impl Circuit {
    pub fn new<S: Into<String>>(inner: S) -> Self {
        Circuit {inner: inner.into()}
    }

    // Formats a circuit with the circuit element wrapper and terminating brackets
    pub fn format_circuit(&self) -> Circuit {
        Circuit::new(format!(r#"CE::<{}> {{}};"#, self.inner))
    }

    pub fn circuit_input(idx: usize) -> Self {
        Circuit::new(format!(r#"CI::<{}>"#, idx))
    }

    // Helper functions for building sub circuits (without circuit elemement wrapper and terminating brackets)
    pub fn circuit_add(lhs: &Circuit, rhs: &Circuit) -> Self {
        // Circuit::new(format!(r#"A::<{}, {}>"#, lhs.inner, rhs.inner))
        let mut result = String::with_capacity(10 + lhs.inner.len() + rhs.inner.len());
        write!(&mut result, r#"A::<{}, {}>"#, lhs.inner, rhs.inner).unwrap();
    
        Circuit::new(result)
    }

    pub fn circuit_sub(lhs: &Circuit, rhs: &Circuit) -> Self {
        // Circuit::new(format!(r#"S::<{}, {}>"#, lhs.inner, rhs.inner))
        let mut result = String::with_capacity(10 + lhs.inner.len() + rhs.inner.len());
        write!(&mut result, r#"S::<{}, {}>"#, lhs.inner, rhs.inner).unwrap();
    
        Circuit::new(result)
    }

    pub fn circuit_mul(lhs: &Circuit, rhs: &Circuit) -> Self {
        // Circuit::new(format!(r#"M::<{}, {}>"#, lhs.inner, rhs.inner))
        let mut result = String::with_capacity(10 + lhs.inner.len() + rhs.inner.len());
        write!(&mut result, r#"M::<{}, {}>"#, lhs.inner, rhs.inner).unwrap();
    
        Circuit::new(result)
    }

    pub fn circuit_inv(lhs: &Circuit) -> Circuit {
        // Circuit::new(format!(r#"I::<{}>"#, lhs.inner))
        let mut result = String::with_capacity(10 + lhs.inner.len());
        write!(&mut result, r#"I::<{}>"#, lhs.inner).unwrap();
    
        Circuit::new(result)
    }

    pub fn inner(self) -> String {
        self.inner
    }
}