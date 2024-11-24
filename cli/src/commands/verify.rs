use crate::CliError;
use std::path::PathBuf;

pub fn verify(vk_path: &PathBuf, proof_path: &PathBuf, public_inputs_path: &PathBuf) -> Result<(), CliError> {
    if !vk_path.exists() {
        return Err(CliError::InvalidInput(format!(
            "Verification key file not found: {}",
            vk_path.display()
        )));
    }

    println!("Verifying proof with:");
    println!("  Verification Key: {}", vk_path.display());
    println!("  Proof: {}", proof_path.display());
    println!("  Public Inputs: {}", public_inputs_path.display());

    Ok(())
}
