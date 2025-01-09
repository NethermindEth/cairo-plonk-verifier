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

fn decompress_zero_circuit() -> (KbrnDecompZeroG0C0, KbrnDecompZeroG0C1, KbrnDecompZeroG1C0, KbrnDecompZeroG1C1) {
	(KbrnDecompZeroG0C0 {}, KbrnDecompZeroG0C1 {}, KbrnDecompZeroG1C0 {}, KbrnDecompZeroG1C1 {})
}
fn decompress_non_zero_circuit() -> (KbrnDecompNonZeroG0C0, KbrnDecompNonZeroG0C1, KbrnDecompNonZeroG1C0, KbrnDecompNonZeroG1C1) {
	(KbrnDecompNonZeroG0C0 {}, KbrnDecompNonZeroG0C1 {}, KbrnDecompNonZeroG1C0 {}, KbrnDecompNonZeroG1C1 {})
}