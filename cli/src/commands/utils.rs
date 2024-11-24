use std::path::Path;
use std::fs;
use crate::CliError;

pub fn read_json_file(path: &Path) -> Result<serde_json::Value, CliError> {
    let content = fs::read_to_string(path)
        .map_err(CliError::IoError)?;
    serde_json::from_str(&content)
        .map_err(|e| CliError::InvalidInput(e.to_string()))
}
