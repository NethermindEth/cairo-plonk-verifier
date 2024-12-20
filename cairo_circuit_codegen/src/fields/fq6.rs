use super::{fq::Fq, fq2::Fq2};

#[derive(Clone, Debug)]
pub struct Fq6 {
    c0: Fq2,
    c1: Fq2,
    c2: Fq2,
    inp: Option<[usize; 6]>,
}

impl Fq6 {
    pub fn new_input(idx: [usize; 6]) -> Self {
        Self {
            c0: Fq2::new_input([idx[0], idx[1]]), 
            c1: Fq2::new_input([idx[2], idx[3]]), 
            c2: Fq2::new_input([idx[4], idx[5]]),
            inp: Some(idx)
        }
    }

    pub fn c0(&mut self) -> &mut Fq2 {
        &mut self.c0
    }

    pub fn c1(&mut self) -> &mut Fq2 {
        &mut self.c1
    }

    pub fn c2(&mut self) -> &mut Fq2 {
        &mut self.c2
    }
}