mod conversions {
    use core::integer::upcast;
    use core::internal::{
        bounded_int, bounded_int::{BoundedInt, AddHelper, MulHelper, DivRemHelper,}
    };
    use core::circuit::{u384, u96};
    // use plonk_verifier::curve::u512;

    type ConstValue<const VALUE: felt252> = BoundedInt<VALUE, VALUE>;
    const POW32: felt252 = 0x100000000;
    const POW32_TYPED: ConstValue<POW32> = 0x100000000;
    const NZ_POW32_TYPED: NonZero<ConstValue<POW32>> = 0x100000000;

    const POW64: felt252 = 0x10000000000000000;
    const POW64_TYPED: ConstValue<POW64> = 0x10000000000000000;
    const NZ_POW64_TYPED: NonZero<ConstValue<POW64>> = 0x10000000000000000;

    const POW96: felt252 = 0x1000000000000000000000000;
    const POW96_TYPED: ConstValue<POW96> = 0x1000000000000000000000000;
    const NZ_POW96_TYPED: NonZero<ConstValue<POW96>> = 0x1000000000000000000000000;

    const POW128: felt252 = 0x100000000000000000000000000000000;
    const POW128_TYPED: ConstValue<POW128> = 0x100000000000000000000000000000000;
    const NZ_POW128_TYPED: NonZero<ConstValue<POW128>> = 0x100000000000000000000000000000000;

    const POW192: felt252 = 0x1000000000000000000000000000000000000000000000000;
    const POW192_TYPED: ConstValue<POW192> = 0x1000000000000000000000000000000000000000000000000;
    const NZ_POW192_TYPED: NonZero<ConstValue<POW192>> =
        0x1000000000000000000000000000000000000000000000000;

    //-----------------DivRemHelpers Parts-----------------
    impl DivRemU96By32 of DivRemHelper<u96, ConstValue<POW32>> {
        type DivT = BoundedInt<0, { POW64 - 1 }>;
        type RemT = BoundedInt<0, { POW32 - 1 }>;
    }

    impl DivRemU96By64 of DivRemHelper<u96, ConstValue<POW64>> {
        type DivT = BoundedInt<0, { POW32 - 1 }>;
        type RemT = BoundedInt<0, { POW64 - 1 }>;
    }

    //-----------------MulHelpers Parts-----------------
    impl Mul32By96Impl of MulHelper<BoundedInt<0, { POW32 - 1 }>, ConstValue<POW96>> {
        // The result needs to accommodate POW32 * 2^96
        type Result = BoundedInt<0, { POW128 - POW96 }>;
    }

    impl MulHelper64By64Impl of MulHelper<BoundedInt<0, { POW64 - 1 }>, ConstValue<POW64>> {
        type Result = BoundedInt<0, { POW128 - POW64 }>;
    }

    impl MulHigh96Shift32Impl of MulHelper<u96, ConstValue<POW32>> {
        type Result = BoundedInt<0, { POW128 - POW32 }>;
    }

    //-----------------AddHelpers Parts-----------------
    impl AddHelperHigh32Low96Impl of AddHelper<BoundedInt<0, { POW128 - POW96 }>, u96> {
        type Result = BoundedInt<0, { POW128 - 1 }>;
        // type Result = u128;
    }

    impl AddHelperHigh64Low64Impl of AddHelper<
        BoundedInt<0, { POW64 - 1 }>, BoundedInt<0, { POW128 - POW64 }>
    > {
        type Result = BoundedInt<0, { POW128 - 1 }>;
    }

    impl AddHelperLimb2Parts of AddHelper<
        BoundedInt<0, { POW32 - 1 }>, BoundedInt<0, { POW128 - POW32 }>
    > {
        type Result = BoundedInt<0, { POW128 - 1 }>;
    }

    // pub fn into_u512(value: u384) -> u512 {
    //     // warning: don't use, this function is not well tested
    //     let (limb2_low32, limb1_high64) = bounded_int::div_rem(value.limb2, NZ_POW64_TYPED);
    //     let (limb1_low64, limb0_high32) = bounded_int::div_rem(value.limb1, NZ_POW32_TYPED);

    //     let shift_limb0_high32 = bounded_int::mul(limb0_high32, POW96_TYPED);
    //     let limb0 = bounded_int::add(shift_limb0_high32, value.limb0);

    //     let shift_limb1_high64 = bounded_int::mul(limb1_high64, POW64_TYPED);
    //     let limb1 = bounded_int::add(limb1_low64, shift_limb1_high64);

    //     let shift_limb2_high96 = bounded_int::mul(value.limb3, POW32_TYPED);
    //     let limb2 = bounded_int::add(limb2_low32, shift_limb2_high96);

    //     u512 {
    //         limb0: upcast::<BoundedInt<0, { POW128 - 1 }>, u128>(limb0),
    //         limb1: upcast::<BoundedInt<0, { POW128 - 1 }>, u128>(limb1),
    //         limb2: upcast::<BoundedInt<0, { POW128 - 1 }>, u128>(limb2),
    //         limb3: 0,
    //     }
    // }
}
