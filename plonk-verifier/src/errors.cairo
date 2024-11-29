use core::result::Result;
use core::result::Result::{Ok, Err};

#[derive(Drop)]
enum PlonkError {
    InvalidCurvePoint: felt252,
    InvalidFieldElement: felt252,
    InvalidPublicInput: felt252,
    VerificationFailed: felt252,
    TranscriptError: felt252,
}

type Result<T> = core::result::Result<T, PlonkError>;

// Helper functions for validation
fn validate_curve_point(is_valid: bool, error_msg: felt252) -> Result<()> {
    if !is_valid {
        Err(PlonkError::InvalidCurvePoint(error_msg))
    } else {
        Ok(())
    }
}

fn validate_field_element(is_valid: bool, error_msg: felt252) -> Result<()> {
    if !is_valid {
        Err(PlonkError::InvalidFieldElement(error_msg))
    } else {
        Ok(())
    }
}

fn validate_public_input(is_valid: bool, error_msg: felt252) -> Result<()> {
    if !is_valid {
        Err(PlonkError::InvalidPublicInput(error_msg))
    } else {
        Ok(())
    }
}

fn validate_verification(is_valid: bool, error_msg: felt252) -> Result<()> {
    if !is_valid {
        Err(PlonkError::VerificationFailed(error_msg))
    } else {
        Ok(())
    }
}
