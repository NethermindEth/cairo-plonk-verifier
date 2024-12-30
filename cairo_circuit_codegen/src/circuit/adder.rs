use crate::fields::affine::Affine;
use crate::fields::fq::Fq;
use crate::fields::fq12::Fq12;

use crate::circuit::builder::CairoCodeBuilder;
use crate::fields::fq2::Fq2;
use crate::fields::fq6::Fq6;
use crate::fields::{ECOperations, FieldOps};
use crate::pairing::line::Precompute;

pub trait CairoCodeAdder {
    fn add_circuit(&self, builder: &mut CairoCodeBuilder, names: Option<Vec<&str>>); 
}

impl CairoCodeAdder for Fq {
    fn add_circuit(&self, builder: &mut CairoCodeBuilder, names: Option<Vec<&str>>) {
        // Default if name is not supplied
        let names = names
        .filter(|v| v.len() >= 1)
        .unwrap_or(vec!["c0"]);

        let c0 = self.c0().format_circuit();
        
        builder.assign_variable(names[0], c0);
    }
}

impl CairoCodeAdder for Fq2 {
    fn add_circuit(&self, builder: &mut CairoCodeBuilder, names: Option<Vec<&str>>) {
        let names = names
        .filter(|v| v.len() >= 2)
        .unwrap_or(vec!["c0", "c1"]);

        let c0 = self.c0().c0().format_circuit();
        let c1 = self.c1().c0().format_circuit();
        
        builder.assign_variable(names[0], c0);
        builder.assign_variable(names[1], c1);
    }
}


impl CairoCodeAdder for Fq6 {
    fn add_circuit(&self, builder: &mut CairoCodeBuilder, names: Option<Vec<&str>>) {
        let names = names
            .filter(|v| v.len() >= 6)
            .unwrap_or(vec!["c0", "c1", "c2", "c3", "c4", "c5"]);

        let c0 = self.c0().c0().c0().format_circuit();
        let c1 = self.c0().c1().c0().format_circuit();
        let c2 = self.c1().c0().c0().format_circuit();
        let c3 = self.c1().c1().c0().format_circuit();
        let c4 = self.c2().c0().c0().format_circuit();
        let c5 = self.c2().c1().c0().format_circuit();

        builder.assign_variable(names[0], c0);
        builder.assign_variable(names[1], c1);
        builder.assign_variable(names[2], c2);
        builder.assign_variable(names[3], c3);
        builder.assign_variable(names[4], c4);
        builder.assign_variable(names[5], c5);
    }
}

impl CairoCodeAdder for Fq12 {
    fn add_circuit(&self, builder: &mut CairoCodeBuilder, names: Option<Vec<&str>>) {
        let names = names
            .filter(|v| v.len() >= 12)
            .unwrap_or(vec!["c0", "c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "c9", "c10", "c11"]);

        let c0 = self.c0().c0().c0().c0().format_circuit();
        let c1 = self.c0().c0().c1().c0().format_circuit();
        let c2 = self.c0().c1().c0().c0().format_circuit();
        let c3 = self.c0().c1().c1().c0().format_circuit();
        let c4 = self.c0().c2().c0().c0().format_circuit();
        let c5 = self.c0().c2().c1().c0().format_circuit();
        let c6 = self.c1().c0().c0().c0().format_circuit();
        let c7 = self.c1().c0().c1().c0().format_circuit();
        let c8 = self.c1().c1().c0().c0().format_circuit();
        let c9 = self.c1().c1().c1().c0().format_circuit();
        let c10 = self.c1().c2().c0().c0().format_circuit();
        let c11 = self.c1().c2().c1().c0().format_circuit();

        builder.assign_variable(names[0], c0);
        builder.assign_variable(names[1], c1);
        builder.assign_variable(names[2], c2);
        builder.assign_variable(names[3], c3);
        builder.assign_variable(names[4], c4);
        builder.assign_variable(names[5], c5);
        builder.assign_variable(names[6], c6);
        builder.assign_variable(names[7], c7);
        builder.assign_variable(names[8], c8);
        builder.assign_variable(names[9], c9);
        builder.assign_variable(names[10], c10);
        builder.assign_variable(names[11], c11);
    }
}

impl CairoCodeAdder for Affine<Fq> {
    fn add_circuit(&self, builder: &mut CairoCodeBuilder, names: Option<Vec<&str>>) {
        let names = names
        .filter(|v| v.len() >= 2)
        .unwrap_or(vec!["x0", "y0"]);
        
        let x0 = self.x().c0().format_circuit();
        let y0 = self.y().c0().format_circuit();
        
        builder.assign_variable(names[0], x0);
        builder.assign_variable(names[1], y0);
    }
}

impl CairoCodeAdder for Affine<Fq2> {
    fn add_circuit(&self, builder: &mut CairoCodeBuilder, names: Option<Vec<&str>>) {
        let names = names
        .filter(|v| v.len() >= 4)
        .unwrap_or(vec!["x0", "x1", "y0", "y1"]);

        let x0 = self.x().c0().c0().format_circuit();
        let x1 = self.x().c1().c0().format_circuit();
        let y0 = self.y().c0().c0().format_circuit();
        let y1 = self.y().c1().c0().format_circuit();
        
        builder.assign_variable(names[0], x0);
        builder.assign_variable(names[1], x1);    
        builder.assign_variable(names[2], y0);
        builder.assign_variable(names[3], y1);    

        // self.x().add_circuit(builder);
        // self.y().add_circuit(builder);
    }
}

impl CairoCodeAdder for Precompute {
    fn add_circuit(&self, builder: &mut CairoCodeBuilder, names: Option<Vec<&str>>) {
        let names = names
        .filter(|v| v.len() >= 12)
        .unwrap_or(vec!["p_x0", "p_y0", "q_x0", "q_x1", "q_y0", "q_y1", "nq_x0", "nq_x1", "nq_y0", "nq_y1", "neg_x_over_y", "y_inv"]);
        
        self.p().add_circuit(builder, Some(names[0..2].to_vec()));
        self.q().add_circuit(builder, Some(names[2..6].to_vec()));
        self.neg_q().add_circuit(builder, Some(names[6..10].to_vec()));
        self.ppc().neg_x_over_y().add_circuit(builder, Some(names[10..11].to_vec()));
        self.ppc().y_inv().add_circuit(builder, Some(names[10..12].to_vec()));

    }
}