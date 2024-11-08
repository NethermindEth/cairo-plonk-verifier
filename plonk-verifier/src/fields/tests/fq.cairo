use debug::PrintTrait;

use plonk_verifier::traits::FieldOps;
use plonk_verifier::fields::{fq, Fq, fq2, Fq2, FieldUtils, FqMulShort};
use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
use plonk_verifier::curve::{FIELD, get_field_nz};


fn ops() -> Array<Fq> {
    array![ //
        fq(256) - fq(56), //
        fq(256) + fq(56), //
        fq(256) * fq(56), //
        fq(256) / fq(56), //
        -fq(256), //
    ]
}

use plonk_verifier::curve::{sub_u, add, mul, div, neg,};

fn u256_mod_ops() -> Array<u256> {
    array![ //
    sub_u(256, 56), //
     add(256, 56), //
     mul(256, 56), //
     div(256, 56), //
     neg(256), //
    ]
}

#[test]
fn inv_one() {
    let one: Fq = FieldUtils::one();
    assert(one.inv(get_field_nz()) == one, 'incorrect inverse of one');
}

#[test]
fn test_main() {
    let fq_res = ops();
    let u256_mod_res = u256_mod_ops();

    let mut i = 0;
    loop {
        if i == fq_res.len() {
            break;
        }
        assert(fq_res.at(i).c0 == u256_mod_res.at(i), 'incorrect op 0' + i.into());
        i += 1;
    };
    assert((fq(256) == fq(56)) == false, 'incorrect eq');
    assert((fq(3294587623987546) == fq(3294587623987546)) == true, 'incorrect eq');
}

#[test]
fn test_fq_u_mul() {
    // Test case 1: Basic multiplication
    let a = fq(1_u256);
    let b = fq(2_u256);
    let result = FqMulShort::u_mul(a, b);
    assert_eq!(result.limb0, 2_u128, "1 * 2 should equal 2");
    assert_eq!(result.limb1, 0_u128, "Higher limbs should be 0");
    assert_eq!(result.limb2, 0_u128, "Higher limbs should be 0");
    assert_eq!(result.limb3, 0_u128, "Higher limbs should be 0");

    // Test case 2: Larger numbers
    let a = fq(0xFFFFFFFF_u256);
    let b = fq(0xFFFFFFFF_u256);
    let result = FqMulShort::u_mul(a, b);
    assert_eq!(result.limb0, 0xFFFFFFFE00000001_u128, "FFFFFFFF * FFFFFFFF calculation");
    assert_eq!(result.limb1, 0_u128, "Higher limbs should match");

    // Test case 3: Zero multiplication
    let a = fq(0_u256);
    let b = fq(123_u256);
    let result = FqMulShort::u_mul(a, b);
    assert_eq!(result.limb0, 0_u128, "0 * 123 should be 0");
    assert_eq!(result.limb1, 0_u128, "Higher limbs should be 0");
    assert_eq!(result.limb2, 0_u128, "Higher limbs should be 0");
    assert_eq!(result.limb3, 0_u128, "Higher limbs should be 0");
}
