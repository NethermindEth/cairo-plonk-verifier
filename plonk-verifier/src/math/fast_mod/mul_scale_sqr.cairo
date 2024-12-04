use core::traits::TryInto;
use integer::{u512, u128_wide_mul};
use core::num::traits::{WideMul};
use core::num::traits::{OverflowingAdd, OverflowingSub, WrappingAdd};

use u::{u128_circuit_wrapping_add};

use super::{utils as u, reduce, u512_reduce};
// scale u512 by u128 (for smaller numbers)
// unreduced, returns u512 plus u128 (fifth limb) which needs handling
#[inline(always)]
fn u512_scl(a: u512, x: u128) -> (u512, u128) {
    let u512 { limb0, limb1, limb2, limb3 } = a;

    let result0 = limb0.wide_mul(x);
    let result1 = limb1.wide_mul(x);
    let result2 = limb2.wide_mul(x);
    let result3 = limb3.wide_mul(x);

    let limb1 = result0.high.wrapping_add(result1.low);
    // let limb1 = u128_circuit_wrapping_add(result0.high, result1.low);
    let limb2 = result1.high.wrapping_add(result2.low);
    let limb3 = result2.high.wrapping_add(result3.low);
    let limb4 = result3.high;

    (u512 { limb0: result0.low, limb1, limb2, limb3 }, limb4)
}


// scale u256 by u128 (for smaller numbers)
// unreduced, returns u512
#[inline(always)]
fn scl_u(a: u256, b: u128) -> u512 {
    // (a1 + a2) * c
    let result1 = a.low.wide_mul(b);
    let result2 = a.high.wide_mul(b);
    let limb1 = result1.high.wrapping_add(result2.low);
    u512 { limb0: result1.low, limb1, limb2: result2.high, limb3: 0 }
}

// scale u256 by u128 (for smaller numbers)
// takes non zero modulo
// returns modded u256
#[inline(always)]
fn scl_nz(a: u256, b: u128, modulo: NonZero<u256>) -> u256 {
    u512_reduce(scl_u(a, b), modulo)
}

// scale u256 by u128 (for smaller numbers)
// returns modded u256
#[inline(always)]
fn scl(a: u256, b: u128, modulo: NonZero<u256>) -> u256 {
    scl_nz(a, b, modulo.try_into().unwrap())
}

// mul two u256
// unreduced, returns u512
#[inline(always)]
fn mul_u(a: u256, b: u256) -> u512 {
    let (limb1, limb0) = u128_wide_mul(a.low, b.low);
    let (limb2, limb1_part) = u128_wide_mul(a.low, b.high);
    let (limb1, limb1_overflow0) = u::u128_add_with_carry(limb1, limb1_part);
    let (limb2_part, limb1_part) = u128_wide_mul(a.high, b.low);
    let (limb1, limb1_overflow1) = u::u128_add_with_carry(limb1, limb1_part);
    let (limb2, limb2_overflow) = u::u128_add_with_carry(limb2, limb2_part);
    let (limb3, limb2_part) = u128_wide_mul(a.high, b.high);

    // No overflow since no limb4.
    let limb3 = limb3.wrapping_add(limb2_overflow);
    let (limb2, limb2_overflow) = u::u128_add_with_carry(limb2, limb2_part);
    // No overflow since no limb4.
    let limb3 = limb3.wrapping_add(limb2_overflow);
    // No overflow possible in this addition since both operands are 0/1.
    let limb1_overflow = limb1_overflow0.wrapping_add(limb1_overflow1);

    let (limb2, limb2_overflow) = u::u128_add_with_carry(limb2, limb1_overflow);
    // No overflow since no limb4.
    let limb3 = limb3.wrapping_add(limb2_overflow);

    u512 { limb0, limb1, limb2, limb3 }
}

// mul two u256
// takes non zero modulo
// returns modded u256
#[inline(always)]
fn mul_nz(a: u256, b: u256, modulo: NonZero<u256>) -> u256 {
    u512_reduce(mul_u(a, b), modulo)
}

// mul two u256
// returns modded u256
#[inline(always)]
fn mul(a: u256, b: u256, modulo: u256) -> u256 {
    mul_nz(a, b, modulo.try_into().unwrap())
}

// squares a u256
// unreduced, returns u512
#[inline(always)]
fn sqr_u(a: u256) -> u512 {
    let (limb1, limb0) = u128_wide_mul(a.low, a.low);
    let (limb2, limb1_part) = u128_wide_mul(a.low, a.high);
    let (limb1, limb1_overflow0) = u::u128_add_with_carry(limb1, limb1_part);
    let (limb1, limb1_overflow1) = u::u128_add_with_carry(limb1, limb1_part);
    let (limb2, limb2_overflow) = u::u128_add_with_carry(limb2, limb2);
    let (limb3, limb2_part) = u128_wide_mul(a.high, a.high);
    // No overflow since no limb4.
    let limb3 = limb3.wrapping_add(limb2_overflow);
    let (limb2, limb2_overflow) = u::u128_add_with_carry(limb2, limb2_part);
    // No overflow since no limb4.
    let limb3 = limb3.wrapping_add(limb2_overflow);
    // No overflow possible in this addition since both operands are 0/1.
    let limb1_overflow = limb1_overflow0.wrapping_add(limb1_overflow1);
    let (limb2, limb2_overflow) = u::u128_add_with_carry(limb2, limb1_overflow);
    // No overflow since no limb4.
    let limb3 = limb3.wrapping_add(limb2_overflow);
    u512 { limb0, limb1, limb2, limb3 }
}

// squares a u256
// takes non zero modulo
// returns modded u256
#[inline(always)]
fn sqr_nz(a: u256, modulo: NonZero<u256>) -> u256 {
    u512_reduce(sqr_u(a), modulo)
}

// squares a u256
// takes non zero modulo
// returns modded u256
#[inline(always)]
fn sqr(a: u256, modulo: u256) -> u256 {
    u512_reduce(sqr_u(a), modulo.try_into().unwrap())
}
