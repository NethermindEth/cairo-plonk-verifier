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

use constants::{
    T, ORDER, ORDER_NZ, get_order_nz, FIELD, FIELD_NZ, get_field_nz, FIELD_X2, FIELDSQLOW,
    FIELDSQHIGH, U256_MOD_FIELD, U256_MOD_FIELD_INV, B, t_naf
};
use constants::{ATE_LOOP_COUNT, LOG_ATE_LOOP_COUNT, six_t_plus_2_naf_rev_trimmed};
// use plonk_verifier::fields::print::u512Display;
use groups::{AffineG1, AffineG2};

// #[cfg(test)]
// mod groups_tests;

mod pairing {
    mod miller_utils;
    mod tate_bkls;
    mod optimal_ate_utils;
    mod optimal_ate_impls;
    mod optimal_ate;
    // #[cfg(test)]
// mod ate_tests;
// #[cfg(test)]
// mod tests;
}

use plonk_verifier::fields as f;
// use plonk_verifier::math::fast_mod as m;
// use m::{u512};
// use m::utils::u128_overflowing_sub;
// use m::{
//     add_u, add_nz, sub, sub_u, mul_u, mul_nz, div_nz, sqr_u, sqr_nz, scl_u, reduce, u512_add,
//     u512_sub
// };
// use m::{u512_add_u256, u512_sub_u256, u512_add_overflow, u512_sub_overflow, u512_scl, u512_reduce};
// use m::{Tuple2Add, Tuple2Sub, Tuple3Add, Tuple3Sub};
// use f::{SixU512};

#[inline(always)]
fn scale_9(a: f::Fq) -> f::Fq {
    // addchain for a to 9a
    let a2 = a + a;
    let a4 = a2 + a2;
    a4 + a4 + a
}
#[inline(always)]
fn circuit_scale_9(a: f::Fq) -> f::Fq {
    // addchain for a to 9a
    let a_in = CircuitElement::<CircuitInput<0>> {};

    let a2 = circuit_add(a_in, a_in);
    let a4 = circuit_add(a2, a2);
    let a8 = circuit_add(a4, a4);
    let a9 = circuit_add(a8, a_in);
    let a_in = a.c0;
    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    let outputs = match (a9,).new_inputs().next(a_in).done().eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };
    let fq_a9 = f::Fq { c0: outputs.get_output(a9).try_into().unwrap() };

    fq_a9
}


// #[inline(always)]
// fn u512_high_add(lhs: u512, rhs: u256) -> u512 {
//     m::u512_high_add(lhs, rhs).expect('u512_high_add overflow')
// }

// #[inline(always)]
// fn u512_high_sub(lhs: u512, rhs: u256) -> u512 {
//     m::u512_high_sub(lhs, rhs).expect('u512_high_sub overflow')
// }

// trait UAddSubTrait<T> {
//     fn u_add(self: T, rhs: T) -> T;
//     fn u_sub(self: T, rhs: T) -> T;
// }

// impl U512Ops of UAddSubTrait<u512> {
//     #[inline(always)]
//     fn u_add(self: u512, rhs: u512) -> u512 {
//         u512_add(self, rhs)
//     }

//     #[inline(always)]
//     fn u_sub(self: u512, rhs: u512) -> u512 {
//         u512_sub(self, rhs)
//     }
// }

// impl U512Fq2Ops of UAddSubTrait<(u512, u512)> {
//     #[inline(always)]
//     fn u_add(self: (u512, u512), rhs: (u512, u512)) -> (u512, u512) {
//         let (L0, L1) = self;
//         let (R0, R1) = rhs;
//         // Operation without modding can only be done like 4 times
//         (u512_add(L0, R0), u512_add(L1, R1))
//     }

//     #[inline(always)]
//     fn u_sub(self: (u512, u512), rhs: (u512, u512)) -> (u512, u512) {
//         let (L0, L1) = self;
//         let (R0, R1) = rhs;
//         // Operation without modding can only be done like 4 times
//         (u512_sub(L0, R0), u512_sub(L1, R1))
//     }
// }

// impl U512Fq6Ops of UAddSubTrait<SixU512> {
//     #[inline(always)]
//     fn u_add(self: SixU512, rhs: SixU512) -> SixU512 {
//         let (L0, L1, L2) = self;
//         let (R0, R1, R2) = rhs;
//         // Operation without modding can only be done like 4 times
//         (L0.u_add(R0), L1.u_add(R1), L2.u_add(R2))
//     }

//     #[inline(always)]
//     fn u_sub(self: SixU512, rhs: SixU512) -> SixU512 {
//         let (L0, L1, L2) = self;
//         let (R0, R1, R2) = rhs;
//         // Operation without modding can only be done like 4 times
//         (L0.u_sub(R0), L1.u_sub(R1), L2.u_sub(R2))
//     }
// }

// // This fixes mod breaking u128 overflow
// // Tell this guy what's safe to add or subtract
// // And it will proceed optimally avoiding overflow
// #[inline(always)]
// fn fix_overflow(result: u256, sub: u256, add: u256) -> u256 {
//     match u128_overflowing_sub(sub.high, result.high) {
//         // If sub >= result, then we add
//         Result::Ok(_) => m::u256_overflow_add(result, add).expect('fix overflow add failed'),
//         // If sub < result, then we subtract
//         Result::Err(_) => m::u256_overflow_sub(result, sub).expect('fix overflow sub failed'),
//     }
// }

// // This fixes mod breaking u128 overflow
// // Tell this guy what's safe to add or subtract
// // And it will proceed optimally avoiding overflow
// #[inline(always)]
// fn fix_overflow_u512(result: u512, sub: u256, add: u256) -> u512 {
//     let u512 { limb0, limb1, limb2, limb3 } = result;
//     let u512_high = u256 { low: limb2, high: limb3 };
//     let u256 { low: limb2, high: limb3 } = fix_overflow(u512_high, sub, add);
//     u512 { limb0, limb1, limb2, limb3 }
// }

// #[inline(always)]
// fn add_u_wrapping(lhs: u256, rhs: u256) -> u256 {
//     match m::u256_overflow_add(lhs, rhs) {
//         Result::Ok(res) => res,
//         Result::Err(res) => fix_overflow(res, U256_MOD_FIELD_INV, U256_MOD_FIELD),
//     }
// }

// impl U512BnAdd of Add<u512> {
//     // Adds u512 for bn field
//     fn add(lhs: u512, rhs: u512) -> u512 {
//         let (result, overflow) = u512_add_overflow(lhs, rhs);
//         if overflow {
//             // 278 % 61 = 34
//             // (278 - 256) + (256 % 61) % 61 = 34
//             // OR, ((x - a) + (a % b)) % b == x % b
//             // For `a` as `2**256` and `b` as `FIELD` and overflow `result` as `x - a`
//             // result + (2**256 % FIELD) fixes overflow error
//             // U256_MOD_FIELD is precompute of 2**256 % FIELD
//             // So we can either add U256_MOD_FIELD or subtract U256_MOD_FIELD_INV
//             fix_overflow_u512(result, U256_MOD_FIELD_INV, U256_MOD_FIELD)
//         } else {
//             result
//         }
//     }
// }

// impl U512BnSub of Sub<u512> {
//     // Subtracts u512 for bn field
//     fn sub(lhs: u512, rhs: u512) -> u512 {
//         let (result, overflow) = u512_sub_overflow(lhs, rhs);
//         if overflow {
//             // -13 % 61 = 48
//             // (100 + -13) - (100 % 61) % 61 = 52
//             // ((x + a) - (a % b)) % b == x % b
//             // So, subbing `a` as `2**256` and `b` as `FIELD`, `x + a` as `result`
//             // result - (2**256 % FIELD) fixes overflow error
//             // U256_MOD_FIELD is precompute of 2**256 % FIELD
//             // So we can either subtract U256_MOD_FIELD or add U256_MOD_FIELD
//             fix_overflow_u512(result, U256_MOD_FIELD, U256_MOD_FIELD_INV)
//         } else {
//             result
//         }
//     }
// }

// #[inline(always)]
// fn u512_reduce_bn(a: u512) -> u256 {
//     u512_reduce(a, get_field_nz())
// }

// #[inline(always)]
// fn u512_scl_9(a: u512, field_nz: NonZero<u256>) -> u512 {
//     let u512 { limb0, limb1, limb2: low, limb3: high, } = a;
//     let u256 { low: limb2, high: limb3 } = reduce(u256 { high, low }, field_nz);
//     let (result, overflow) = u512_scl(u512 { limb0, limb1, limb2, limb3, }, 9);

//     if (overflow == 0) {
//         result
//     } else {
//         fix_overflow_u512(result, U256_MOD_FIELD_INV, U256_MOD_FIELD)
//     }
// }

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

fn mul_by_xi_nz_as_circuit(t: f::Fq2) -> f::Fq2 {
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

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let outputs =
        match (t0_mul_9_sub_t1, t0_add_t1_mul_9,)
            .new_inputs()
            .next(t0)
            .next(t1)
            .next(scl)
            .done()
            .eval(modulus) {
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
fn mul_by_v_nz_as_circuit(t: f::Fq6) -> f::Fq6 {
    let t0 = t.c0;
    let t1 = t.c1;
    let t2 = t.c2;

    f::Fq6 { c0: mul_by_xi_nz_as_circuit(t2), c1: t0, c2: t1 }
}

// #[inline(always)]
// fn mul(a: u256, b: u256) -> u256 {
//     m::mul_nz(a, b, get_field_nz())
// }

// #[inline(always)]
// fn scl(a: u256, b: u128) -> u256 {
//     m::scl(a, b, get_field_nz())
// }

// #[inline(always)]
// fn neg(b: u256) -> u256 {
//     m::neg(b, FIELD)
// }

// #[inline(always)]
// fn neg_o(b: u256) -> u256 {
//     m::neg(b, ORDER)
// }

// #[inline(always)]
// fn add(mut a: u256, mut b: u256) -> u256 {
//     m::add(a, b, FIELD)
// }

// #[inline(always)]
// fn sqr(mut a: u256) -> u256 {
//     m::sqr_nz(a, get_field_nz())
// }

// #[inline(always)]
// fn sub_field(mut a: u256, mut b: u256) -> u256 {
//     m::sub(a, b, FIELD)
// }

// #[inline(always)]
// fn div(a: u256, b: u256) -> u256 {
//     m::div_nz(a, b, get_field_nz())
// }

// #[inline(always)]
// fn inv(b: u256) -> u256 {
//     m::inv(b, get_field_nz())
// }
