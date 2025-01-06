use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};

type Add<const IDX0: usize, const IDX1: usize> = CE<A<CI<IDX0>, CI<IDX1>>>;
type Sub<const IDX0: usize, const IDX1: usize> = CE<S<CI<IDX0>, CI<IDX1>>>;
type Neg<const IDX: usize> = CE<S<S<CI<0>, CI<0>>, CI<IDX>>>;