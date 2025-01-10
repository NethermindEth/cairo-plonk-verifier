use core::{
    byte_array::ByteArrayTrait,
    integer::u128_byte_reverse,
    to_byte_array::FormatAsByteArray,
    traits::Into,
};
use core::circuit::{CircuitModulus, u384}; 

use plonk_verifier::curve::{
    constants::FIELD_U384,
    groups::{AffineG1, AffineG2, AffineG2Impl, ECOperationsCircuitFq, g2},
};
use plonk_verifier::fields::{fq12, Fq12};

// // Serde for group points todo:(optimize - last u96 points of each u384 may be unused)
// // Serialize
// fn ser_miller(g1: AffineG1, g2: AffineG2, m: u384) -> Array<felt252> {
//     let mut arr: Array<felt252> = array![];
//     ser_g1(ref arr, g1);
//     ser_g2(ref arr, g2);
//     ser_mod(ref arr, m); 

//     arr
// }

// // Affine G1 ([u96;8])
// fn ser_g1(ref self: Array<felt252>, g1: AffineG1) {
//     self.append(g1.x.c0.limb0.try_into().unwrap());
//     self.append(g1.x.c0.limb1.try_into().unwrap());
//     self.append(g1.x.c0.limb2.try_into().unwrap());
//     self.append(g1.x.c0.limb3.try_into().unwrap());

//     self.append(g1.y.c0.limb0.try_into().unwrap());
//     self.append(g1.y.c0.limb1.try_into().unwrap());
//     self.append(g1.y.c0.limb2.try_into().unwrap());
//     self.append(g1.y.c0.limb3.try_into().unwrap());
// }

// // Affine G2 ([u96;16])
// fn ser_g2(ref self: Array<felt252>, g2: AffineG2) {
//     self.append(g2.x.c0.c0.limb0.try_into().unwrap());
//     self.append(g2.x.c0.c0.limb1.try_into().unwrap());
//     self.append(g2.x.c0.c0.limb2.try_into().unwrap());
//     self.append(g2.x.c0.c0.limb3.try_into().unwrap());

//     self.append(g2.x.c1.c0.limb0.try_into().unwrap());
//     self.append(g2.x.c1.c0.limb1.try_into().unwrap());
//     self.append(g2.x.c1.c0.limb2.try_into().unwrap());
//     self.append(g2.x.c1.c0.limb3.try_into().unwrap());

//     self.append(g2.y.c0.c0.limb0.try_into().unwrap());
//     self.append(g2.y.c0.c0.limb1.try_into().unwrap());
//     self.append(g2.y.c0.c0.limb2.try_into().unwrap());
//     self.append(g2.y.c0.c0.limb3.try_into().unwrap());

//     self.append(g2.y.c1.c0.limb0.try_into().unwrap());
//     self.append(g2.y.c1.c0.limb1.try_into().unwrap());
//     self.append(g2.y.c1.c0.limb2.try_into().unwrap());
//     self.append(g2.y.c1.c0.limb3.try_into().unwrap());
// }

// // Circuit Modulus ([u96;4])
// fn ser_mod(ref self: Array<felt252>, m: u384) {
//     self.append(m.limb0.try_into().unwrap());
//     self.append(m.limb1.try_into().unwrap());
//     self.append(m.limb2.try_into().unwrap());
//     self.append(m.limb3.try_into().unwrap());
// }

// // Deserialize 

// // Fq12
// fn des_fq12(ref self: Span<felt252>) -> Fq12 {
//     let c0 = u384 {
//         limb0: self.at(0).clone().try_into().unwrap(), 
//         limb1: self.at(1).clone().try_into().unwrap(), 
//         limb2: self.at(2).clone().try_into().unwrap(), 
//         limb3: self.at(3).clone().try_into().unwrap() 
//     };
//     let c1 = u384 {
//         limb0: self.at(4).clone().try_into().unwrap(), 
//         limb1: self.at(5).clone().try_into().unwrap(), 
//         limb2: self.at(6).clone().try_into().unwrap(), 
//         limb3: self.at(7).clone().try_into().unwrap() 
//     };
//     let c2 = u384 {
//         limb0: self.at(8).clone().try_into().unwrap(), 
//         limb1: self.at(9).clone().try_into().unwrap(), 
//         limb2: self.at(10).clone().try_into().unwrap(), 
//         limb3: self.at(11).clone().try_into().unwrap() 
//     };
//     let c3 = u384 {
//         limb0: self.at(12).clone().try_into().unwrap(), 
//         limb1: self.at(13).clone().try_into().unwrap(), 
//         limb2: self.at(14).clone().try_into().unwrap(), 
//         limb3: self.at(15).clone().try_into().unwrap() 
//     };

//     let c4 = u384 {
//         limb0: self.at(16).clone().try_into().unwrap(), 
//         limb1: self.at(17).clone().try_into().unwrap(), 
//         limb2: self.at(18).clone().try_into().unwrap(), 
//         limb3: self.at(19).clone().try_into().unwrap() 
//     };
//     let c5 = u384 {
//         limb0: self.at(20).clone().try_into().unwrap(), 
//         limb1: self.at(21).clone().try_into().unwrap(), 
//         limb2: self.at(22).clone().try_into().unwrap(), 
//         limb3: self.at(23).clone().try_into().unwrap() 
//     };
//     let c6 = u384 {
//         limb0: self.at(24).clone().try_into().unwrap(), 
//         limb1: self.at(25).clone().try_into().unwrap(), 
//         limb2: self.at(26).clone().try_into().unwrap(), 
//         limb3: self.at(27).clone().try_into().unwrap() 
//     };
//     let c7 = u384 {
//         limb0: self.at(28).clone().try_into().unwrap(), 
//         limb1: self.at(29).clone().try_into().unwrap(), 
//         limb2: self.at(30).clone().try_into().unwrap(), 
//         limb3: self.at(31).clone().try_into().unwrap() 
//     };

//     let c8 = u384 {
//         limb0: self.at(32).clone().try_into().unwrap(), 
//         limb1: self.at(33).clone().try_into().unwrap(), 
//         limb2: self.at(34).clone().try_into().unwrap(), 
//         limb3: self.at(35).clone().try_into().unwrap() 
//     };
//     let c9 = u384 {
//         limb0: self.at(36).clone().try_into().unwrap(), 
//         limb1: self.at(37).clone().try_into().unwrap(), 
//         limb2: self.at(38).clone().try_into().unwrap(), 
//         limb3: self.at(39).clone().try_into().unwrap() 
//     };
//     let c10 = u384 {
//         limb0: self.at(40).clone().try_into().unwrap(), 
//         limb1: self.at(41).clone().try_into().unwrap(), 
//         limb2: self.at(42).clone().try_into().unwrap(), 
//         limb3: self.at(43).clone().try_into().unwrap() 
//     };
//     let c11 = u384 {
//         limb0: self.at(44).clone().try_into().unwrap(), 
//         limb1: self.at(45).clone().try_into().unwrap(), 
//         limb2: self.at(46).clone().try_into().unwrap(), 
//         limb3: self.at(47).clone().try_into().unwrap() 
//     };
    
//     fq12(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11)
// }

// // Affine G1 ([u96;8])

// // Affine G2 ([u96;16])

// // Circuit Modulus ([u96;4])
// fn des_mod(ref self: Array<felt252>) -> u384 {
//     u384 {
//         limb0: self.pop_front().unwrap().clone().try_into().unwrap(), 
//         limb1: self.pop_front().unwrap().clone().try_into().unwrap(), 
//         limb2: self.pop_front().unwrap().clone().try_into().unwrap(), 
//         limb3: self.pop_front().unwrap().clone().try_into().unwrap() 
//     }
// }

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