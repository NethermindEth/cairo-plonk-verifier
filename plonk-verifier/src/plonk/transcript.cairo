use core::{
    traits::{TryInto, Into, Destruct}, clone::Clone, fmt::{Display, Formatter, Error},
    byte_array::ByteArrayTrait, to_byte_array::{FormatAsByteArray, AppendFormattedToByteArray},
    keccak, circuit::conversions::from_u256
};
use debug::PrintTrait;

use plonk_verifier::{
    curve::{constants::{ORDER, ORDER_NZ}, groups::{AffineG1, AffineG2, g1, g2}},
    fields::{fq, Fq, FqIntoU256},
    plonk::utils::{
        byte_array_to_decimal_without_ascii_without_rev, convert_le_to_be, decimal_to_byte_array,
        hex_to_decimal, reverse_endianness,
    },
    math::circuit_mod::{add_co, zero_384}
};

#[derive(Drop)]
pub struct PlonkTranscript {
    data: Array<TranscriptElement<AffineG1, Fq>>
}

#[derive(Drop)]
enum TranscriptElement<AffineG1, Fq> {
    Polynomial: AffineG1,
    Scalar: Fq,
}

#[derive(Drop)]
trait Keccak256Transcript<T> {
    fn new() -> T;
    fn add_poly_commitment(ref self: T, polynomial_commitment: AffineG1);
    fn add_scalar(ref self: T, scalar: Fq);
    fn get_challenge(self: T) -> Fq;
}

#[derive(Drop)]
impl Transcript of Keccak256Transcript<PlonkTranscript> {
    fn new() -> PlonkTranscript {
        PlonkTranscript { data: ArrayTrait::new() }
    }
    fn add_poly_commitment(ref self: PlonkTranscript, polynomial_commitment: AffineG1) {
        self.data.append(TranscriptElement::Polynomial(polynomial_commitment));
    }

    fn add_scalar(ref self: PlonkTranscript, scalar: Fq) {
        self.data.append(TranscriptElement::Scalar(scalar));
    }

    fn get_challenge(mut self: PlonkTranscript) -> Fq {
        if 0 == self.data.len() {
            panic!("Keccak256Transcript: No data to generate a transcript");
        }

        let mut buffer: ByteArray = "";

        for i in 0
            ..self
                .data
                .len() {
                    match self.data.at(i) {
                        TranscriptElement::Polynomial(pt) => {
                            let x: u256 = (pt.x.c0.clone()).try_into().unwrap();
                            let y: u256 = (pt.y.c0.clone()).try_into().unwrap();
                            let mut x_bytes: ByteArray = decimal_to_byte_array(x);
                            let mut y_bytes: ByteArray = decimal_to_byte_array(y);
                            buffer.append(@x_bytes);
                            buffer.append(@y_bytes);
                        },
                        TranscriptElement::Scalar(scalar) => {
                            let s: u256 = (scalar.c0.clone()).try_into().unwrap();
                            let mut s_bytes: ByteArray = decimal_to_byte_array(s);
                            buffer.append(@s_bytes);
                        },
                    };
                };

        let le_value = keccak::compute_keccak_byte_array(@buffer);
        let be_u256 = reverse_endianness(le_value);
        let be_mod = add_co(from_u256(be_u256), zero_384);
        let challenge: Fq = fq(be_mod);

        challenge
    }
}
