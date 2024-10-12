use core::traits::Into;
use core::byte_array::ByteArrayTrait;
use core::to_byte_array::FormatAsByteArray;

fn convert_le_to_be(le: u256) -> ByteArray {
    let hex_base: NonZero<u256> = 16_u256.try_into().unwrap();
    let mut le = le.format_as_byte_array(hex_base);

    if le.len() < 64 {
        le = left_padding_32_bytes(le);
    }
    let mut rev_le: ByteArray = le.rev();
    let mut be_ba: ByteArray = "";

    let mut i = 0;
    while i < rev_le.len() {
        let mut word: ByteArray = "";

        word.append_byte(rev_le[i]);
        word.append_byte(rev_le[i + 1]);

        let rev: ByteArray = word.rev();
        be_ba.append(@rev);
        i += 2;
    };

    be_ba
}

fn left_padding_32_bytes(ba_in: ByteArray) -> ByteArray {
    let mut ba_len = ba_in.len();
    let mut ba_out: ByteArray = ba_in;
    let mut i = 0;

    while i < 64 - ba_len {
        let ba = ByteArrayTrait::concat(@"0", @ba_out);
        ba_out = ba;
        i += 1;
    };

    ba_out
}

// converts a big endian hexadecial byte array to u256 decimal
fn hex_to_decimal(mut hex_string: ByteArray) -> u256 {
    let mut result: u256 = 0;
    let mut power: u256 = 1;
    let mut i = 0;
    hex_string = hex_string.rev();

    while i < hex_string.len() {
        let byte_ascii_value = hex_string[i];
        let mut byte_value = ascii_to_dec(byte_ascii_value);
        let u256_byte_value: u256 = byte_value.into();

        result += u256_byte_value * power;
        if i != hex_string.len() - 1 {
            power *= 16;
        }
        i += 1;
    };
    result
}

// Converts a ByteArray into Ascii without reversing the ByteArray and without converting to ASCII
fn byte_array_to_decimal_without_ascii_without_rev(mut hex_string: ByteArray) -> u256 {
    let mut result: u256 = 0;
    let mut power: u256 = 1;
    let mut i = 0;
    hex_string = hex_string.rev();

    while i < hex_string.len() {
        let u256_byte_value: u256 = hex_string[i].into();

        result += u256_byte_value * power;
        if i != hex_string.len() - 1 {
            power *= 16;
        }
        i += 1;
    };
    result
}

fn decimal_to_byte_array(mut n: u256) -> ByteArray {
    let mut byte_array: ByteArray = "";
    append_formatted_to_byte_array_as_hex(@n, ref byte_array, 16_u256.try_into().unwrap());
    byte_array
}

fn decimal_to_byte_array_reverse_order(mut n: u256) -> ByteArray {
    let mut byte_array: ByteArray = "";
    append_formatted_to_byte_array_as_hex_reversed(@n, ref byte_array, 16_u256.try_into().unwrap());
    byte_array
}

fn ascii_to_dec(mut b: u8) -> u32 {
    let mut b_32: u32 = b.into();
    let mut byte_value = 0;
    if b_32 >= 97 {
        byte_value = b_32 - 87;
    } else {
        byte_value = b_32 - 48;
    }
    byte_value
}

// This helper function assumes that combining both low and high < u8
// It should always be true, therefore no error assert check needed
fn combine_low_and_high_u8_as_hex(low: u8, high: u8) -> u8 { 
    low + high * 16
}

// Modified function from to_byte_array.cairo
// Instead of converting to ascii representation, this function outputs as hex directly 
// This function will also pad to 32 bytes exactly 
// Example: 12979393775570966734443646882391122404847230034748025975999327462158755419776 = 0x1CB213983ED3C1451CB34F509B4D8316669BA852020544183E3415F9659BD680
// Returns: [1C,B2,13,98,3E,D3,C1,45,1C,B3,4F,50,9B,4D,83,16,66,9B,A8,52,02,05,44,18,3E,34,15,F9,65,9B,D6,80]
fn append_formatted_to_byte_array_as_hex
(
    mut value: @u256, ref byte_array: ByteArray, base_nz: NonZero<u256>,
) {
    let base: u256 = base_nz.into(); 
    assert(base == 16, 'base must be == 16');

    let mut reversed_digits = array![];

    loop {
        let (new_value, digit) = DivRem::div_rem(*value, base_nz);
        value = @new_value;
        let digit_as_u8_low: u8 = digit.try_into().unwrap();

        let (new_value, digit) = DivRem::div_rem(*value, base_nz);
        value = @new_value;
        let digit_as_u8_high: u8 = digit.try_into().unwrap();

        reversed_digits.append(combine_low_and_high_u8_as_hex(digit_as_u8_low, digit_as_u8_high));
        if (*value).is_zero() {
            break;
        };
    };
    
    // Pad to 32 bytes
    for _ in 0..32 - reversed_digits.len() {
        reversed_digits.append(0); 
    };

    // Reverse to change back to original endianness
    let mut span = reversed_digits.span();
    loop {
        match span.pop_back() {
            Option::Some(byte) => { byte_array.append_byte(*byte); },
            Option::None => { break; },
        };
    };
}

// Same function as append_formatted_to_byte_array_as_hex but does not reverse in order to change endianness
// and returns the bytes as separated indices 
// Pads to 64 bytes
// Example: 12979393775570966734443646882391122404847230034748025975999327462158755419776 = 0x1CB213983ED3C1451CB34F509B4D8316669BA852020544183E3415F9659BD680
// Returns: [8,0,D,6,9,B,6,5,F,9,1,5,3,4,3,E,1,8,4,4,0,5,0,2,5,2,A,8,9,B,6,6,1,6,8,3,4,D,9,B,5,0,4,F,B,3,1,C,4,5,C,1,D,3,3,E,9,8,1,3,B,2,1,C]
fn append_formatted_to_byte_array_as_hex_reversed
(
    mut value: @u256, ref byte_array: ByteArray, base_nz: NonZero<u256>,
) {
    let base: u256 = base_nz.into(); 
    assert(base == 16, 'base must be == 16');

    loop {
        let (new_value, digit) = DivRem::div_rem(*value, base_nz);
        value = @new_value;
        let digit_as_u8_low: u8 = digit.try_into().unwrap();

        let (new_value, digit) = DivRem::div_rem(*value, base_nz);
        value = @new_value;
        let digit_as_u8_high: u8 = digit.try_into().unwrap();

        byte_array.append_byte(digit_as_u8_high);
        byte_array.append_byte(digit_as_u8_low);

        if (*value).is_zero() {
            break;
        };
    };
    
    for _ in 0..64 - byte_array.len() {
        byte_array.append_byte(0); 
    };
}

