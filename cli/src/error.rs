use std::error::Error;
use std::fmt;

#[derive(Debug)]
pub enum CliError {
    IoError(String),
    ParseError(String),
    VerificationError(String),
    InvalidInput(String),
}

impl fmt::Display for CliError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            CliError::IoError(msg) => write!(f, "IO Error: {}", msg),
            CliError::ParseError(msg) => write!(f, "Parse Error: {}", msg),
            CliError::VerificationError(msg) => write!(f, "Verification Error: {}", msg),
            CliError::InvalidInput(msg) => write!(f, "Invalid Input: {}", msg),
        }
    }
}

impl Error for CliError {}

impl From<std::io::Error> for CliError {
    fn from(err: std::io::Error) -> Self {
        CliError::IoError(err.to_string())
    }
}

impl From<serde_json::Error> for CliError {
    fn from(err: serde_json::Error) -> Self {
        CliError::ParseError(err.to_string())
    }
}
