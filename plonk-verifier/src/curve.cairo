use core::option::OptionTrait;
use core::traits::TryInto;
use core::circuit::{
    CircuitElement, CircuitInput, AddMod, circuit_add, circuit_sub, circuit_mul, circuit_inverse,
    EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs,
    EvalCircuitResult
};
use plonk_verifier::curve::constants::{FIELD_U384, ORDER_U384};
use core::circuit::conversions::{from_u128, from_u256};
mod constants;
mod groups;

use groups::{AffineG1, AffineG2};

mod pairing {
    mod miller_utils;
    mod optimal_ate_utils;
    mod optimal_ate_impls;
    mod optimal_ate;
    // #[cfg(test)]
// mod ate_tests;
// #[cfg(test)]
// mod tests;
}

use plonk_verifier::fields as f;

// #[inline(always)]
// fn scale_9(a: f::Fq) -> f::Fq {
//     // addchain for a to 9a
//     let a2 = a + a;
//     let a4 = a2 + a2;
//     a4 + a4 + a
// }

#[inline(always)]
fn circuit_scale_9(a: f::Fq, m: CircuitModulus) -> f::Fq {
    // addchain for a to 9a
    let a_in = CircuitElement::<CircuitInput<0>> {};

    let a2 = circuit_add(a_in, a_in);
    let a4 = circuit_add(a2, a2);
    let a8 = circuit_add(a4, a4);
    let a9 = circuit_add(a8, a_in);
    let a_in = a.c0;
    let outputs = match (a9,).new_inputs().next(a_in).done().eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };
    let fq_a9 = f::Fq { c0: outputs.get_output(a9).try_into().unwrap() };

    fq_a9
}

// // ξ = 9 + i
// fn mul_by_xi(t: (u512, u512)) -> (u512, u512) {
//     let field_nz = get_field_nz();
//     let (t0, t1): (u512, u512) = t;
//     (u512_scl_9(t0, field_nz) - t1, //
//      t0 + u512_scl_9(t1, field_nz))
// }

// fn mul_by_xi_nz(t: (u512, u512), field_nz: NonZero<u256>) -> (u512, u512) {
//     let (t0, t1): (u512, u512) = t;
//     (u512_scl_9(t0, field_nz) - t1, //
//      t0 + u512_scl_9(t1, field_nz))
// }

fn mul_by_xi_nz_as_circuit(t: f::Fq2, m: CircuitModulus) -> f::Fq2 {
    let t0 = CircuitElement::<CircuitInput<0>> {};
    let t1 = CircuitElement::<CircuitInput<1>> {};
    let scl = CircuitElement::<CircuitInput<2>> {};

    let t0_mul_9 = circuit_mul(t0, scl);
    let t1_mul_9 = circuit_mul(t1, scl);
    let t0_mul_9_sub_t1 = circuit_sub(t0_mul_9, t1);
    let t0_add_t1_mul_9 = circuit_add(t0, t1_mul_9);

    let t0 = t.c0.c0;
    let t1 = t.c1.c0;
    let scl = [9, 0, 0, 0];

    let outputs =
        match (t0_mul_9_sub_t1, t0_add_t1_mul_9,)
            .new_inputs()
            .next(t0)
            .next(t1)
            .next(scl)
            .done()
            .eval(m) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };
    let fq2_c0 = f::Fq { c0: outputs.get_output(t0_mul_9_sub_t1).try_into().unwrap() };
    let fq2_c1 = f::Fq { c0: outputs.get_output(t0_add_t1_mul_9).try_into().unwrap() };
    let res = f::Fq2 { c0: fq2_c0, c1: fq2_c1 };
    res
}

// #[inline(always)]
// fn mul_by_v(
//     t: ((u512, u512), (u512, u512), (u512, u512)),
// ) -> ((u512, u512), (u512, u512), (u512, u512)) {
//     // https://github.com/paritytech/bn/blob/master/src/fields/fq6.rs#L110
//     let (t0, t1, t2) = t;
//     (mul_by_xi(t2), t0, t1,)
// }

// #[inline(always)]
// fn mul_by_v_nz(
//     t: ((u512, u512), (u512, u512), (u512, u512)), field_nz: NonZero<u256>
// ) -> ((u512, u512), (u512, u512), (u512, u512)) {
//     // https://github.com/paritytech/bn/blob/master/src/fields/fq6.rs#L110
//     let (t0, t1, t2) = t;
//     (mul_by_xi_nz(t2, field_nz), t0, t1)
// }


#[inline(always)]
fn mul_by_v_nz_as_circuit(t: f::Fq6, m: CircuitModulus) -> f::Fq6 {
    let t0 = t.c0;
    let t1 = t.c1;
    let t2 = t.c2;

    f::Fq6 { c0: mul_by_xi_nz_as_circuit(t2, m), c1: t0, c2: t1 }
}