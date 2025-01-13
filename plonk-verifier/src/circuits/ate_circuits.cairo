use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use plonk_verifier::circuits::typedefs::ate_type::{Slope1_C0, Slope1_C1, X1_C0, X1_C1, Slope2_C0, Slope2_C1};

fn step_dbl_add_slopes_circuit() -> (Slope1_C0, Slope1_C1, X1_C0, X1_C1, Slope2_C0, Slope2_C1) {
	(Slope1_C0 {}, Slope1_C1 {}, X1_C0 {}, X1_C1 {}, Slope2_C0 {}, Slope2_C1 {})
}
