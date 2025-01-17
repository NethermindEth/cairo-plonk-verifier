use core::{
    circuit::{
        AddInputResultTrait, AddMod, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
        CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, circuit_add, circuit_inverse,
        circuit_mul, circuit_sub, u384, conversions::{from_u128, from_u256},
    },
    option::OptionTrait,
    traits::TryInto,
};

use plonk_verifier::curve::constants::{FIELD_U384, ORDER_U384};

mod constants;
mod groups;

use groups::{AffineG1, AffineG2};

mod pairing {
    mod optimal_ate_utils;
    mod optimal_ate_impls;
    mod optimal_ate;
    // #[cfg(test)]
    // mod ate_tests;
    // #[cfg(test)]
    // mod tests;
}

use plonk_verifier::fields as f;

// // #[inline(always)]
// fn scale_9(a: f::Fq) -> f::Fq {
//     // addchain for a to 9a
//     let a2 = a + a;
//     let a4 = a2 + a2;
//     a4 + a4 + a
// }

// #[inline(always)]
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
    let fq_a9 = f::Fq { c0: outputs.get_output(a9) };

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

    let t0_a2 = circuit_add(t0, t0);
    let t0_a4 = circuit_add(t0_a2, t0_a2);
    let t0_a8 = circuit_add(t0_a4, t0_a4);
    let t0_a9 = circuit_add(t0_a8, t0);

    let t1_a2 = circuit_add(t1, t1);
    let t1_a4 = circuit_add(t1_a2, t1_a2);
    let t1_a8 = circuit_add(t1_a4, t1_a4);
    let t1_a9 = circuit_add(t1_a8, t1);

    let t0_mul_9_sub_t1 = circuit_sub(t0_a9, t1);
    let t0_add_t1_mul_9 = circuit_add(t0, t1_a9);

    let t0 = t.c0.c0;
    let t1 = t.c1.c0;

    let outputs = match (t0_mul_9_sub_t1, t0_add_t1_mul_9,)
        .new_inputs()
        .next(t0)
        .next(t1)
        .done()
        .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
    };
    let fq2_c0 = f::Fq { c0: outputs.get_output(t0_mul_9_sub_t1) };
    let fq2_c1 = f::Fq { c0: outputs.get_output(t0_add_t1_mul_9) };
    let res = f::Fq2 { c0: fq2_c0, c1: fq2_c1 };
    res
}

// // #[inline(always)]
// fn mul_by_v(
//     t: ((u512, u512), (u512, u512), (u512, u512)),
// ) -> ((u512, u512), (u512, u512), (u512, u512)) {
//     // https://github.com/paritytech/bn/blob/master/src/fields/fq6.rs#L110
//     let (t0, t1, t2) = t;
//     (mul_by_xi(t2), t0, t1,)
// }

// // #[inline(always)]
// fn mul_by_v_nz(
//     t: ((u512, u512), (u512, u512), (u512, u512)), field_nz: NonZero<u256>
// ) -> ((u512, u512), (u512, u512), (u512, u512)) {
//     // https://github.com/paritytech/bn/blob/master/src/fields/fq6.rs#L110
//     let (t0, t1, t2) = t;
//     (mul_by_xi_nz(t2, field_nz), t0, t1)
// }

// #[inline(always)]
fn mul_by_v_nz_as_circuit(t: f::Fq6, m: CircuitModulus) -> f::Fq6 {
    let t0 = t.c0;
    let t1 = t.c1;
    let t2 = t.c2;

    f::Fq6 { c0: mul_by_xi_nz_as_circuit(t2, m), c1: t0, c2: t1 }
}