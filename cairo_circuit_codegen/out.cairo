use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
let slope_x = CE::<S::<M::<S::<CI::<6>, CI::<2>>, M::<S::<CI::<4>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>, M::<S::<CI::<7>, CI::<3>>, M::<S::<CI::<5>, CI::<1>>, S::<S::<CI::<0>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>>>> {};
let slope_y = CE::<S::<M::<A::<S::<CI::<6>, CI::<2>>, S::<CI::<7>, CI::<3>>>, A::<M::<S::<CI::<4>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>,M::<S::<CI::<5>, CI::<1>>, S::<S::<CI::<0>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>>>, A::<M::<S::<CI::<6>, CI::<2>>, M::<S::<CI::<4>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>, M::<S::<CI::<7>, CI::<3>>, M::<S::<CI::<5>, CI::<1>>, S::<S::<CI::<0>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>>>>> {};
