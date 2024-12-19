use integer::u512;
use super::{mul_u, mul_nz};
use core::math::u256_inv_mod;
use core::circuit::{
    CircuitElement, CircuitInput, circuit_mul, circuit_inverse, EvalCircuitTrait, u384,
    CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs, EvalCircuitResult
};
use core::circuit::conversions::{from_u128, from_u256};

use plonk_verifier::curve::constants::FIELD_U384;

// Inversion
#[inline(always)]
fn inv(b: u256, modulo: NonZero<u256>) -> u256 {
    u256_inv_mod(b, modulo).expect('inversion failed').into()
}

#[inline(always)]
fn inv_circuit(b: u256) -> u256 {
    let r = CircuitElement::<CircuitInput<0>> {};
    let r_inv = circuit_inverse(r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let r = from_u256(b);

    let outputs = match (r_inv,).new_inputs().next(r).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(r_inv).try_into().unwrap();
    o
}

// Division with Non Zero
#[inline(always)]
fn div_nz(a: u256, b: u256, modulo_nz: NonZero<u256>) -> u256 {
    mul_nz(a, inv(b, modulo_nz), modulo_nz)
}

// Division unreduced
#[inline(always)]
fn div_u(a: u256, b: u256, modulo_nz: NonZero<u256>) -> u512 {
    mul_u(a, inv(b, modulo_nz))
}

// Division - Easy
#[inline(always)]
fn div(a: u256, b: u256, modulo: u256) -> u256 {
    let modulo_nz = modulo.try_into().expect('0 modulo');
    div_nz(a, b, modulo_nz)
}

#[inline(always)]
fn div_circuit(a: u256, b: u256) -> u256 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let r_inv = circuit_inverse(r);
    let div = circuit_mul(l, r_inv);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let l = from_u256(a);
    let r = from_u256(b);

    let outputs = match (div,).new_inputs().next(l).next(r).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(div).try_into().unwrap();
    o
}
