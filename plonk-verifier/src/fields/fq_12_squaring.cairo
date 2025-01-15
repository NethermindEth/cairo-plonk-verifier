use core::circuit::{
    AddInputResultTrait, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
    CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, circuit_add, circuit_inverse,
    circuit_mul, circuit_sub, u384,
};

use plonk_verifier::circuits::fq_12_squaring_circuits::{decompress_zero_circuit, decompress_non_zero_circuit, sqr_circuit};
use plonk_verifier::curve::{constants::{FIELD_U384, TWO}, mul_by_xi_nz_as_circuit};
use plonk_verifier::fields::{
    fq, fq2, fq12, Fq, Fq2, Fq6, Fq12, Fq12Frobenius, FieldOps, FieldUtils,
};
use plonk_verifier::fields::fq_generics::TFqPartialEq;

#[derive(Copy, Drop,)]
struct Krbn2345 {
    g2: Fq2,
    g3: Fq2,
    g4: Fq2,
    g5: Fq2,
}

pub fn krbn2345(g2: Fq2, g3: Fq2, g4: Fq2, g5: Fq2) -> Krbn2345 {
    Krbn2345 { g2, g3, g4, g5}
}

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
    // #[inline(always)]
    fn krbn_compress_2345(self: Fq12) -> Krbn2345 {
        let Fq12 { c0: Fq6 { c0: _0, c1: g4, c2: g3 }, c1: Fq6 { c0: g2, c1: _1, c2: g5 } } = self;
        Krbn2345 { g2, g3, g4, g5 }
    }

    // Karabina decompress a2, a3, a4, a5 to Fq12 a0, a1, a2, a3, a4, a5
    fn krbn_decompress(self: Krbn2345, m: CircuitModulus) -> Fq12 {
        let Krbn2345 { g2, g3, g4, g5 } = self;

            let (g0_c0, g0_c1, g1_c0, g1_c1) = decompress_non_zero_circuit(); 

            let o = match (g0_c0, g0_c1, g1_c0, g1_c1).new_inputs()
                .next(self.g2.c0.c0)
                .next(self.g2.c1.c0)
                .next(self.g3.c0.c0)
                .next(self.g3.c1.c0)
                .next(self.g4.c0.c0)
                .next(self.g4.c1.c0)
                .next(self.g5.c0.c0)
                .next(self.g5.c1.c0)
                .done().eval(m) {
                    Result::Ok(outputs) => { outputs },
                    Result::Err(_) => { panic!("Expected success") }
            };
    
            let mut g0 = fq2(o.get_output(g0_c0), o.get_output(g0_c1));
            let g1 = fq2(o.get_output(g1_c0), o.get_output(g1_c1));
            
            
            g0 = g0.add(FieldUtils::one(), m);
            Fq12 { c0: Fq6 { c0: g0, c1: g4, c2: g3 }, c1: Fq6 { c0: g2, c1: g1, c2: g5 } }
    }

    // https://eprint.iacr.org/2010/542.pdf
    // Compressed Karabina 2345 square
    fn sqr_krbn(self: Krbn2345, m: CircuitModulus) -> Krbn2345 {

        let (g2_c0, g2_c1, g3_c0, g3_c1, g4_c0, g4_c1, g5_c0, g5_c1) = sqr_circuit(); 

        let o = match (g2_c0, g2_c1, g3_c0, g3_c1, g4_c0, g4_c1, g5_c0, g5_c1).new_inputs()
            .next(self.g2.c0.c0)
            .next(self.g2.c1.c0)
            .next(self.g3.c0.c0)
            .next(self.g3.c1.c0)
            .next(self.g4.c0.c0)
            .next(self.g4.c1.c0)
            .next(self.g5.c0.c0)
            .next(self.g5.c1.c0)
            .done().eval(m) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        krbn2345(
            fq2(o.get_output(g2_c0), o.get_output(g2_c1)), 
            fq2(o.get_output(g3_c0), o.get_output(g3_c1)), 
            fq2(o.get_output(g4_c0), o.get_output(g4_c1)), 
            fq2(o.get_output(g5_c0), o.get_output(g5_c1))
        )
    }

    fn sqr_n_times(self: Fq12, n: i32, m: CircuitModulus) -> Fq12 {
        let mut krbn = self.krbn_compress_2345();

        let mut i = 0;
        while i < n {
            krbn = krbn.sqr_krbn(m);
            i = i + 1;
        };

        krbn.krbn_decompress(m)
    }
}

#[generate_trait]
impl Fq12SquaringCircuit of Fq12SquaringCircuitTrait {
    // Cyclotomic squaring
    fn cyclotomic_sqr_circuit(self: Fq12, m: CircuitModulus) -> Fq12 {
        // core::internal::revoke_ap_tracking();

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
                .eval(m) {
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
                .eval(m) {
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
                .eval(m) {
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
                .eval(m) {
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
                .eval(m) {
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
            match (tmp_0, tmp_1,).new_inputs().next(T5_c0).next(T5_c1).done().eval(m) {
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
                .eval(m) {
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
                .eval(m) {
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
                .eval(m) {
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
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let z5_0 = outputs.get_output(Z5_0);
        let z5_1 = outputs.get_output(Z5_1);

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
