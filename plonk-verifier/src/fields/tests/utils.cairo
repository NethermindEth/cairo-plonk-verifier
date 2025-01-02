use core::circuit::{u384, u96};
use debug::PrintTrait;

use plonk_verifier::curve::u512;
use plonk_verifier::fields::utils::conversions::into_u512;

#[test]
fn test_into_u512() {
    let value = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };
    let result = into_u512(value);
    assert(result.limb0 == 0, 'limb0 should be 0');
    assert(result.limb1 == 0, 'limb1 should be 0');
    assert(result.limb2 == 0, 'limb2 should be 0');
    assert(result.limb3 == 0, 'limb3 should be 0');

    // Test with small values
    let value = u384 { limb0: 0, limb1: 0, limb2: 1, limb3: 0 };
    let result = into_u512(value);
    // Basic assertions
    assert(result.limb0 == 0, 'limb0 should be 0');
    assert(result.limb1 == 18446744073709551616, 'limb1 should not be 0');
    assert(result.limb2 == 0, 'limb2 should not be 0');
    assert(result.limb3 == 0, 'limb3 should be 0');

    let value = u384 { limb0: 0, limb1: 1, limb2: 0, limb3: 0 };
    let result = into_u512(value);
    assert(result.limb0 == 79228162514264337593543950336, 'limb0 wrong value'); // 2^32
    assert(result.limb1 == 0, 'limb1 should be 0');
    assert(result.limb2 == 0, 'limb2 should be 0');
    assert(result.limb3 == 0, 'limb3 should be 0');
}

