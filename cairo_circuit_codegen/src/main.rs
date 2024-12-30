use std::fs;

use cairo_circuit_codegen::circuit::utils::generate_cairo_code;

fn main() {
    let code = generate_cairo_code();
    // Write the generated code to out.cairo
    fs::write("out.cairo", code).expect("Unable to write file");
    println!("Cairo code generated successfully and written to out.cairo");
}
