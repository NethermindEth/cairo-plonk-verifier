use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};

type Add<const IDX1: usize, const IDX2: usize> = CE<A<CI<IDX1>, CI<IDX2>>>;
type Sub<const IDX1: usize, const IDX2: usize> = CE<S<CI<IDX1>, CI<IDX2>>>;
type Neg<const IDX: usize> = CE<S<S<CI<0>, CI<0>>, CI<IDX>>>;