use std::fs;
use sysinfo::{System, SystemExt};

use cairo_circuit_codegen::circuit::utils::{generate_fq12_field_ops, generate_fq6_field_ops, generate_step_dbl_add};

fn main() {
    let mut system = System::new_all();
    system.refresh_all();

    // let code = generate_fq12_field_ops();
    let code = generate_step_dbl_add();

    // Write the generated code to out.cairo
    
    println!("Total memory: {} KB", system.total_memory());
    println!("Used memory: {} KB", system.used_memory());
    println!("Free memory: {} KB", system.free_memory());

    fs::write("out.cairo", code).expect("Unable to write file");
    println!("Cairo code generated successfully and written to out.cairo");

    
}



