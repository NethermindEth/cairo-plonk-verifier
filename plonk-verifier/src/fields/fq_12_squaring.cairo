use plonk_verifier::traits::FieldShortcuts;
use plonk_verifier::traits::FieldMulShortcuts;
use core::array::ArrayTrait;
use plonk_verifier::curve::{FIELD, FIELD_X2};
// use plonk_verifier::curve::{
//     u512, mul_by_xi_nz, mul_by_v, U512BnAdd, U512BnSub, Tuple2Add, Tuple2Sub,
//     mul_by_xi_nz_as_circuit
// };
use plonk_verifier::curve::{mul_by_xi_nz_as_circuit};
// use plonk_verifier::curve::{u512_add, u512_sub, u512_high_add, u512_high_sub, U512Fq2Ops};
use plonk_verifier::fields::{
    FieldUtils, FieldOps, fq, Fq, Fq2, ufq2_inv, Fq6, Fq12, fq12, Fq12Frobenius
};
use plonk_verifier::fields::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
// use plonk_verifier::fields::print::{Fq2Display, FqDisplay, u512Display};
use core::circuit::{
    CircuitElement, CircuitInput, circuit_add, circuit_sub, circuit_mul, circuit_inverse,
    EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs,
    EvalCircuitResult,
};
use core::circuit::conversions::from_u256;
use plonk_verifier::curve::constants::FIELD_U384;

#[derive(Copy, Drop,)]
struct Krbn2345 {
    g2: Fq2,
    g3: Fq2,
    g4: Fq2,
    g5: Fq2,
}

#[inline(always)]
fn x2(a: Fq2) -> Fq2 {
    a.u_add(a)
}

#[inline(always)]
fn x4(a: Fq2) -> Fq2 {
    let a_twice = x2(a);
    a_twice.u_add(a_twice)
}

// #[inline(always)]
// fn X2(a: (u512, u512)) -> (u512, u512) {
//     a + a
// }

#[generate_trait]
impl Fq12Squaring of Fq12SquaringTrait {
    // Karabina compress Fq12 a0, a1, a2, a3, a4, a5 to a2, a3, a4, a5
    // For Karabina sqr 2345
    //
    // https://github.com/mratsim/constantine/blob/c7979b003372b329dd450ff152bb5945cafb0db5/constantine/math/pairings/cyclotomic_subgroups.nim#L639
    // Karabina uses the cubic over quadratic representation
    // But we use the quadratic over cubic Fq12 -> Fq6 -> Fq2
    // `Fq12` --quadratic-- `Fq6` --cubic-- `Fq2`
    // canonical <=> cubic over quadratic <=> quadratic over cubic
    //    c0     <=>        g0            <=>            b0
    //    c1     <=>        g2            <=>            b3
    //    c2     <=>        g4            <=>            b1
    //    c3     <=>        g1            <=>            b4
    //    c4     <=>        g3            <=>            b2
    //    c5     <=>        g5            <=>            b5
    #[inline(always)]
    fn krbn_compress_2345(self: Fq12) -> Krbn2345 {
        let Fq12 { c0: Fq6 { c0: _0, c1: g4, c2: g3 }, c1: Fq6 { c0: g2, c1: _1, c2: g5 } } = self;
        Krbn2345 { g2, g3, g4, g5 }
    }

    // Karabina decompress a2, a3, a4, a5 to Fq12 a0, a1, a2, a3, a4, a5
    fn krbn_decompress(self: Krbn2345, field_nz: NonZero<u256>) -> Fq12 {
        core::internal::revoke_ap_tracking();
        let Krbn2345 { g2, g3, g4, g5 } = self;
        // Si = gi^2
        if g2.c0 == FieldUtils::zero() && g2.c1 == FieldUtils::zero() {
            // g1 = 2g4g5/g3
            let tg24g5 = x2(g4.mul(g5));
            let g1 = tg24g5.mul(g3.inv(field_nz));

            // g0 = (2S1 - 3g3g4)ξ + 1
            let S1 = g1.sqr();
            let T_g3g4 = g3.mul(g4);
            let Tmp = (S1 - T_g3g4).scale(2);
            let mut g0 = (Tmp - T_g3g4).mul_by_nonresidue();
            g0 = g0.add(FieldUtils::one());

            Fq12 { c0: Fq6 { c0: g0, c1: g4, c2: g3 }, c1: Fq6 { c0: g2, c1: g1, c2: g5 } }
        } else {
            // g1 = (S5ξ + 3S4 - 2g3)/4g2
            let S5xi = mul_by_xi_nz_as_circuit(g5.sqr());
            let S4 = g4.sqr();
            let Tmp = S4.sub(g3);
            let g1 = (S5xi + S4.add(Tmp.add(Tmp)));
            let g1 = g1.mul(ufq2_inv(x4(g2), field_nz));

            // // g0 = (2S1 + g2g5 - 3g3g4)ξ + 1
            let S1 = g1.sqr();
            let T_g3g4 = g3.mul(g4);
            let T_g2g5 = g2.mul(g5);
            let Tmp = (S1 - T_g3g4).scale(2);
            let mut g0 = (Tmp + T_g2g5 - T_g3g4).mul_by_nonresidue();
            g0 = g0.add(FieldUtils::one());
            Fq12 { c0: Fq6 { c0: g0, c1: g4, c2: g3 }, c1: Fq6 { c0: g2, c1: g1, c2: g5 } }
        }
    }

    // This Karabina implementation is adjusted for the quadratic over cubic representation
    // https://github.com/Consensys/gnark-crypto/blob/v0.12.1/ecc/bn254/internal/fptower/e12.go#L143
    fn sqr_krbn_1235(self: Fq12, field_nz: NonZero<u256>) -> Fq12 {
        core::internal::revoke_ap_tracking();
        let Fq12 { c0: Fq6 { c0: _g0, c1: g1, c2: g2 }, c1: Fq6 { c0: g3, c1: _g4, c2: g5 } } =
            self;

        let S1 = g1.sqr();
        let S2 = g2.sqr();
        let S3 = g3.sqr();
        let S5 = g5.sqr();
        let S1_5 = (g1 + g5).sqr();
        let S2_3 = (g2 + g3).sqr();

        let Tmp = S3 + mul_by_xi_nz_as_circuit(S2);
        let h1 = Tmp.sub(g1).scale(2) + Tmp;

        let Tmp = mul_by_xi_nz_as_circuit(S5) + S1;
        let h2 = Tmp.sub(g2).scale(2) + Tmp;

        let Tmp = mul_by_xi_nz_as_circuit(S1_5 - S1 - S5);
        let h3 = Tmp.add(g3).scale(2) + Tmp;

        let Tmp = S2_3 - S2 - S3;
        let h5 = Tmp.add(g5).scale(2) + Tmp;

        let _0 = FieldUtils::zero();

        Fq12 { c0: Fq6 { c0: _0, c1: h1, c2: h2 }, c1: Fq6 { c0: h3, c1: _0, c2: h5 } }
    }

    // https://eprint.iacr.org/2010/542.pdf
    // Compressed Karabina 2345 square
    fn sqr_krbn(self: Krbn2345, field_nz: NonZero<u256>) -> Krbn2345 {
        core::internal::revoke_ap_tracking();
        // Input: self = (a2 +a3s)t+(a4 +a5s)t2 ∈ Gφ6(Fp2)
        // Output: self^2 = (c2 +c3s)t+(c4 +c5s)t2 ∈ Gφ6 (Fp2 ).
        let Krbn2345 { g2, g3, g4, g5 } = self;

        let S2 = g2.sqr();
        let S3 = g3.sqr();
        let S4 = g4.sqr();
        let S5 = g5.sqr();
        let S4_5 = g4.add(g5).sqr();
        let S2_3 = g2.add(g3).sqr();

        let Tmp = mul_by_xi_nz_as_circuit(S4_5.sub(S4.add(S5)));
        let h2 = Tmp.add(g2).scale(2).add(Tmp);

        let Tmp = S4.add(mul_by_xi_nz_as_circuit(S5));
        let h3 = Tmp.sub(g3).scale(2).add(Tmp);

        let Tmp = S2.add(mul_by_xi_nz_as_circuit(S3));
        let h4 = Tmp.sub(g4).scale(2).add(Tmp);

        let Tmp = S2_3.sub(S2).sub(S3);
        let h5 = Tmp.add(g5).scale(2).add(Tmp);

        Krbn2345 { g2: h2, g3: h3, g4: h4, g5: h5, }
    }

    #[inline(always)]
    fn krbn_sqr_4x(self: Krbn2345, field_nz: NonZero<u256>) -> Krbn2345 {
        self.sqr_krbn(field_nz).sqr_krbn(field_nz).sqr_krbn(field_nz).sqr_krbn(field_nz)
    }

    fn sqr_6_times(self: Fq12, field_nz: NonZero<u256>) -> Fq12 {
        core::internal::revoke_ap_tracking();
        self
            .krbn_compress_2345()
            .krbn_sqr_4x(field_nz) // ^2^4
            .sqr_krbn(field_nz) // ^2^5
            .sqr_krbn(field_nz) // ^2^6
            .krbn_decompress(field_nz)
    }

    // Called only once hence inlined
    #[inline(always)]
    fn sqr_7_times(self: Fq12, field_nz: NonZero<u256>) -> Fq12 {
        core::internal::revoke_ap_tracking();
        self
            .krbn_compress_2345()
            .krbn_sqr_4x(field_nz) // ^2^4
            .sqr_krbn(field_nz) // ^2^5
            .sqr_krbn(field_nz) // ^2^6
            .sqr_krbn(field_nz) // ^2^7
            .krbn_decompress(field_nz)
    }

    fn sqr_8_times(self: Fq12, field_nz: NonZero<u256>) -> Fq12 {
        core::internal::revoke_ap_tracking();
        self
            .krbn_compress_2345()
            .krbn_sqr_4x(field_nz)
            .krbn_sqr_4x(field_nz)
            .krbn_decompress(field_nz)
    }

    // Called only once hence inlined
    #[inline(always)]
    fn sqr_10_times(self: Fq12, field_nz: NonZero<u256>) -> Fq12 {
        core::internal::revoke_ap_tracking();
        self
            .krbn_compress_2345()
            .krbn_sqr_4x(field_nz) // ^2^4
            .krbn_sqr_4x(field_nz) // ^2^8
            .sqr_krbn(field_nz) // ^2^9
            .sqr_krbn(field_nz) // ^2^10
            .krbn_decompress(field_nz)
    }

    // Cyclotomic squaring
    fn cyclotomic_sqr(self: Fq12, field_nz: NonZero<u256>) -> Fq12 {
        core::internal::revoke_ap_tracking();

        let z0 = self.c0.c0;
        let z4 = self.c0.c1;
        let z3 = self.c0.c2;
        let z2 = self.c1.c0;
        let z1 = self.c1.c1;
        let z5 = self.c1.c2;
        // let tmp = z0 * z1;
        // let Tmp = z0.u_mul(z1);
        // let t0 = (z0 + z1) * (z1.mul_by_nonresidue() + z0) - tmp - tmp.mul_by_nonresidue();
        // let T0 = z0.u_add(z1).u_mul(z1.mul_by_nonresidue().u_add(z0))
        //     - Tmp
        //     - mul_by_xi_nz(Tmp, field_nz);

        // let t1 = tmp + tmp;
        // let T1 = Tmp + Tmp;

        // // let tmp = z2 * z3;
        // let Tmp = z2.u_mul(z3);
        // // let t2 = (z2 + z3) * (z3.mul_by_nonresidue() + z2) - tmp - tmp.mul_by_nonresidue();
        // let T2 = z2.u_add(z3).u_mul(z3.mul_by_nonresidue().u_add(z2))
        //     - Tmp
        //     - mul_by_xi_nz(Tmp, field_nz);
        // // let t3 = tmp + tmp;
        // let T3 = Tmp + Tmp;

        // // let tmp = z4 * z5;
        // let Tmp = z4.u_mul(z5);
        // // let t4 = (z4 + z5) * (z5.mul_by_nonresidue() + z4) - tmp - tmp.mul_by_nonresidue();
        // let T4 = z4.u_add(z5).u_mul(z5.mul_by_nonresidue().u_add(z4))
        //     - Tmp
        //     - mul_by_xi_nz(Tmp, field_nz);
        // // let t5 = tmp + tmp;
        // let T5 = Tmp + Tmp;

        // let Z0 = T0.u512_sub_fq(z0);
        // let Z0 = Z0 + Z0;
        // let Z0 = Z0 + T0;

        // let Z1 = T1.u512_add_fq(z1);
        // let Z1 = Z1 + Z1;
        // let Z1 = Z1 + T1;

        // let Tmp = mul_by_xi_nz(T5, field_nz);
        // let Z2 = Tmp.u512_add_fq(z2);
        // let Z2 = Z2 + Z2;
        // let Z2 = Z2 + Tmp;

        // let Z3 = T4.u512_sub_fq(z3);
        // let Z3 = Z3 + Z3;
        // let Z3 = Z3 + T4;

        // let Z4 = T2.u512_sub_fq(z4);
        // let Z4 = Z4 + Z4;
        // let Z4 = Z4 + T2;

        // let Z5 = T3.u512_add_fq(z5);
        // let Z5 = Z5 + Z5;
        // let Z5 = Z5 + T3;

        let tmp = z0.mul(z1);
        let T0 = z0
            .add(z1)
            .mul(z1.mul_by_nonresidue().add(z0))
            .sub(tmp)
            .sub(mul_by_xi_nz_as_circuit(tmp));

        let T1 = tmp.add(tmp);

        let tmp = z2.mul(z3);

        let T2 = z2.add(z3).mul(z3.mul_by_nonresidue().add(z2))
            - tmp
            - mul_by_xi_nz_as_circuit(tmp);
        let T3 = tmp.add(tmp);

        let tmp = z4.mul(z5);
        let T4 = z4.add(z5).mul(z5.mul_by_nonresidue().add(z4))
            - tmp
            - mul_by_xi_nz_as_circuit(tmp);
        let T5 = tmp.add(tmp);

        let Z0 = T0.sub(z0);
        let Z0 = Z0 + Z0;
        let Z0 = Z0 + T0;

        let Z1 = T1.add(z1);
        let Z1 = Z1 + Z1;
        let Z1 = Z1 + T1;

        let tmp = mul_by_xi_nz_as_circuit(T5);

        let Z2 = tmp.add(z2);
        let Z2 = Z2 + Z2;
        let Z2 = Z2 + tmp;

        let Z3 = T4.sub(z3);
        let Z3 = Z3 + Z3;
        let Z3 = Z3 + T4;

        let Z4 = T2.sub(z4);
        let Z4 = Z4 + Z4;
        let Z4 = Z4 + T2;

        let Z5 = T3.add(z5);
        let Z5 = Z5 + Z5;
        let Z5 = Z5 + T3;

        Fq12 { c0: Fq6 { c0: Z0, c1: Z4, c2: Z3 }, c1: Fq6 { c0: Z2, c1: Z1, c2: Z5 }, }
    }
}

#[generate_trait]
impl Fq12SquaringCircuit of Fq12SquaringCircuitTrait {
    // Cyclotomic squaring
    fn cyclotomic_sqr_circuit(self: Fq12, field_nz: NonZero<u256>) -> Fq12 {
        core::internal::revoke_ap_tracking();

        let z0_0 = CircuitElement::<CircuitInput<0>> {};
        let z0_1 = CircuitElement::<CircuitInput<1>> {};
        let z1_0 = CircuitElement::<CircuitInput<2>> {};
        let z1_1 = CircuitElement::<CircuitInput<3>> {};

        let tmp_T0 = circuit_mul(z0_0, z1_0); // z0 * z1;
        let tmp_T1 = circuit_mul(z0_1, z1_1);
        let tmp_T2_0 = circuit_add(z0_0, z0_1);
        let tmp_T2_1 = circuit_add(z1_0, z1_1);
        let tmp_T2 = circuit_mul(tmp_T2_0, tmp_T2_1);
        let tmp_T3_0 = circuit_add(tmp_T0, tmp_T1);
        let tmp_c1 = circuit_sub(tmp_T2, tmp_T3_0);
        let tmp_c0 = circuit_sub(tmp_T0, tmp_T1);

        let T0_0_c0 = circuit_add(z0_0, z1_0); // (z0 + z1)
        let T0_0_c1 = circuit_add(z0_1, z1_1);

        let a0_scale_9_2 = circuit_add(z1_0, z1_0); // z1.mul_by_nonresidue()
        let a0_scale_9_4 = circuit_add(a0_scale_9_2, a0_scale_9_2);
        let a0_scale_9_8 = circuit_add(a0_scale_9_4, a0_scale_9_4);
        let a0_scale_9 = circuit_add(a0_scale_9_8, z1_0);
        let a1_scale_9_2 = circuit_add(z1_1, z1_1);
        let a1_scale_9_4 = circuit_add(a1_scale_9_2, a1_scale_9_2);
        let a1_scale_9_8 = circuit_add(a1_scale_9_4, a1_scale_9_4);
        let a1_scale_9 = circuit_add(a1_scale_9_8, z1_1);
        let T0_1_c0 = circuit_sub(a0_scale_9, z1_1);
        let T0_1_c1 = circuit_add(a1_scale_9, z1_0);

        let T0_2_c0 = circuit_add(T0_1_c0, z0_0); // (z1.mul_by_nonresidue() + z0)
        let T0_2_c1 = circuit_add(T0_1_c1, z0_1);

        let tmp_T0 = circuit_mul(T0_0_c0, T0_2_c0); // (z0 + z1) * (z1.mul_by_nonresidue() + z0)
        let tmp_T1 = circuit_mul(T0_0_c1, T0_2_c1);
        let tmp_T2_0 = circuit_add(T0_0_c0, T0_0_c1);
        let tmp_T2_1 = circuit_add(T0_2_c0, T0_2_c1);
        let tmp_T2 = circuit_mul(tmp_T2_0, tmp_T2_1);
        let tmp_T3_0 = circuit_add(tmp_T0, tmp_T1);
        let T0_3_c1 = circuit_sub(tmp_T2, tmp_T3_0);
        let T0_3_c0 = circuit_sub(tmp_T0, tmp_T1);

        let a0_scale_9_2 = circuit_add(tmp_c0, tmp_c0); // tmp.mul_by_nonresidue()
        let a0_scale_9_4 = circuit_add(a0_scale_9_2, a0_scale_9_2);
        let a0_scale_9_8 = circuit_add(a0_scale_9_4, a0_scale_9_4);
        let a0_scale_9 = circuit_add(a0_scale_9_8, tmp_c0);
        let a1_scale_9_2 = circuit_add(tmp_c1, tmp_c1);
        let a1_scale_9_4 = circuit_add(a1_scale_9_2, a1_scale_9_2);
        let a1_scale_9_8 = circuit_add(a1_scale_9_4, a1_scale_9_4);
        let a1_scale_9 = circuit_add(a1_scale_9_8, tmp_c1);
        let T0_4_c0 = circuit_sub(a0_scale_9, tmp_c1);
        let T0_4_c1 = circuit_add(a1_scale_9, tmp_c0);

        let T0_5_c0 = circuit_sub(
            T0_3_c0, tmp_c0
        ); // (z0 + z1) * (z1.mul_by_nonresidue() + z0) - tmp
        let T0_5_c1 = circuit_sub(T0_3_c1, tmp_c1);

        let T0_c0_template = circuit_sub(T0_5_c0, T0_4_c0);
        let T0_c1_template = circuit_sub(T0_5_c1, T0_4_c1);

        let T1_c0_template = circuit_add(tmp_c0, tmp_c0);
        let T1_c1_template = circuit_add(tmp_c1, tmp_c1);

        // Initialization
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
        let z0_0 = self.c0.c0.c0.c0;
        let z0_1 = self.c0.c0.c1.c0;
        let z1_0 = self.c1.c1.c0.c0;
        let z1_1 = self.c1.c1.c1.c0;
        let z2_0 = self.c1.c0.c0.c0;
        let z2_1 = self.c1.c0.c1.c0;
        let z3_0 = self.c0.c2.c0.c0;
        let z3_1 = self.c0.c2.c1.c0;
        let z4_0 = self.c0.c1.c0.c0;
        let z4_1 = self.c0.c1.c1.c0;
        let z5_0 = self.c1.c2.c0.c0;
        let z5_1 = self.c1.c2.c1.c0;

        // Intermediate circuit as all out gates must be degree 0
        let outputs =
            match (T0_c0_template, T0_c1_template, T1_c0_template, T1_c1_template,)
                .new_inputs()
                .next(z0_0)
                .next(z0_1)
                .next(z1_0)
                .next(z1_1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let T0_c0 = outputs.get_output(T0_c0_template);
        let T0_c1 = outputs.get_output(T0_c1_template);
        let T1_c0 = outputs.get_output(T1_c0_template);
        let T1_c1 = outputs.get_output(T1_c1_template);

        let outputs =
            match (T0_c0_template, T0_c1_template, T1_c0_template, T1_c1_template,)
                .new_inputs()
                .next(z2_0)
                .next(z2_1)
                .next(z3_0)
                .next(z3_1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let T2_c0 = outputs.get_output(T0_c0_template);
        let T2_c1 = outputs.get_output(T0_c1_template);
        let T3_c0 = outputs.get_output(T1_c0_template);
        let T3_c1 = outputs.get_output(T1_c1_template);

        let outputs =
            match (T0_c0_template, T0_c1_template, T1_c0_template, T1_c1_template,)
                .new_inputs()
                .next(z4_0)
                .next(z4_1)
                .next(z5_0)
                .next(z5_1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let T4_c0 = outputs.get_output(T0_c0_template);
        let T4_c1 = outputs.get_output(T0_c1_template);
        let T5_c0 = outputs.get_output(T1_c0_template);
        let T5_c1 = outputs.get_output(T1_c1_template);

        // Z0
        let z0_0_in = CircuitElement::<CircuitInput<0>> {};
        let z0_1_in = CircuitElement::<CircuitInput<1>> {};
        let t0_0_in = CircuitElement::<CircuitInput<2>> {};
        let t0_1_in = CircuitElement::<CircuitInput<3>> {};

        let Z0_0_c0 = circuit_sub(t0_0_in, z0_0_in);
        let Z0_1_c0 = circuit_sub(t0_1_in, z0_1_in);
        let Z0_0_dbl = circuit_add(Z0_0_c0, Z0_0_c0);
        let Z0_1_dbl = circuit_add(Z0_1_c0, Z0_1_c0);
        let Z0_0 = circuit_add(Z0_0_dbl, t0_0_in);
        let Z0_1 = circuit_add(Z0_1_dbl, t0_1_in);

        let outputs =
            match (Z0_0, Z0_1,)
                .new_inputs()
                .next(z0_0)
                .next(z0_1)
                .next(T0_c0)
                .next(T0_c1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let z0_0 = outputs.get_output(Z0_0).try_into().unwrap();
        let z0_1 = outputs.get_output(Z0_1).try_into().unwrap();

        // Z1
        let z1_0_in = CircuitElement::<CircuitInput<0>> {};
        let z1_1_in = CircuitElement::<CircuitInput<1>> {};
        let t1_0_in = CircuitElement::<CircuitInput<2>> {};
        let t1_1_in = CircuitElement::<CircuitInput<3>> {};

        let Z1_0_c0 = circuit_add(t1_0_in, z1_0_in);
        let Z1_1_c0 = circuit_add(t1_1_in, z1_1_in);
        let Z1_0_dbl = circuit_add(Z1_0_c0, Z1_0_c0);
        let Z1_1_dbl = circuit_add(Z1_1_c0, Z1_1_c0);
        let Z1_0 = circuit_add(Z1_0_dbl, t1_0_in);
        let Z1_1 = circuit_add(Z1_1_dbl, t1_1_in);

        let outputs =
            match (Z1_0, Z1_1,)
                .new_inputs()
                .next(z1_0)
                .next(z1_1)
                .next(T1_c0)
                .next(T1_c1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let z1_0 = outputs.get_output(Z1_0).try_into().unwrap();
        let z1_1 = outputs.get_output(Z1_1).try_into().unwrap();

        // Z2
        let t5_0_in = CircuitElement::<CircuitInput<0>> {};
        let t5_1_in = CircuitElement::<CircuitInput<1>> {};

        let a0_scale_9_2 = circuit_add(t5_0_in, t5_0_in); // 2 * z5_0
        let a0_scale_9_4 = circuit_add(a0_scale_9_2, a0_scale_9_2); // 4 * z5_0
        let a0_scale_9_8 = circuit_add(a0_scale_9_4, a0_scale_9_4);
        let a0_scale_9 = circuit_add(a0_scale_9_8, t5_0_in); // 5 * z5_0
        let a1_scale_9_2 = circuit_add(t5_1_in, t5_1_in); // 2 * z5_1
        let a1_scale_9_4 = circuit_add(a1_scale_9_2, a1_scale_9_2); // 4 * z5_1
        let a1_scale_9_8 = circuit_add(a1_scale_9_4, a1_scale_9_4);
        let a1_scale_9 = circuit_add(a1_scale_9_8, t5_1_in); // 5 * z5_1

        let tmp_0 = circuit_sub(a0_scale_9, t5_1_in); // T4_1_c0 = a0_scale_9 - z5_1
        let tmp_1 = circuit_add(a1_scale_9, t5_0_in); // T4_1_c1 = a1_scale_9 + z5_0

        // Temp is split into smaller circuit due to error with recursive circuit building
        let outputs =
            match (tmp_0, tmp_1,).new_inputs().next(T5_c0).next(T5_c1).done().eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let tmp_0 = outputs.get_output(tmp_0);
        let tmp_1 = outputs.get_output(tmp_1);

        let z2_0_in = CircuitElement::<CircuitInput<0>> {};
        let z2_1_in = CircuitElement::<CircuitInput<1>> {};
        let tmp_0_in = CircuitElement::<CircuitInput<2>> {};
        let tmp_1_in = CircuitElement::<CircuitInput<3>> {};

        let Z2_0_c0 = circuit_add(tmp_0_in, z2_0_in);
        let Z2_1_c0 = circuit_add(tmp_1_in, z2_1_in);
        let Z2_0_dbl = circuit_add(Z2_0_c0, Z2_0_c0);
        let Z2_1_dbl = circuit_add(Z2_1_c0, Z2_1_c0);
        let Z2_0 = circuit_add(Z2_0_dbl, tmp_0_in);
        let Z2_1 = circuit_add(Z2_1_dbl, tmp_1_in);

        let outputs =
            match (Z2_0, Z2_1,)
                .new_inputs()
                .next(z2_0)
                .next(z2_1)
                .next(tmp_0)
                .next(tmp_1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let z2_0 = outputs.get_output(Z2_0).try_into().unwrap();
        let z2_1 = outputs.get_output(Z2_1).try_into().unwrap();

        // Z3
        let z3_0_in = CircuitElement::<CircuitInput<0>> {};
        let z3_1_in = CircuitElement::<CircuitInput<1>> {};
        let t4_0_in = CircuitElement::<CircuitInput<2>> {};
        let t4_1_in = CircuitElement::<CircuitInput<3>> {};

        let Z3_0_c0 = circuit_sub(t4_0_in, z3_0_in);
        let Z3_1_c0 = circuit_sub(t4_1_in, z3_1_in);
        let Z3_0_dbl = circuit_add(Z3_0_c0, Z3_0_c0);
        let Z3_1_dbl = circuit_add(Z3_1_c0, Z3_1_c0);
        let Z3_0 = circuit_add(Z3_0_dbl, t4_0_in);
        let Z3_1 = circuit_add(Z3_1_dbl, t4_1_in);

        let outputs =
            match (Z3_0, Z3_1,)
                .new_inputs()
                .next(z3_0)
                .next(z3_1)
                .next(T4_c0)
                .next(T4_c1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let z3_0 = outputs.get_output(Z3_0).try_into().unwrap();
        let z3_1 = outputs.get_output(Z3_1).try_into().unwrap();

        // Z4
        let z4_0_in = CircuitElement::<CircuitInput<0>> {};
        let z4_1_in = CircuitElement::<CircuitInput<1>> {};
        let t2_0_in = CircuitElement::<CircuitInput<2>> {};
        let t2_1_in = CircuitElement::<CircuitInput<3>> {};

        let Z4_0_c0 = circuit_sub(t2_0_in, z4_0_in);
        let Z4_1_c0 = circuit_sub(t2_1_in, z4_1_in);
        let Z4_0_dbl = circuit_add(Z4_0_c0, Z4_0_c0);
        let Z4_1_dbl = circuit_add(Z4_1_c0, Z4_1_c0);
        let Z4_0 = circuit_add(Z4_0_dbl, t2_0_in);
        let Z4_1 = circuit_add(Z4_1_dbl, t2_1_in);

        let outputs =
            match (Z4_0, Z4_1,)
                .new_inputs()
                .next(z4_0)
                .next(z4_1)
                .next(T2_c0)
                .next(T2_c1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let z4_0 = outputs.get_output(Z4_0).try_into().unwrap();
        let z4_1 = outputs.get_output(Z4_1).try_into().unwrap();

        // Z5
        let z5_0_in = CircuitElement::<CircuitInput<0>> {};
        let z5_1_in = CircuitElement::<CircuitInput<1>> {};
        let t3_0_in = CircuitElement::<CircuitInput<2>> {};
        let t3_1_in = CircuitElement::<CircuitInput<3>> {};

        let Z5_0_c0 = circuit_add(t3_0_in, z5_0_in);
        let Z5_1_c0 = circuit_add(t3_1_in, z5_1_in);
        let Z5_0_dbl = circuit_add(Z5_0_c0, Z5_0_c0);
        let Z5_1_dbl = circuit_add(Z5_1_c0, Z5_1_c0);
        let Z5_0 = circuit_add(Z5_0_dbl, t3_0_in);
        let Z5_1 = circuit_add(Z5_1_dbl, t3_1_in);

        let outputs =
            match (Z5_0, Z5_1,)
                .new_inputs()
                .next(z5_0)
                .next(z5_1)
                .next(T3_c0)
                .next(T3_c1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let z5_0 = outputs.get_output(Z5_0).try_into().unwrap();
        let z5_1 = outputs.get_output(Z5_1).try_into().unwrap();

        Fq12 {
            c0: Fq6 {
                c0: Fq2 { c0: Fq { c0: z0_0 }, c1: Fq { c0: z0_1 } },
                c1: Fq2 { c0: Fq { c0: z4_0 }, c1: Fq { c0: z4_1 } },
                c2: Fq2 { c0: Fq { c0: z3_0 }, c1: Fq { c0: z3_1 } }
            },
            c1: Fq6 {
                c0: Fq2 { c0: Fq { c0: z2_0 }, c1: Fq { c0: z2_1 } },
                c1: Fq2 { c0: Fq { c0: z1_0 }, c1: Fq { c0: z1_1 } },
                c2: Fq2 { c0: Fq { c0: z5_0 }, c1: Fq { c0: z5_1 } }
            },
        }
    }
}
