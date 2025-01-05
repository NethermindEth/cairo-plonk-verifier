use core::circuit::{
    AddInputResultTrait, AddMod, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
    CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, circuit_add, circuit_inverse,
    circuit_mul, circuit_sub, u384,
};
use core::traits::TryInto;

use plonk_verifier::circuits::fq_circuits::{one_384, zero_384};
use plonk_verifier::curve::{circuit_scale_9};
use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::fields::{fq, Fq, FqOps};
use plonk_verifier::fields::fq_generics::TFqPartialEq;
use plonk_verifier::traits::{FieldEqs, FieldOps, FieldUtils};

#[derive(Copy, Drop, Debug)]
struct Fq2 {
    c0: Fq,
    c1: Fq,
}

#[inline(always)]
fn fq2(c0: u384, c1: u384) -> Fq2 {
    Fq2 { c0: fq(c0), c1: fq(c1), }
}


#[generate_trait]
impl Fq2Frobenius of Fq2FrobeniusTrait {
    #[inline(always)]
    fn frob0(self: Fq2) -> Fq2 {
        self
    }

    #[inline(always)]
    fn frob1(self: Fq2, m: CircuitModulus) -> Fq2 {
        self.conjugate(m)
    }
}

impl Fq2Utils of FieldUtils<Fq2, u384, CircuitModulus> {
    #[inline(always)]
    fn one() -> Fq2 {
        fq2(one_384, zero_384)
    }

    #[inline(always)]
    fn zero() -> Fq2 {
        fq2(zero_384, zero_384)
    }

    #[inline(always)]
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

    #[inline(always)]
    fn conjugate(self: Fq2, m: CircuitModulus) -> Fq2 {
        Fq2 { c0: self.c0, c1: self.c1.neg(m), }
    }
    
    #[inline(always)]
    fn mul_by_nonresidue(self: Fq2, m: CircuitModulus) -> Fq2 {
        let Fq2 { c0: a0, c1: a1 } = self;
        // fq2(9, 1)
        Fq2 { //  a0 * b0 + a1 * βb1,
            c0: circuit_scale_9(a0, m).sub(a1, m), //  
             // c1: a0 * b1 + a1 * b0,
            c1: a0.add(circuit_scale_9(a1, m), m), //
        }
    }

    #[inline(always)]
    fn frobenius_map(self: Fq2, power: usize, m: CircuitModulus) -> Fq2 {
        if power % 2 == 0 {
            self
        } else {
            self.conjugate(m)
        }
    }
}

impl Fq2Ops of FieldOps<Fq2, CircuitModulus> {
    #[inline(always)]
    fn add(self: Fq2, rhs: Fq2, m: CircuitModulus) -> Fq2 {
        Fq2 { c0: self.c0.add(rhs.c0, m), c1: self.c1.add(rhs.c1, m) }
    }

    #[inline(always)]
    fn sub(self: Fq2, rhs: Fq2, m: CircuitModulus) -> Fq2 {
        Fq2 { c0: self.c0.sub(rhs.c0, m), c1: self.c1.sub(rhs.c1, m), }
    }

    #[inline(always)]
    fn mul(self: Fq2, rhs: Fq2, m: CircuitModulus) -> Fq2 {
        let a0 = CircuitElement::<CircuitInput<0>> {};
        let a1 = CircuitElement::<CircuitInput<1>> {};
        let b0 = CircuitElement::<CircuitInput<2>> {};
        let b1 = CircuitElement::<CircuitInput<3>> {};

        let t0 = circuit_mul(a0, b0);
        let t1 = circuit_mul(a1, b1);
        let a0_add_a1 = circuit_add(a0, a1);
        let b0_add_b1 = circuit_add(b0, b1);
        let t2 = circuit_mul(a0_add_a1, b0_add_b1);
        let t3 = circuit_add(t0, t1);
        let t3 = circuit_sub(t2, t3);
        let t4 = circuit_sub(t0, t1);

        let a0 = self.c0.c0;
        let a1 = self.c1.c0;
        let b0 = rhs.c0.c0;
        let b1 = rhs.c1.c0;

        let outputs =
            match (t3, t4,).new_inputs().next(a0).next(a1).next(b0).next(b1).done().eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let fq_c0 = Fq { c0: outputs.get_output(t4) };
        let fq_c1 = Fq { c0: outputs.get_output(t3) };

        let fq_t = Fq2 { c0: fq_c0, c1: fq_c1 };
        fq_t
    }

    #[inline(always)]
    fn div(self: Fq2, rhs: Fq2, m: CircuitModulus) -> Fq2 {
        let inv_rhs = rhs.inv(m);
        let res = Self::mul(self, inv_rhs, m);
        res
    }

    #[inline(always)]
    fn neg(self: Fq2, m: CircuitModulus) -> Fq2 {
        Fq2 { c0: self.c0.neg(m), c1: self.c1.neg(m), }
    }

    #[inline(always)]
    fn sqr(self: Fq2, m: CircuitModulus) -> Fq2 {
        // // Aranha sqr_u + 2r
        let a0 = CircuitElement::<CircuitInput<0>> {};
        let a1 = CircuitElement::<CircuitInput<1>> {};
        let t0 = circuit_add(a0, a1);
        let t1 = circuit_sub(a0, a1);
        let T0 = circuit_mul(t0, t1);
        let t0 = circuit_add(a0, a0);
        let T1 = circuit_mul(t0, a1);
        let a0 = self.c0.c0;
        let a1 = self.c1.c0;

        let outputs = match (T0, T1,).new_inputs().next(a0).next(a1).done().eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let fq_t0 = Fq { c0: outputs.get_output(T0) };
        let fq_t1 = Fq { c0: outputs.get_output(T1) };

        let fq_t = Fq2 { c0: fq_t0, c1: fq_t1 };
        fq_t
    }


    #[inline(always)]
    fn inv(self: Fq2, m: CircuitModulus) -> Fq2 {
        let Fq2 { c0, c1 } = self;
        let t = c0.sqr(m).add(c1.sqr(m), m).inv(m);
        Fq2 { c0: c0.mul(t, m), c1: c1.mul(t.neg(m), m) }
    }
}

impl FqEqs of FieldEqs<Fq2> {
    #[inline(always)]
    fn eq(lhs: @Fq2, rhs: @Fq2) -> bool {
        lhs.c0 == rhs.c0 && lhs.c1 == rhs.c1
    }
}

