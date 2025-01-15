use core::circuit::{
    AddInputResultTrait, AddMod, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
    CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, circuit_add, circuit_inverse,
    circuit_mul, circuit_sub, u384,U384Serde
};

use plonk_verifier::circuits::{
    fq_circuits::{one_384, zero_384},
    fq_2_circuits::{
        add_circuit, div_circuit, inv_circuit, mul_circuit, neg_circuit, sqr_circuit, sub_circuit
    }
};
use plonk_verifier::curve::circuit_scale_9;
use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::fields::{fq, Fq, FqOps};
use plonk_verifier::fields::fq_generics::TFqPartialEq;
use plonk_verifier::traits::{FieldEqs, FieldOps, FieldUtils};

#[derive(Copy, Drop, Debug, Serde)]
struct Fq2 {
    c0: Fq,
    c1: Fq,
}

// #[inline(always)]
fn fq2(c0: u384, c1: u384) -> Fq2 {
    Fq2 { c0: fq(c0), c1: fq(c1), }
}

#[generate_trait]
impl Fq2Frobenius of Fq2FrobeniusTrait {
    // #[inline(always)]
    fn frob0(self: Fq2) -> Fq2 {
        self
    }

    // #[inline(always)]
    fn frob1(self: Fq2, m: CircuitModulus) -> Fq2 {
        self.conjugate(m)
    }
}

impl Fq2Utils of FieldUtils<Fq2, u384, CircuitModulus> {
    // #[inline(always)]
    fn one() -> Fq2 {
        fq2(ONE, ZERO)
    }

    // #[inline(always)]
    fn zero() -> Fq2 {
        fq2(ZERO, ZERO)
    }

    // #[inline(always)]
    fn scale(self: Fq2, by: u384, m: CircuitModulus) -> Fq2 {
        let a_c0 = CircuitElement::<CircuitInput<0>> {};
        let a_c1 = CircuitElement::<CircuitInput<1>> {};
        let scalar = CircuitElement::<CircuitInput<2>> {};

        let a_c0_scale = circuit_mul(a_c0, scalar);
        let a_c1_scale = circuit_mul(a_c1, scalar);

        let a0 = self.c0.c0;
        let a1 = self.c1.c0;
        let scalar = by;

        let outputs =
            match (a_c0_scale, a_c1_scale,)
                .new_inputs()
                .next(a0)
                .next(a1)
                .next(scalar)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let fq_c0 = Fq { c0: outputs.get_output(a_c0_scale) };
        let fq_c1 = Fq { c0: outputs.get_output(a_c1_scale) };

        let res = Fq2 { c0: fq_c0, c1: fq_c1 };
        res
    }

    // #[inline(always)]
    fn conjugate(self: Fq2, m: CircuitModulus) -> Fq2 {
        Fq2 { c0: self.c0, c1: self.c1.neg(m), }
    }

    // #[inline(always)]
    fn mul_by_nonresidue(self: Fq2, m: CircuitModulus) -> Fq2 {
        let Fq2 { c0: a0, c1: a1 } = self;
        // fq2(9, 1)
        Fq2 { //  a0 * b0 + a1 * βb1,
            c0: circuit_scale_9(a0, m).sub(a1, m), //  
             // c1: a0 * b1 + a1 * b0,
            c1: a0.add(circuit_scale_9(a1, m), m), //
        }
    }
}

impl Fq2Ops of FieldOps<Fq2, CircuitModulus> {
    // #[inline(always)]
    fn add(self: Fq2, rhs: Fq2, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = add_circuit();

        let outputs =
            match (c0, c1)
                .new_inputs()
                .next(self.c0.c0)
                .next(self.c1.c0)
                .next(rhs.c0.c0)
                .next(rhs.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(outputs.get_output(c0), outputs.get_output(c1))
    }

    // #[inline(always)]
    fn sub(self: Fq2, rhs: Fq2, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = sub_circuit();

        let outputs =
            match (c0, c1)
                .new_inputs()
                .next(self.c0.c0)
                .next(self.c1.c0)
                .next(rhs.c0.c0)
                .next(rhs.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(outputs.get_output(c0), outputs.get_output(c1))
    }

    // #[inline(always)]
    fn mul(self: Fq2, rhs: Fq2, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = mul_circuit();

        let outputs =
            match (c0, c1)
                .new_inputs()
                .next(self.c0.c0)
                .next(self.c1.c0)
                .next(rhs.c0.c0)
                .next(rhs.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(outputs.get_output(c0), outputs.get_output(c1))
    }

    // #[inline(always)]
    fn div(self: Fq2, rhs: Fq2, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = div_circuit();

        let outputs =
            match (c0, c1)
                .new_inputs()
                .next(self.c0.c0)
                .next(self.c1.c0)
                .next(rhs.c0.c0)
                .next(rhs.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(outputs.get_output(c0), outputs.get_output(c1))
    }

    // #[inline(always)]
    fn neg(self: Fq2, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = neg_circuit();

        let outputs = match (c0, c1).new_inputs().next(self.c0.c0).next(self.c1.c0).done().eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(outputs.get_output(c0), outputs.get_output(c1))
    }

    // #[inline(always)]
    fn sqr(self: Fq2, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = sqr_circuit();

        let outputs = match (c0, c1).new_inputs().next(self.c0.c0).next(self.c1.c0).done().eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(outputs.get_output(c0), outputs.get_output(c1))
    }

    // #[inline(always)]
    fn inv(self: Fq2, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = inv_circuit();

        let outputs = match (c0, c1).new_inputs().next(self.c0.c0).next(self.c1.c0).done().eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(outputs.get_output(c0), outputs.get_output(c1))
    }
}

impl FqEqs of FieldEqs<Fq2> {
    // #[inline(always)]
    fn eq(lhs: @Fq2, rhs: @Fq2) -> bool {
        lhs.c0 == rhs.c0 && lhs.c1 == rhs.c1
    }
}
