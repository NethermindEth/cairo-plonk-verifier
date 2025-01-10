use core::circuit::{
    AddInputResultTrait, AddMod, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
    CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, circuit_add, circuit_inverse,
    circuit_mul, circuit_sub, u384,
};
use core::circuit::conversions::from_u128;

use plonk_verifier::curve::constants::{FIELD_U384, ORDER_U384};

const ZERO: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };
const ONE: u384 = u384 { limb0: 1, limb1: 0, limb2: 0, limb3: 0 };

// #[inline(always)]
fn add_c(mut a: u384, mut b: u384, m: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let add = circuit_add(l, r);

    let outputs = match (add,).new_inputs().next(a).next(b).done().eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(add);
    o
}

// #[inline(always)]
fn add_co(mut a: u384, mut b: u384, m_o: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let add = circuit_add(l, r);

    let outputs = match (add,).new_inputs().next(a).next(b).done().eval(m_o) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(add);
    o
}

// #[inline(always)]
fn sub_c(mut a: u384, mut b: u384, m: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let sub = circuit_sub(l, r);

    let outputs = match (sub,).new_inputs().next(a).next(b).done().eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(sub);
    o
}

// #[inline(always)]
fn sub_co(mut a: u384, mut b: u384, m_o: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let sub = circuit_sub(l, r);

    let outputs = match (sub,).new_inputs().next(a).next(b).done().eval(m_o) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(sub);
    o
}

// #[inline(always)]
fn neg_c(mut a: u384, m: CircuitModulus) -> u384 {
    let r = CircuitElement::<CircuitInput<0>> {};
    let zero = circuit_sub(r, r);
    let sub = circuit_sub(zero, r);

    //let zero = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    let outputs = match (sub,).new_inputs().next(a).done().eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(sub);
    o
}

// #[inline(always)]
fn neg_co(mut a: u384, m_o: CircuitModulus) -> u384 {
    let r = CircuitElement::<CircuitInput<0>> {};
    let zero = circuit_sub(r, r);
    let sub = circuit_sub(zero, r);

    //let zero = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    let outputs = match (sub,).new_inputs().next(a).done().eval(m_o) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(sub);
    o
}

// #[inline(always)]
fn inv_c(b: u384, m: CircuitModulus) -> u384 {
    let r = CircuitElement::<CircuitInput<0>> {};
    let r_inv = circuit_inverse(r);

    let outputs = match (r_inv,).new_inputs().next(b).done().eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(r_inv);
    o
}

// #[inline(always)]
fn div_c(a: u384, b: u384, m: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let r_inv = circuit_inverse(r);
    let div = circuit_mul(l, r_inv);

    let outputs = match (div,).new_inputs().next(a).next(b).done().eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(div);
    o
}

// #[inline(always)]
fn div_co(a: u384, b: u384, m_o: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let r_inv = circuit_inverse(r);
    let div = circuit_mul(l, r_inv);

    let outputs = match (div,).new_inputs().next(a).next(b).done().eval(m_o) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(div);
    o
}

// #[inline(always)]
fn mul_c(a: u384, b: u384, m: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let mul = circuit_mul(l, r);

    let outputs = match (mul,).new_inputs().next(a).next(b).done().eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul);
    o
}

// #[inline(always)]
fn mul_co(a: u384, b: u384, m_o: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let mul = circuit_mul(l, r);

    let outputs = match (mul,).new_inputs().next(a).next(b).done().eval(m_o) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul);
    o
}

// #[inline(always)]
fn scl_c(a: u384, b: u128, m: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let r = CircuitElement::<CircuitInput<1>> {};
    let mul = circuit_mul(l, r);

    let scalar = from_u128(b);

    let outputs = match (mul,).new_inputs().next(a).next(scalar).done().eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul);
    o
}

// #[inline(always)]
fn sqr_c(a: u384, m: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let mul = circuit_mul(l, l);

    let outputs = match (mul,).new_inputs().next(a).done().eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul);
    o
}

// #[inline(always)]
fn sqr_co(a: u384, m_o: CircuitModulus) -> u384 {
    let l = CircuitElement::<CircuitInput<0>> {};
    let mul = circuit_mul(l, l);

    let outputs = match (mul,).new_inputs().next(a).done().eval(m_o) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };

    let o = outputs.get_output(mul);
    o
}
