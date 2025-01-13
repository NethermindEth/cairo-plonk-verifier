use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use plonk_verifier::circuits::typedefs::line_fn_step_dbl_add_type::{Lf1SlopeC0, Lf1SlopeC1, Lf1C0, Lf1C1, Lf2SlopeC0, Lf2SlopeC1, Lf2C0, Lf2C1, x0, x1, y0, y1};

fn line_fn_step_dbl_add_circuit() -> (Lf1SlopeC0, Lf1SlopeC1, Lf1C0, Lf1C1, Lf2SlopeC0, Lf2SlopeC1, Lf2C0, Lf2C1, x0, x1, y0, y1) {
	(
		Lf1SlopeC0 {}, Lf1SlopeC1 {}, Lf1C0 {}, Lf1C1 {}, Lf2SlopeC0 {}, Lf2SlopeC1 {}, Lf2C0 {}, Lf2C1 {}, x0 {}, x1 {}, y0 {}, y1 {}
	)
}