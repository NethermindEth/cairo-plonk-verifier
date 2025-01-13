use num_bigint::BigUint;
use num_traits::{One};
use primitive_types::U256;
use std::str::FromStr;

pub fn convert_u384_to_low_high(input: &str) -> (String, String) {
    // Parse the input decimal string into a BigUint
    let num = BigUint::from_str(input).expect("Invalid decimal input");

    // Define the 192-bit mask
    let mask_192 = (BigUint::one() << 192) - BigUint::one();

    // Get the low part (first 192 bits)
    let low = &num & &mask_192;

    // Get the high part (remaining bits above 192)
    let high: BigUint = &num >> 192;

    // Convert BigUint parts to decimal strings
    let low_string = low.to_str_radix(10);
    let high_string = high.to_str_radix(10);

    (low_string, high_string)
}

pub fn convert_u256_to_low_high(input: &str) -> (String, String) {
    // Parse the input decimal string into a U256
    let num = U256::from_dec_str(input).expect("Invalid decimal input");

    // Get low and high parts as u128
    let low_128 = num.low_u128(); // Lower 128 bits
    let high_128 = (num >> 128).low_u128(); // Upper 128 bits

    // Convert u128 values to decimal strings
    let low_string = low_128.to_string();
    let high_string = high_128.to_string();

    (low_string, high_string)
}
