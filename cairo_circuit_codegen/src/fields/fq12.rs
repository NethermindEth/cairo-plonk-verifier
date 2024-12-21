use super::fq6::Fq6;

#[derive(Clone, Debug)]
pub struct Fq12 {
    c0: Fq6,
    c1: Fq6,
    inp: Option<[usize; 12]>,
}

impl Fq12 {
    pub fn new_input(idx: [usize; 12]) -> Self {
        Self {
            c0: Fq6::new_input(idx[0..6].try_into().unwrap()), 
            c1: Fq6::new_input(idx[6..12].try_into().unwrap()), 
            inp: Some(idx)
        }
    }

    pub fn c0(&self) -> &Fq6 {
        &self.c0
    }

    pub fn c1(&self) -> &Fq6 {
        &self.c1
    }
}