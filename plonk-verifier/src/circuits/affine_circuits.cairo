use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use plonk_verifier::circuits::typedefs::affine::{
    AffFq2YSlopeC0, AffFq2YSlopeC1, AffFq2ChordC0, AffFq2ChordC1,
    AffFq2PTSlopeX0, AffFq2PTSlopeX1, AffFq2PTSlopeY0, AffFq2PTSlopeY1,
    AffFq2AddX0, AffFq2AddX1, AffFq2AddY0, AffFq2AddY1,
    AffFq2DoubleX0, AffFq2DoubleX1, AffFq2DoubleY0, AffFq2DoubleY1,
    AffFq2TanC0, AffFq2TanC1
};

fn fq2_y_on_slope_circuit() -> (AffFq2YSlopeC0, AffFq2YSlopeC1) {
    (AffFq2YSlopeC0 {}, AffFq2YSlopeC1 {})
}

fn fq2_pt_on_slope_circuit() -> (AffFq2PTSlopeX0, AffFq2PTSlopeX1, AffFq2PTSlopeY0, AffFq2PTSlopeY1) {
    (AffFq2PTSlopeX0 {}, AffFq2PTSlopeX1 {}, AffFq2PTSlopeY0 {}, AffFq2PTSlopeY1 {})
}

fn fq2_chord_circuit() -> (AffFq2ChordC0, AffFq2ChordC1) {
    (AffFq2ChordC0 {}, AffFq2ChordC1 {})
}

fn fq2_add_circuit() -> (AffFq2AddX0, AffFq2AddX1, AffFq2AddY0, AffFq2AddY1) {
    (AffFq2AddX0 {}, AffFq2AddX1 {}, AffFq2AddY0 {}, AffFq2AddY1 {})
}

fn fq2_tangent_circuit() -> (AffFq2TanC0, AffFq2TanC1) {
    (AffFq2TanC0 {}, AffFq2TanC1 {})
}

fn fq2_double_circuit() -> (AffFq2DoubleX0, AffFq2DoubleX1, AffFq2DoubleY0, AffFq2DoubleY1) {
    (AffFq2DoubleX0 {}, AffFq2DoubleX1 {}, AffFq2DoubleY0 {}, AffFq2DoubleY1 {})
}