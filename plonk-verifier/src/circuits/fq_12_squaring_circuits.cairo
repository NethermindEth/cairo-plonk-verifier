use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use plonk_verifier::circuits::typedefs::fq_12_squaring_type::{
	KrbnG2C0, KrbnG2C1, KrbnG3C0, KrbnG3C1, KrbnG4C0, KrbnG4C1, KrbnG5C0, KrbnG5C1,
	KbrnDecompZeroG0C0, KbrnDecompZeroG0C1, KbrnDecompZeroG1C0, KbrnDecompZeroG1C1,
	KbrnDecompNonZeroG0C0, KbrnDecompNonZeroG0C1, KbrnDecompNonZeroG1C0, KbrnDecompNonZeroG1C1
};

fn sqr_circuit() -> (KrbnG2C0, KrbnG2C1, KrbnG3C0, KrbnG3C1, KrbnG4C0, KrbnG4C1, KrbnG5C0, KrbnG5C1) {
    (KrbnG2C0 {}, KrbnG2C1 {}, KrbnG3C0 {}, KrbnG3C1 {}, KrbnG4C0 {}, KrbnG4C1 {}, KrbnG5C0 {}, KrbnG5C1 {})
}

// If Zero
// // Si = gi^2
// if g2.c0 == FieldUtils::zero() && g2.c1 == FieldUtils::zero() {
//     let (g0_c0, g0_c1, g1_c0, g1_c1) = decompress_zero_circuit(); 

//     let o = match (g0_c0, g0_c1, g1_c0, g1_c1).new_inputs()
//         .next(self.g3.c0.c0)
//         .next(self.g3.c1.c0)
//         .next(self.g4.c0.c0)
//         .next(self.g4.c1.c0)
//         .next(self.g5.c0.c0)
//         .next(self.g5.c1.c0)
//         .done().eval(m) {
//             Result::Ok(outputs) => { outputs },
//             Result::Err(_) => { panic!("Expected success") }
//     };

//     let mut g0 = fq2(o.get_output(g0_c0), o.get_output(g0_c1));
//     let g1 = fq2(o.get_output(g1_c0), o.get_output(g1_c1));
// //     // g1 = 2g4g5/g3
// //     let tg24g5 = x2(g4.mul(g5, m), m);
// //     let g1 = tg24g5.mul(g3.inv(m), m);

// //     // g0 = (2S1 - 3g3g4)ξ + 1
// //     let S1 = g1.sqr(m);
// //     let T_g3g4 = g3.mul(g4, m);
// //     let Tmp = (S1.sub(T_g3g4, m)).scale(TWO, m);
// //     let mut g0 = (Tmp.sub(T_g3g4, m)).mul_by_nonresidue(m);

//     g0 = g0.add(FieldUtils::one(), m);

//     Fq12 { c0: Fq6 { c0: g0, c1: g4, c2: g3 }, c1: Fq6 { c0: g2, c1: g1, c2: g5 } }
// } else {
fn decompress_zero_circuit() -> (KbrnDecompZeroG0C0, KbrnDecompZeroG0C1, KbrnDecompZeroG1C0, KbrnDecompZeroG1C1) {
	(KbrnDecompZeroG0C0 {}, KbrnDecompZeroG0C1 {}, KbrnDecompZeroG1C0 {}, KbrnDecompZeroG1C1 {})
}

// Else
// g1 = (S5ξ + 3S4 - 2g3)/4g2
// let S5xi = mul_by_xi_nz_as_circuit(g5.sqr(m), m);
// let S4 = g4.sqr(m);
// let Tmp = S4.sub(g3, m);
// let g1 = S5xi.add(S4.add(Tmp.add(Tmp, m), m), m);
// let g1 = g1.mul(x4(g2, m).inv(m), m);

// // // g0 = (2S1 + g2g5 - 3g3g4)ξ + 1
// let S1 = g1.sqr(m);
// let T_g3g4 = g3.mul(g4, m);
// let T_g2g5 = g2.mul(g5, m);
// let Tmp = (S1.sub(T_g3g4, m)).scale(TWO, m);
// let mut g0 = (Tmp.add(T_g2g5.sub(T_g3g4, m), m)).mul_by_nonresidue(m);
// }
fn decompress_non_zero_circuit() -> (KbrnDecompNonZeroG0C0, KbrnDecompNonZeroG0C1, KbrnDecompNonZeroG1C0, KbrnDecompNonZeroG1C1) {
	(KbrnDecompNonZeroG0C0 {}, KbrnDecompNonZeroG0C1 {}, KbrnDecompNonZeroG1C0 {}, KbrnDecompNonZeroG1C1 {})
}