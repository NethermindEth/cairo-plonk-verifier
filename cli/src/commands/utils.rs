use crate::error::CliError;
use std::fs;
use std::path::Path;

pub fn read_json_file(path: &Path) -> Result<serde_json::Value, CliError> {
    let content = fs::read_to_string(path).map_err(|e| CliError::IoError(e.to_string()))?;

    serde_json::from_str(&content).map_err(|e| CliError::ParseError(e.to_string()))
}

pub fn validate_json_file(path: &Path) -> Result<(), CliError> {
    if !path.exists() {
        return Err(CliError::InvalidInput(format!(
            "File not found: {}",
            path.display()
        )));
    }

    // Try to read and parse as JSON to validate
    read_json_file(path)?;
    Ok(())
}

pub fn ensure_temp_dir() -> Result<(), CliError> {
    let temp_dir = Path::new("./data/temp");
    if !temp_dir.exists() {
        fs::create_dir_all(temp_dir)
            .map_err(|e| CliError::IoError(format!("Failed to create temp directory: {}", e)))?;
    }
    Ok(())
}

pub fn get_data_dir() -> Result<std::path::PathBuf, CliError> {
    let current_dir = std::env::current_dir()
        .map_err(|e| CliError::IoError(format!("Failed to get current directory: {}", e)))?;
    Ok(current_dir.join("data"))
}

pub fn get_temp_dir() -> Result<std::path::PathBuf, CliError> {
    Ok(get_data_dir()?.join("temp"))
}
