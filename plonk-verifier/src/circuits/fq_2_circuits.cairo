use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use plonk_verifier::circuits::typedefs::add_sub_neg::{Add, Sub, Neg};
use plonk_verifier::circuits::typedefs::fq_2_type::{Fq2MulC0, Fq2MulC1, Fq2SqrC0, Fq2SqrC1, Fq2DivC0, Fq2DivC1, Fq2InvC0, Fq2InvC1};

fn add_circuit() -> (Add::<0, 2>, Add::<1, 3>) {
	(Add::<0, 2> {}, Add::<1, 3> {})
}

fn sub_circuit() -> (Sub::<0, 2>, Sub::<1, 3>) {
	(Sub::<0, 2> {}, Sub::<1, 3> {})
}

fn neg_circuit() -> (Neg::<0>, Neg::<1>) {
	(Neg::<0> {}, Neg::<1> {})
}

fn mul_circuit() -> (Fq2MulC0, Fq2MulC1) {
    (Fq2MulC0 {}, Fq2MulC1 {})
}

fn sqr_circuit() -> (Fq2SqrC0, Fq2SqrC1) {
    (Fq2SqrC0 {}, Fq2SqrC1 {})
}

fn div_circuit() -> (Fq2DivC0, Fq2DivC1) {
    (Fq2DivC0 {}, Fq2DivC1 {})
}

fn inv_circuit() -> (Fq2InvC0, Fq2InvC1) {
    (Fq2InvC0 {}, Fq2InvC1 {})
}