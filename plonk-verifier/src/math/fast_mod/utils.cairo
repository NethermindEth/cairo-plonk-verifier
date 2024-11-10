use core::num::traits::WrappingAdd;
use integer::{u128_overflowing_add, u128_overflowing_sub, u512};
use core::num::traits::{OverflowingAdd, OverflowingSub};
use core::circuit::{
    CircuitElement, CircuitInput, AddMod, circuit_add, circuit_sub, circuit_mul, circuit_inverse,
    EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs,
    EvalCircuitResult
};
use core::circuit::conversions::{from_u128, from_u256};
use core::num::traits::bounded::Bounded;

#[inline(always)]
fn u128_add_with_carry(a: u128, b: u128) -> (u128, u128) nopanic {
    match u128_overflowing_add(a, b) {
        Result::Ok(v) => (v, 0),
        Result::Err(v) => (v, 1),
    }
}

#[inline(always)]
fn u256_overflow_add(lhs: u256, rhs: u256) -> Result<u256, u256> implicits(RangeCheck) nopanic {
    let (high, overflow) = match u128_overflowing_add(lhs.high, rhs.high) {
        Result::Ok(high) => (high, false),
        Result::Err(high) => (high, true),
    };
    match u128_overflowing_add(lhs.low, rhs.low) {
        Result::Ok(low) => if overflow {
            Result::Err(u256 { low, high })
        } else {
            Result::Ok(u256 { low, high })
        },
        Result::Err(low) => {
            match u128_overflowing_add(high, 1_u128) {
                Result::Ok(high) => if overflow {
                    Result::Err(u256 { low, high })
                } else {
                    Result::Ok(u256 { low, high })
                },
                Result::Err(high) => Result::Err(u256 { low, high }),
            }
        },
    }
}

#[inline(always)]
fn u256_overflow_sub(lhs: u256, rhs: u256) -> Result<u256, u256> implicits(RangeCheck) nopanic {
    let (high, overflow) = match u128_overflowing_sub(lhs.high, rhs.high) {
        Result::Ok(high) => (high, false),
        Result::Err(high) => (high, true),
    };
    match u128_overflowing_sub(lhs.low, rhs.low) {
        Result::Ok(low) => if overflow {
            Result::Err(u256 { low, high })
        } else {
            Result::Ok(u256 { low, high })
        },
        Result::Err(low) => {
            match u128_overflowing_sub(high, 1_u128) {
                Result::Ok(high) => if overflow {
                    Result::Err(u256 { low, high })
                } else {
                    Result::Ok(u256 { low, high })
                },
                Result::Err(high) => Result::Err(u256 { low, high }),
            }
        },
    }
}


fn u256_circcuit_overflow_sub(lhs: u256, rhs: u256) -> u256 {
    let a = CircuitElement::<CircuitInput<0>> {};
    let b = CircuitElement::<CircuitInput<1>> {};
    let a_sub_b = circuit_sub(a, b);
    let u256_max = from_u256(Bounded::<u256>::MAX);
    let modulus = TryInto::<
        _, CircuitModulus
    >::try_into([u256_max.limb0, u256_max.limb1, u256_max.limb2, u256_max.limb3])
        .unwrap();
    let x1 = from_u256(lhs);
    let y1 = from_u256(rhs);

    let outputs = match (a_sub_b,).new_inputs().next(x1).next(y1).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    outputs.get_output(a_sub_b).try_into().unwrap()
}
#[inline(always)]
fn u256_wrapping_add(lhs: u256, rhs: u256) -> u256 implicits(RangeCheck) nopanic {
    let high = match u128_overflowing_add(lhs.high, rhs.high) {
        Result::Ok(high) => high,
        Result::Err(high) => high,
    };
    match u128_overflowing_add(lhs.low, rhs.low) {
        Result::Ok(low) => u256 { low, high },
        Result::Err(low) => {
            match u128_overflowing_add(high, 1_u128) {
                Result::Ok(high) => u256 { low, high },
                Result::Err(high) => u256 { low, high },
            }
        },
    }
}

#[inline(always)]
fn u256_wrapping_sub(lhs: u256, rhs: u256) -> u256 implicits(RangeCheck) nopanic {
    let high = match u128_overflowing_sub(lhs.high, rhs.high) {
        Result::Ok(high) => high,
        Result::Err(high) => high,
    };
    match u128_overflowing_sub(lhs.low, rhs.low) {
        Result::Ok(low) => u256 { low, high },
        Result::Err(low) => {
            match u128_overflowing_sub(high, 1_u128) {
                Result::Ok(high) => u256 { low, high },
                Result::Err(high) => u256 { low, high },
            }
        },
    }
}

#[inline(always)]
fn expect_u256(result: Result<u256, u256>, panic_msg: felt252) -> u256 {
    match result {
        Result::Ok(value) => value,
        Result::Err(value) => {
            panic_with_felt252(panic_msg);
            value
        },
    }
}

#[inline(always)]
fn expect_u128(result: Result<u128, u128>, panic_msg: felt252) -> u128 {
    match result {
        Result::Ok(value) => value,
        Result::Err(value) => {
            panic_with_felt252(panic_msg);
            value
        },
    }
}

use core::to_byte_array::AppendFormattedToByteArray;
use core::fmt::{Display, Formatter, Error};

impl u512Display of Display<u512> {
    fn fmt(self: @u512, ref f: Formatter) -> Result<(), Error> {
        let base = 16_u256.try_into().unwrap();
        write!(f, "\n0x").unwrap();
        u256 { high: *self.limb3, low: *self.limb2 }
            .append_formatted_to_byte_array(ref f.buffer, base);
        write!(f, ",0x").unwrap();
        u256 { high: *self.limb1, low: *self.limb0 }
            .append_formatted_to_byte_array(ref f.buffer, base);
        Result::Ok(())
    }
}

impl Tuple2Add<T1, T2, +Add<T1>, +Add<T2>, +Drop<T1>, +Drop<T2>> of Add<(T1, T2)> {
    #[inline(always)]
    fn add(lhs: (T1, T2), rhs: (T1, T2)) -> (T1, T2) {
        let (a0, a1) = lhs;
        let (b0, b1) = rhs;
        (a0 + b0, a1 + b1)
    }
}

impl Tuple2Sub<T1, T2, +Sub<T1>, +Sub<T2>, +Drop<T1>, +Drop<T2>> of Sub<(T1, T2)> {
    #[inline(always)]
    fn sub(lhs: (T1, T2), rhs: (T1, T2)) -> (T1, T2) {
        let (a0, a1) = lhs;
        let (b0, b1) = rhs;
        (a0 - b0, a1 - b1)
    }
}

impl Tuple3Add<
    T1, T2, T3, +Add<T1>, +Add<T2>, +Add<T3>, +Drop<T1>, +Drop<T2>, +Drop<T3>,
> of Add<(T1, T2, T3)> {
    #[inline(always)]
    fn add(lhs: (T1, T2, T3), rhs: (T1, T2, T3)) -> (T1, T2, T3) {
        let (a0, a1, a2) = lhs;
        let (b0, b1, b2) = rhs;
        (a0 + b0, a1 + b1, a2 + b2)
    }
}

impl Tuple3Sub<
    T1, T2, T3, +Sub<T1>, +Sub<T2>, +Sub<T3>, +Drop<T1>, +Drop<T2>, +Drop<T3>,
> of Sub<(T1, T2, T3)> {
    #[inline(always)]
    fn sub(lhs: (T1, T2, T3), rhs: (T1, T2, T3)) -> (T1, T2, T3) {
        let (a0, a1, a2) = lhs;
        let (b0, b1, b2) = rhs;
        (a0 - b0, a1 - b1, a2 - b2)
    }
}


fn u128_circuit_wrapping_add(lhs: u128, rhs: u128) -> u128 {
    let a = CircuitElement::<CircuitInput<0>> {};
    let b = CircuitElement::<CircuitInput<1>> {};
    let a_add_b = circuit_add(a, b);
    let u128_max = from_u128(Bounded::<u128>::MAX);
    let modulus = TryInto::<
        _, CircuitModulus
    >::try_into([u128_max.limb0, u128_max.limb1, u128_max.limb2, u128_max.limb3])
        .unwrap();
    let x1 = from_u128(lhs);
    let y1 = from_u128(rhs);

    let outputs = match (a_add_b,).new_inputs().next(x1).next(y1).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    outputs.get_output(a_add_b).try_into().unwrap()
}

fn u256_circuit_wrapping_add(lhs: u256, rhs: u256) -> u256 {
    let a = CircuitElement::<CircuitInput<0>> {};
    let b = CircuitElement::<CircuitInput<1>> {};
    let a_add_b = circuit_add(a, b);
    let u256_max = from_u256(Bounded::<u256>::MAX);
    let modulus = TryInto::<
        _, CircuitModulus
    >::try_into([u256_max.limb0, u256_max.limb1, u256_max.limb2, u256_max.limb3])
        .unwrap();
    let x1 = from_u256(lhs);
    let y1 = from_u256(rhs);

    let outputs = match (a_add_b,).new_inputs().next(x1).next(y1).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    outputs.get_output(a_add_b).try_into().unwrap()
}
