use crate::fields::{fq2::Fq2, fq6::Fq6, fq12::Fq12};

#[derive(Debug, Clone,)]
pub struct Fq12Sparse034 {
    c3: Fq2,
    c4: Fq2,
}

#[derive(Debug, Clone,)]
pub struct Fq6Sparse01 {
    c0: Fq2,
    c1: Fq2,
}

impl Fq6Sparse01 {
    pub fn new(c0: Fq2, c1: Fq2) -> Self {
        Self {c0, c1 }
    }

    pub fn c0(&self) -> &Fq2 {
        &self.c0
    }

    pub fn c1(&self) -> &Fq2 {
        &self.c1
    }
}

impl Fq12Sparse034 {
    pub fn new(c3: Fq2, c4: Fq2) -> Self {
        Self { c3, c4 }
    }

    pub fn c3(&self) -> &Fq2 {
        &self.c3
    }

    pub fn c4(&self) -> &Fq2 {
        &self.c4
    }
}