use std::fs;

pub fn write_stdout(path: &str, code: String) {
    fs::write(path, code).expect("Unable to write file");
    println!("Cairo code generated successfully and written to out.cairo");
}