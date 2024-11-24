use std::fmt;

#[derive(Debug)]
pub enum CliError {
    IoError(std::io::Error),
    InvalidInput(String),
}

impl std::error::Error for CliError {}

impl fmt::Display for CliError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            CliError::IoError(e) => write!(f, "IO error: {}", e),
            CliError::InvalidInput(s) => write!(f, "Invalid input: {}", s),
        }
    }
}

