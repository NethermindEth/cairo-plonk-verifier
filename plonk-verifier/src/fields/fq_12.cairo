use plonk_verifier::traits::{FieldUtils, FieldOps};
//use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
use plonk_verifier::fields::{fq, fq2, Fq, Fq2, Fq2Ops, Fq6, fq6, Fq6Utils, Fq6Frobenius, Fq6Ops};
use plonk_verifier::fields::frobenius::fp12 as frob;
// use plonk_verifier::fields::print::{Fq6Display};
use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::curve::{FIELD, get_field_nz};
// use plonk_verifier::curve::{
//     u512, U512BnAdd, Tuple2Add, Tuple3Add, U512BnSub, Tuple2Sub, Tuple3Sub, u512_reduce,
//     mul_by_v_nz, mul_by_v_nz_as_circuit, U512Fq6Ops
// };
use plonk_verifier::curve::{mul_by_v_nz_as_circuit};
use core::circuit::conversions::from_u256;
use core::traits::TryInto;
use core::circuit::{
    CircuitElement, CircuitInput, circuit_add, circuit_sub, circuit_mul, circuit_inverse,
    EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus, AddInputResultTrait, CircuitInputs,
    EvalCircuitResult,
};

use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use debug::PrintTrait;
use plonk_verifier::circuits::fq_12_circuits::{add_circuit, mul_circuit, sqr_circuit, neg_circuit, sub_circuit};
#[derive(Copy, Drop, Debug)]
struct Fq12 {
    c0: Fq6,
    c1: Fq6,
}

#[inline(always)]
fn fq12(
    a0: u384,
    a1: u384,
    a2: u384,
    a3: u384,
    a4: u384,
    a5: u384,
    b0: u384,
    b1: u384,
    b2: u384,
    b3: u384,
    b4: u384,
    b5: u384
) -> Fq12 {
    Fq12 { c0: fq6(a0, a1, a2, a3, a4, a5), c1: fq6(b0, b1, b2, b3, b4, b5), }
}

#[generate_trait]
impl Fq12Frobenius of Fq12FrobeniusTrait {
    fn frob0(self: Fq12) -> Fq12 {
        self
    }

    fn frob1(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob1(),
            c1: c1.frob1().scale(fq2(frob::Q_1_C0, frob::Q_1_C1)),
        }
    }

    fn frob2(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        let Fq6 { c0: c10, c1: c11, c2: c12 } = c1.frob2();
        Fq12 {
            c0: c0.frob2(),
            c1: Fq6 {
                c0: c10.scale(frob::Q_2_C0),
                c1: c11.scale(frob::Q_2_C0),
                c2: c12.scale(frob::Q_2_C0),
            },
        }
    }

    fn frob3(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob3(),
            c1: c1.frob3().scale(fq2(frob::Q_3_C0, frob::Q_3_C1)),
        }
    }

    fn frob4(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob4(),
            c1: c1.frob4().scale(fq2(frob::Q_4_C0, frob::Q_4_C1)),
        }
    }

    fn frob5(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob5(),
            c1: c1.frob5().scale(fq2(frob::Q_5_C0, frob::Q_5_C1)),
        }
    }

    fn frob6(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob0(),
            c1: c1.frob0().scale(fq2(frob::Q_6_C0, frob::Q_6_C1)),
        }
    }

    fn frob7(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob1(),
            c1: c1.frob1().scale(fq2(frob::Q_7_C0, frob::Q_7_C1)),
        }
    }

    fn frob8(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob2(),
            c1: c1.frob2().scale(fq2(frob::Q_8_C0, frob::Q_8_C1)),
        }
    }

    fn frob9(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob3(),
            c1: c1.frob3().scale(fq2(frob::Q_9_C0, frob::Q_9_C1)),
        }
    }

    fn frob10(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob4(),
            c1: c1.frob4().scale(fq2(frob::Q_10_C0, frob::Q_10_C1)),
        }
    }


    fn frob11(self: Fq12) -> Fq12 {
        let Fq12 { c0, c1 } = self;
        Fq12 {
            c0: c0.frob5(),
            c1: c1.frob5().scale(fq2(frob::Q_11_C0, frob::Q_11_C1)),
        }
    }
}

impl Fq12Utils of FieldUtils<Fq12, Fq6> {
    #[inline(always)]
    fn one() -> Fq12 {
        Fq12 { c0: FieldUtils::one(), c1: FieldUtils::zero(), }
    }

    #[inline(always)]
    fn zero() -> Fq12 {
        Fq12 { c0: FieldUtils::zero(), c1: FieldUtils::zero(), }
    }

    #[inline(always)]
    fn scale(self: Fq12, by: Fq6) -> Fq12 {
        assert(false, 'no_impl: fq12 scale');
        Self::one()
    }

    fn conjugate(self: Fq12) -> Fq12 {
        Fq12 { c0: self.c0, c1: self.c1.neg(), }
    }

    fn mul_by_nonresidue(self: Fq12,) -> Fq12 {
        assert(false, 'no_impl: fq12 non residue');
        Self::one()
    }

    fn frobenius_map(self: Fq12, power: usize) -> Fq12 {
        let rem = power % 12;
        if rem == 1 {
            self.frob1()
        } else if rem == 2 {
            self.frob2()
        } else if rem == 3 {
            self.frob3()
        } else if rem == 4 {
            self.frob4()
        } else if rem == 5 {
            self.frob5()
        } else if rem == 6 {
            self.frob6()
        } else if rem == 7 {
            self.frob7()
        } else if rem == 8 {
            self.frob8()
        } else if rem == 9 {
            self.frob9()
        } else if rem == 10 {
            self.frob10()
        } else if rem == 11 {
            self.frob11()
        } else {
            self.frob0()
        }
    }
}

// type Fq6U512 = ((u512, u512), (u512, u512), (u512, u512));

impl Fq12Ops of FieldOps<Fq12, CircuitModulus> {
    fn add(self: Fq12, rhs: Fq12, m: CircuitModulus) -> Fq12 {
        let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11) = add_circuit(); 

        let outputs = match (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11).new_inputs()
            .next(self.c0.c0.c0.c0)
            .next(self.c0.c0.c1.c0)
            .next(self.c0.c1.c0.c0)
            .next(self.c0.c1.c1.c0)
            .next(self.c0.c2.c0.c0)
            .next(self.c0.c2.c1.c0)
            .next(self.c1.c0.c0.c0)
            .next(self.c1.c0.c1.c0)
            .next(self.c1.c1.c0.c0)
            .next(self.c1.c1.c1.c0)
            .next(self.c1.c2.c0.c0)
            .next(self.c1.c2.c1.c0)
            .next(rhs.c0.c0.c0.c0)
            .next(rhs.c0.c0.c1.c0)
            .next(rhs.c0.c1.c0.c0)
            .next(rhs.c0.c1.c1.c0)
            .next(rhs.c0.c2.c0.c0)
            .next(rhs.c0.c2.c1.c0)
            .next(rhs.c1.c0.c0.c0)
            .next(rhs.c1.c0.c1.c0)
            .next(rhs.c1.c1.c0.c0)
            .next(rhs.c1.c1.c1.c0)
            .next(rhs.c1.c2.c0.c0)
            .next(rhs.c1.c2.c1.c0)
            .done().eval(m) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        Fq12 { 
            c0: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } }, 
            c1: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c6) }, c1: Fq { c0: outputs.get_output(c7) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c8) }, c1: Fq { c0: outputs.get_output(c9) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c10) }, c1: Fq { c0: outputs.get_output(c11) } } 
            } 
        } 
    }

    fn sub(self: Fq12, rhs: Fq12) -> Fq12 {
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11) = sub_circuit(); 

        let outputs = match (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11).new_inputs()
            .next(self.c0.c0.c0.c0)
            .next(self.c0.c0.c1.c0)
            .next(self.c0.c1.c0.c0)
            .next(self.c0.c1.c1.c0)
            .next(self.c0.c2.c0.c0)
            .next(self.c0.c2.c1.c0)
            .next(self.c1.c0.c0.c0)
            .next(self.c1.c0.c1.c0)
            .next(self.c1.c1.c0.c0)
            .next(self.c1.c1.c1.c0)
            .next(self.c1.c2.c0.c0)
            .next(self.c1.c2.c1.c0)
            .next(rhs.c0.c0.c0.c0)
            .next(rhs.c0.c0.c1.c0)
            .next(rhs.c0.c1.c0.c0)
            .next(rhs.c0.c1.c1.c0)
            .next(rhs.c0.c2.c0.c0)
            .next(rhs.c0.c2.c1.c0)
            .next(rhs.c1.c0.c0.c0)
            .next(rhs.c1.c0.c1.c0)
            .next(rhs.c1.c1.c0.c0)
            .next(rhs.c1.c1.c1.c0)
            .next(rhs.c1.c2.c0.c0)
            .next(rhs.c1.c2.c1.c0)
            .done().eval(modulus) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        Fq12 { 
            c0: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } }, 
            c1: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c6) }, c1: Fq { c0: outputs.get_output(c7) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c8) }, c1: Fq { c0: outputs.get_output(c9) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c10) }, c1: Fq { c0: outputs.get_output(c11) } } 
            } 
        } 
    }

    fn div(self: Fq12, rhs: Fq12) -> Fq12 {
        self.mul(rhs.inv())
    }

    fn neg(self: Fq12) -> Fq12 {
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11) = neg_circuit(); 

        let outputs = match (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11).new_inputs()
            .next(self.c0.c0.c0.c0)
            .next(self.c0.c0.c1.c0)
            .next(self.c0.c1.c0.c0)
            .next(self.c0.c1.c1.c0)
            .next(self.c0.c2.c0.c0)
            .next(self.c0.c2.c1.c0)
            .next(self.c1.c0.c0.c0)
            .next(self.c1.c0.c1.c0)
            .next(self.c1.c1.c0.c0)
            .next(self.c1.c1.c1.c0)
            .next(self.c1.c2.c0.c0)
            .next(self.c1.c2.c1.c0)
            .done().eval(modulus) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        Fq12 { 
            c0: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } }, 
            c1: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c6) }, c1: Fq { c0: outputs.get_output(c7) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c8) }, c1: Fq { c0: outputs.get_output(c9) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c10) }, c1: Fq { c0: outputs.get_output(c11) } } 
            } 
        } 
    }

    fn eq(lhs: @Fq12, rhs: @Fq12) -> bool {
        Fq6Ops::eq(lhs.c0, rhs.c0) && Fq6Ops::eq(lhs.c1, rhs.c1)
    }

    fn mul(self: Fq12, rhs: Fq12) -> Fq12 {
        core::internal::revoke_ap_tracking();

        // let Fq12 { c0: a0, c1: a1 } = self;
        // let Fq12 { c0: b0, c1: b1 } = rhs;

        // let U = Fq6Ops::mul(a0, b0);
        // let V = Fq6Ops::mul(a1, b1);
        // let c0 = Fq6Ops::add(mul_by_v_nz_as_circuit(V), U);
        // let c1 = Fq6Ops::sub(Fq6Ops::sub(Fq6Ops::mul(a0 + a1, b0 + b1), U), V);
        // Fq12 { c0: c0, c1: c1 }

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11) = mul_circuit(); 

        let outputs = match (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11).new_inputs()
            .next(self.c0.c0.c0.c0)
            .next(self.c0.c0.c1.c0)
            .next(self.c0.c1.c0.c0)
            .next(self.c0.c1.c1.c0)
            .next(self.c0.c2.c0.c0)
            .next(self.c0.c2.c1.c0)
            .next(self.c1.c0.c0.c0)
            .next(self.c1.c0.c1.c0)
            .next(self.c1.c1.c0.c0)
            .next(self.c1.c1.c1.c0)
            .next(self.c1.c2.c0.c0)
            .next(self.c1.c2.c1.c0)
            .next(rhs.c0.c0.c0.c0)
            .next(rhs.c0.c0.c1.c0)
            .next(rhs.c0.c1.c0.c0)
            .next(rhs.c0.c1.c1.c0)
            .next(rhs.c0.c2.c0.c0)
            .next(rhs.c0.c2.c1.c0)
            .next(rhs.c1.c0.c0.c0)
            .next(rhs.c1.c0.c1.c0)
            .next(rhs.c1.c1.c0.c0)
            .next(rhs.c1.c1.c1.c0)
            .next(rhs.c1.c2.c0.c0)
            .next(rhs.c1.c2.c1.c0)
            .done().eval(modulus) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        Fq12 { 
            c0: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } }, 
            c1: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c6) }, c1: Fq { c0: outputs.get_output(c7) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c8) }, c1: Fq { c0: outputs.get_output(c9) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c10) }, c1: Fq { c0: outputs.get_output(c11) } } 
            } 
        } 
    }

    fn sqr(self: Fq12) -> Fq12 {
        core::internal::revoke_ap_tracking();
        // let Fq12 { c0: a0, c1: a1 } = self;
        // let V = Fq6Ops::mul(a0, a1);
        // let c0 = Fq6Ops::sub(
        //     Fq6Ops::sub(
        //         Fq6Ops::mul(Fq6Ops::add(a0, a1), Fq6Ops::add(a0, a1.mul_by_nonresidue())), V
        //     ),
        //     mul_by_v_nz_as_circuit(V)
        // );
        // let c1 = Fq6Ops::add(V, V);

        // Fq12 { c0: c0, c1: c1 }

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11) = sqr_circuit();

        let outputs = match (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11).new_inputs()
            .next(self.c0.c0.c0.c0)
            .next(self.c0.c0.c1.c0)
            .next(self.c0.c1.c0.c0)
            .next(self.c0.c1.c1.c0)
            .next(self.c0.c2.c0.c0)
            .next(self.c0.c2.c1.c0)
            .next(self.c1.c0.c0.c0)
            .next(self.c1.c0.c1.c0)
            .next(self.c1.c1.c0.c0)
            .next(self.c1.c1.c1.c0)
            .next(self.c1.c2.c0.c0)
            .next(self.c1.c2.c1.c0)
            .done().eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        Fq12 { 
            c0: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } }, 
            c1: Fq6 { 
                c0: Fq2 { c0: Fq { c0: outputs.get_output(c6) }, c1: Fq { c0: outputs.get_output(c7) } }, 
                c1: Fq2 { c0: Fq { c0: outputs.get_output(c8) }, c1: Fq { c0: outputs.get_output(c9) } }, 
                c2: Fq2 { c0: Fq { c0: outputs.get_output(c10) }, c1: Fq { c0: outputs.get_output(c11) } } 
            } 
        } 
    }

    fn inv(self: Fq12) -> Fq12 {
        core::internal::revoke_ap_tracking();
        let t = (self.c0.sqr().sub(mul_by_v_nz_as_circuit(self.c1.sqr()))).inv();

        Fq12 { c0: self.c0.mul(t), c1: (self.c1.mul(t)).neg() }
    }
}
fn fq12_karatsuba_sqr(a: Fq12) -> Fq12 {
    let m = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    core::internal::revoke_ap_tracking();
    let Fq12 { c0: a0, c1: a1 } = a;
    // Karatsuba squaring
    // v0 = a0² , v1 = a1²
    let V0 = a0.sqr();
    let V1 = a1.sqr();

    // c0 = v0 + βv1
    let C0 = Fq6Ops::add(V0, mul_by_v_nz_as_circuit(V1), m);
    // c1 = (a0 +a1)² - v0 - v1,
    let C1 = Fq6Ops::add(a0, a1, m).sqr().sub(V0).sub(V1);
    Fq12 { c0: C0, c1: C1 }
}
