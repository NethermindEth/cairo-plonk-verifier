use core::circuit::{
    CircuitElement, CircuitInput, AddMod, circuit_add, circuit_sub, circuit_mul, circuit_inverse,
    EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs,
    EvalCircuitResult
};
use core::circuit::conversions::{from_u128};

use plonk_verifier::curve::constants::{FIELD_U384, ORDER_U384};

const zero_384: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };
const one_384: u384 = u384 { limb0: 1, limb1: 0, limb2: 0, limb3: 0 };

#[inline(always)]
fn add_c(mut a: u384, mut b: u384, modulus: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let add = circuit_add(l, r);

    let outputs = match (add,).new_inputs().next(a).next(b).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(add).try_into().unwrap();
    o
}

#[inline(always)]
fn add_co(mut a: u384, mut b: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let add = circuit_add(l, r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(ORDER_U384).unwrap();

    let outputs = match (add,).new_inputs().next(a).next(b).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(add).try_into().unwrap();
    o
}

#[inline(always)]
fn sub_c(mut a: u384, mut b: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let sub = circuit_sub(l, r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let outputs = match (sub,).new_inputs().next(a).next(b).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(sub).try_into().unwrap();
    o
}

#[inline(always)]
fn sub_co(mut a: u384, mut b: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let sub = circuit_sub(l, r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(ORDER_U384).unwrap();

    let outputs = match (sub,).new_inputs().next(a).next(b).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(sub).try_into().unwrap();
    o
}

fn neg_c(mut a: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let sub = circuit_sub(l, r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let zero = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    let outputs = match (sub,).new_inputs().next(zero).next(a).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(sub).try_into().unwrap();
    o
}


fn neg_co(mut a: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let sub = circuit_sub(l, r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(ORDER_U384).unwrap();

    let zero = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    let outputs = match (sub,).new_inputs().next(zero).next(a).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(sub).try_into().unwrap();
    o
}

fn inv_c(b: u384) -> u384 {
    let r = CircuitElement::<CircuitInput<0>> {};
    let r_inv = circuit_inverse(r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let outputs = match (r_inv,).new_inputs().next(b).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(r_inv).try_into().unwrap();
    o
}

fn div_c(a: u384, b: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let r_inv = circuit_inverse(r);
    let div = circuit_mul(l, r_inv);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let outputs = match (div,).new_inputs().next(a).next(b).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(div).try_into().unwrap();
    o
}

fn div_co(a: u384, b: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let r_inv = circuit_inverse(r);
    let div = circuit_mul(l, r_inv);

    let modulus = TryInto::<_, CircuitModulus>::try_into(ORDER_U384).unwrap();

    let outputs = match (div,).new_inputs().next(a).next(b).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(div).try_into().unwrap();
    o
}

fn mul_c(a: u384, b: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let mul = circuit_mul(l, r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let outputs = match (mul,).new_inputs().next(a).next(b).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul).try_into().unwrap();
    o
}

fn mul_co(a: u384, b: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let mul = circuit_mul(l, r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(ORDER_U384).unwrap();

    let outputs = match (mul,).new_inputs().next(a).next(b).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul).try_into().unwrap();
    o
}

fn scl_c(a: u384, b: u128) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let mul = circuit_mul(l, r);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let scalar = from_u128(b);

    let outputs = match (mul,).new_inputs().next(a).next(scalar).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul).try_into().unwrap();
    o
}


fn sqr_c(a: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let mul = circuit_mul(l, l);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let outputs = match (mul,).new_inputs().next(a).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul).try_into().unwrap();
    o
}

fn sqr_co(a: u384) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let mul = circuit_mul(l, l);

    let modulus = TryInto::<_, CircuitModulus>::try_into(ORDER_U384).unwrap();

    let outputs = match (mul,).new_inputs().next(a).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul).try_into().unwrap();
    o
}
