use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use plonk_verifier::circuits::typedefs::fq_12_squaring_type::{KrbnG2C0, KrbnG2C1, KrbnG3C0, KrbnG3C1, KrbnG4C0, KrbnG4C1, KrbnG5C0, KrbnG5C1};

fn sqr_circuit() -> (KrbnG2C0, KrbnG2C1, KrbnG3C0, KrbnG3C1, KrbnG4C0, KrbnG4C1, KrbnG5C0, KrbnG5C1) {
    (KrbnG2C0 {}, KrbnG2C1 {}, KrbnG3C0 {}, KrbnG3C1 {}, KrbnG4C0 {}, KrbnG4C1 {}, KrbnG5C0 {}, KrbnG5C1 {})
}