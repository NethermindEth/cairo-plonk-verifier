use core::traits::Into;
use core::byte_array::ByteArrayTrait;
use core::to_byte_array::FormatAsByteArray;
use core::integer::u128_byte_reverse;

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


fn reverse_endianness(value: u256) -> u256 {
    let new_low = u128_byte_reverse(value.high);
    let new_high = u128_byte_reverse(value.low);
    u256 { low: new_low, high: new_high }
}

// This helper function assumes that combining both low and high < u8
// It should always be true, therefore no error assert check needed
fn combine_low_and_high_u8_as_hex(low: u8, high: u8) -> u8 {
    low + high * 16
}

fn append_formatted_to_byte_array_as_hex(
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
