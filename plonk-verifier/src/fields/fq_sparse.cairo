use core::array::ArrayTrait;
use core::circuit::{
    AddInputResultTrait, AddModGate as A, CircuitElement, CircuitElement as CE, CircuitInput,
    CircuitInput as CI, CircuitInputs, CircuitModulus, CircuitOutputsTrait, EvalCircuitResult,
    EvalCircuitTrait, InverseGate as I, MulModGate as M, SubModGate as S, circuit_add,
    circuit_inverse, circuit_mul, circuit_sub, u384,
};
use core::traits::TryInto;

use plonk_verifier::circuits::sparse_circuits::{mul_034_by_034_circuit, mul_01_circuit};
use plonk_verifier::curve::{constants::FIELD_U384, mul_by_v_nz_as_circuit, mul_by_xi_nz_as_circuit};
use plonk_verifier::fields::{
    fq, fq2, fq6, fq12, Fq, Fq2, Fq2Ops, Fq6, Fq12, Fq12Frobenius, Fq12Squaring, FieldOps, FieldUtils,
};
use plonk_verifier::fields::fq_generics::TFqPartialEq;

// Sparse Fp12 element containing only c3 and c4 Fq2s (c0 is 1)
// Equivalent to,
// Fq12{
//   c0: Fq6{c0: 1, c1: 0, c2: 0},
//   c1: Fq6{c0: c3, c1: c4, c2: 0},
// }
#[derive(Copy, Drop,)]
struct Fq12Sparse034 {
    c3: Fq2,
    c4: Fq2,
}

// Sparse Fp6 element derived from second Fq6 of a sparse Fq12 034
// containing only c0 and c1 Fq2s from c3 and c4 of sparse Fq12 034
// Equivalent to,
// Fq6{c0: c3, c1: c4, c2: 0}
#[derive(Copy, Drop,)]
struct Fq6Sparse01 {
    c0: Fq2,
    c1: Fq2,
}

// #[inline(always)]
fn sparse_fq6(c0: Fq2, c1: Fq2) -> Fq6Sparse01 {
    Fq6Sparse01 { c0, c1 }
}

// Sparse Fp12 element containing c0, c1, c2, c3 and c4 Fq2s
#[derive(Copy, Drop,)]
struct Fq12Sparse01234 {
    c0: Fq6,
    c1: Fq6Sparse01,
}

impl Fq12Sparse034PartialEq of PartialEq<Fq12Sparse034> {
    // #[inline(always)]
    fn eq(lhs: @Fq12Sparse034, rhs: @Fq12Sparse034) -> bool {
        lhs.c3 == rhs.c3 && lhs.c4 == rhs.c4
    }

    // #[inline(always)]
    fn ne(lhs: @Fq12Sparse034, rhs: @Fq12Sparse034) -> bool {
        !Self::eq(lhs, rhs)
    }
}

impl Fq12Sparse01234PartialEq of PartialEq<Fq12Sparse01234> {
    // #[inline(always)]
    fn eq(lhs: @Fq12Sparse01234, rhs: @Fq12Sparse01234) -> bool {
        lhs.c0 == rhs.c0 && lhs.c1.c0 == rhs.c1.c0 && lhs.c1.c1 == rhs.c1.c1
    }

    // #[inline(always)]
    fn ne(lhs: @Fq12Sparse01234, rhs: @Fq12Sparse01234) -> bool {
        !Self::eq(lhs, rhs)
    }
}

// Sparse Fp12 element containing only c3 and c4 Fq2s (c0 is 1)
// Equivalent to,
// Fq12{
//   c0: Fq6{c0: 1, c1: 0, c2: 0},
//   c1: Fq6{c0: c3, c1: c4, c2: 0},
// }
#[generate_trait]
impl FqSparse of FqSparseTrait {
    
    // Fq6 sparse 
    // Mul Fq6 with a sparse Fq6 01 derived from a sparse 034 Fq12
    // Same as Fq6 u_mul but with b2 as zero (and associated ops removed)
    // #[inline(always)]
    fn mul_01(self: Fq6, rhs: Fq6Sparse01, m: CircuitModulus) -> Fq6 {
        let (c0, c1, c2, c3, c4, c5) = mul_01_circuit(); 

        let outputs = match (c0, c1, c2, c3, c4, c5, ).new_inputs()
            .next(self.c0.c0.c0)
            .next(self.c0.c1.c0)
            .next(self.c1.c0.c0)
            .next(self.c1.c1.c0)
            .next(self.c2.c0.c0)
            .next(self.c2.c1.c0)
            .next(rhs.c0.c0.c0)
            .next(rhs.c0.c1.c0)
            .next(rhs.c1.c0.c0)
            .next(rhs.c1.c1.c0)
            .done().eval(m) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        Fq6 { 
            c0: Fq2 { c0: Fq { c0: outputs.get_output(c0) }, c1: Fq { c0: outputs.get_output(c1) } }, 
            c1: Fq2 { c0: Fq { c0: outputs.get_output(c2) }, c1: Fq { c0: outputs.get_output(c3) } }, 
            c2: Fq2 { c0: Fq { c0: outputs.get_output(c4) }, c1: Fq { c0: outputs.get_output(c5) } } 
        }
    }

    // // Mul Fq6 with a sparse Fq6 01 derived from a sparse 034 Fq12
    // // Same as Fq6 u_mul but with a2 and b2 as zero (and associated ops removed)
    // // #[inline(always)]
    // fn mul_01_by_01(self: Fq6Sparse01, rhs: Fq6Sparse01, m: CircuitModulus) -> Fq6 {
    //     // Input:a = (a0 + a1v) and b = (b0 + b1v) ∈ Fp6
    //     // Output:c = a · b = (c0 + c1v + c2v2) ∈ Fp6
    //     let Fq6Sparse01 { c0: a0, c1: a1, } = self;
    //     let Fq6Sparse01 { c0: b0, c1: b1, } = rhs;

    //     // a2 and b2 is zero so all ops associated ar removed

    //     // v0 = a0b0, v1 = a1b1, v2 = a2b2
    //     // let (V0, V1,) = (a0.mul(b0), a1.mul(b1),);

    //     // c0 = v0 + ξ((a1 + a2)(b1 + b2) - v1 - v2)
    //     // c0 = v0 + ξ((a1b1) - v1 - v2)
    //     // c0 = v0 + ξ(v1 - v1 - v2)
    //     // c0 = v0, v2 is 0

    //     // c1 =(a0 + a1)(b0 + b1) - v0 - v1 + ξv2
    //     // let C1 = a0.u_add(a1).mul(b0.u_add(b1)) - V0 - V1;
    //     // c2 = (a0 + a2)(b0 + b2) - v0 + v1 - v2,
    //     // c2 = a0b0 - v0 + v1 - v2,
    //     // c2 = v0 - v0 + v1 - v2,
    //     // c2 = v1, v2 is 0

    //     let v0 = Fq2Ops::mul(a0, b0, m);
    //     let v1 = Fq2Ops::mul(a1, b1, m);
    //     let c1 = Fq2Ops::sub(
    //         Fq2Ops::sub(Fq2Ops::mul(Fq2Ops::add(a0, a1, m), Fq2Ops::add(b0, b1, m), m), v0, m), v1, m
    //     );

    //     Fq6 { c0: v0, c1: c1, c2: v1 }
    // }
       
    // Fq12 sparse 
    // Mul a sparse 034 Fq12 by another 034 Fq12 resulting in a sparse 01234
    // https://github.com/Consensys/gnark/blob/v0.9.1/std/algebra/emulated/fields_bn254/e12_pairing.go#L150
    // // #[inline(always)]
    fn mul_034_by_034(self: Fq12Sparse034, rhs: Fq12Sparse034, m: CircuitModulus) -> Fq12Sparse01234 {
        let (M034034_zC0B0C0, M034034_zC0B0C1, M034034_C3D3C0, M034034_C3D3C1, M034034_X34C0, M034034_X34C1, M034034_X03C0, M034034_X03C1, M034034_X04C0, M034034_X04C1) = mul_034_by_034_circuit(); 
        
        let o = match (M034034_zC0B0C0, M034034_zC0B0C1, M034034_C3D3C0, M034034_C3D3C1, M034034_X34C0, M034034_X34C1, M034034_X03C0, M034034_X03C1, M034034_X04C0, M034034_X04C1).new_inputs()
            .next(self.c3.c0.c0)
            .next(self.c3.c1.c0)
            .next(self.c4.c0.c0)
            .next(self.c4.c1.c0)
            .next(rhs.c3.c0.c0)
            .next(rhs.c3.c1.c0)
            .next(rhs.c4.c0.c0)
            .next(rhs.c4.c1.c0)
            .done().eval(m) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        let mut zC0B0 = fq2(o.get_output(M034034_zC0B0C0), o.get_output(M034034_zC0B0C1));
        let c3d3 = fq2(o.get_output(M034034_C3D3C0), o.get_output(M034034_C3D3C1));
        let x34 = fq2(o.get_output(M034034_X34C0), o.get_output(M034034_X34C1));
        let x03 = fq2(o.get_output(M034034_X03C0), o.get_output(M034034_X03C1));
        let x04 = fq2(o.get_output(M034034_X04C0), o.get_output(M034034_X04C1));
        
        zC0B0.c0 = zC0B0.c0.add(FieldUtils::one(), m); 
        Fq12Sparse01234 {
            c0: Fq6 { c0: zC0B0, c1: c3d3, c2: x34 }, c1: Fq6Sparse01 { c0: x03, c1: x04 },
        }
    }
    
    // Mul a sparse 034 Fq12 by another 034 Fq12 resulting in a sparse 01234
    // https://github.com/Consensys/gnark/blob/v0.9.1/std/algebra/emulated/fields_bn254/e12_pairing.go#L150
    // // #[inline(always)]
    // fn sqr_034(self: Fq12Sparse034, m: CircuitModulus) -> Fq12Sparse01234 {
    //     let Fq12Sparse034 { c3: c3, c4: c4 } = self;
    //     // x3 = c3 * c3
    //     let c3_sq = c3.sqr(m);
    //     // x4 = c4 * d4
    //     let c4_sq = c4.sqr(m);
    //     // x04 = c4 + c4
    //     let x04 = c4.add(c4, m);
    //     // x03 = c3 + c3
    //     let x03 = c3.add(c3, m);
    //     // tmp = c3 + c4
    //     // x34 = c3 + c4
    //     // x34 = x34 * tmp
    //     let x34 = c3.add(c4, m).sqr(m); // c3_sq + c3c4 + c4c3 + c4_sq
    //     // x34 = x34 - x3
    //     let x34 = x34.sub(c3_sq, m); // c3c4 + c4c3 + c4_sq
    //     // x34 = x34 - x4
    //     let x34 = x34.sub(c4_sq, m); // c3c4 + c4c3

    //     // zC0B0 = ξx4
    //     // zC0B0 = zC0B0 + 1
    //     // zC0B1 = x3
    //     // zC0B2 = x34
    //     // zC1B0 = x03
    //     // zC1B1 = x04

    //     let mut zC0B0: Fq2 = c4_sq.mul_by_nonresidue(m);
    //     zC0B0.c0 = zC0B0.c0.add(FieldUtils::one(), m); // POTENTIAL OVERFLOW
    //     Fq12Sparse01234 {
    //         c0: Fq6 { c0: zC0B0, c1: c3_sq, c2: x34 }, c1: Fq6Sparse01 { c0: x03, c1: x04 },
    //     }
    // }

    // Mul Fq12 with a sparse 034 Fq12
    // https://github.com/Consensys/gnark/blob/v0.9.1/std/algebra/emulated/fields_bn254/e12_pairing.go#L116
    // // #[inline(always)]
    fn mul_034(self: Fq12, rhs: Fq12Sparse034, m: CircuitModulus) -> Fq12 {
        let Fq12 { c0: a0, c1: a1 } = self;
        let Fq12Sparse034 { mut c3, c4 } = rhs;
        // a0 := z.C0
        // b := e.MulBy01(&z.C1, c3, c4)
        let B = a1.mul_01(sparse_fq6(c3, c4), m);
        // c3 = e.Ext2.Add(e.Ext2.One(), c3)
        c3.c0 = c3.c0.add(FieldUtils::one(), m); // POTENTIAL OVERFLOW
        // d := e.Ext6.Add(&z.C0, &z.C1)
        // Requires reduction, or overflow in next step
        let d = a0.add(a1, m);
        // d = e.MulBy01(d, c3, c4)
        let D = d.mul_01(sparse_fq6(c3, c4), m);

        // zC1 := e.Ext6.Add(&a0, b)
        // zC1 = e.Ext6.Neg(zC1)
        // zC1 = e.Ext6.Add(zC1, d)
        // equivalent to, C1 = D + (-(a0 + B))
        let C1 = D.sub(B.add(a0, m), m);
        // zC0 := e.Ext6.MulByNonResidue(b)
        let C0 = mul_by_v_nz_as_circuit(B, m);
        // zC0 = e.Ext6.Add(zC0, &a0)
        let C0 = C0.add(a0, m);

        Fq12 { c0: C0, c1: C1 }
    }

    // Mul sparse 01234 Fq12 with a sparse 034 Fq12
    // Same as Fq12 mul 034 but with a sparse b1 i.e. b1.c2 as 0 and associated ops removed
    // https://github.com/Consensys/gnark/blob/v0.9.1/std/algebra/emulated/fields_bn254/e12_pairing.go#L208
    // // #[inline(always)]
    // fn mul_01234_034(self: Fq12Sparse01234, rhs: Fq12Sparse034, m: CircuitModulus) -> Fq12 {
    //     let Fq12Sparse01234 { c0: a0, c1: a1 } = self;

    //     // a0 := &E6{B0: *x[0], B1: *x[1], B2: *x[2]}
    //     // a1 := &E6{B0: *x[3], B1: *x[4], B2: *e.Ext2.Zero()}

    //     let Fq12Sparse034 { c3: mut z3, c4: z4 } = rhs;

    //     // a := e.Ext6.Add(e.Ext6.One(), &E6{B0: *z3, B1: *z4, B2: *e.Ext2.Zero()})
    //     let mut a = sparse_fq6(z3, z4);
    //     a.c0.c0 = a.c0.c0.add(FieldUtils::one(), m); // POTENTIAL OVERFLOW
    //     // b := e.Ext6.Add(a0, a1)
    //     let mut b = a0;
    //     b.c0 = b.c0.add(a1.c0, m);
    //     b.c1 = b.c1.add(a1.c1, m);
    //     // a = e.Ext6.Mul(a, b)
    //     let A = b.mul_01(a, m);
    //     // c := e.Ext6.Mul01By01(z3, z4, x[3], x[4])
    //     let C = a1.mul_01_by_01(sparse_fq6(z3, z4), m);
    //     // z1 := e.Ext6.Sub(a, a0)
    //     // z1 = e.Ext6.Sub(z1, c)
    //     let Z1 = A.sub(C.add(a0, m), m);
    //     // z0 := e.Ext6.MulByNonResidue(c)
    //     // z0 = e.Ext6.Add(z0, a0)
    //     let Z0 = mul_by_v_nz_as_circuit(C, m).add(a0, m);

    //     Fq12 { c0: Z0, c1: Z1, }
    // }

    // Mul Fq12 with a sparse 01234 Fq12
    // Same as Fq12 mul but with a sparse b1 i.e. b1.c2 as 0 and associated ops removed
    // // #[inline(always)]
    fn mul_01234(self: Fq12, rhs: Fq12Sparse01234, m: CircuitModulus) -> Fq12 {
        let Fq12 { c0: a0, c1: a1 } = self;
        let Fq12Sparse01234 { c0: b0, c1: b1 } = rhs;

        // Doing this part before U, V cost less for some reason
        let b = Fq6 { c0: b0.c0.add(b1.c0, m), c1: b0.c1.add(b1.c1, m), c2: b0.c2 };
        let c1 = (a0.add(a1, m)).mul(b, m);

        let u = a0.mul(b0, m);
        let v = a1.mul_01(b1, m);

        let c0 = v.mul_by_nonresidue(m).add(u, m);
        let c1 = c1.sub((u.add(v, m)), m);

        Fq12 { c0, c1, }
    }

    // Mul Fq12 with a sparse 01234 Fq12
    // Same as Fq12 mul but with a sparse b1 i.e. b1.c2 as 0 and associated ops removed
    // // #[inline(always)]
    // fn mul_01234_01234(self: Fq12Sparse01234, rhs: Fq12Sparse01234, m: CircuitModulus) -> Fq12 {
    //     let Fq12Sparse01234 { c0: a0, c1: a1 } = self;
    //     // let Fq12 {c0: a0, c1: a1 } = Fq12 {c0: a0, c1: Fq6 {c0:a1.c0, c1:a1.c1, c2: FieldUtils::zero()}}
    //     let Fq12Sparse01234 { c0: b0, c1: b1 } = rhs;

    //     // Doing this part before U, V cost less for some reason
    //     let b = Fq6 { c0: b0.c0.add(b1.c0, m), c1: b0.c1.add(b1.c1, m), c2: b0.c2 };
    //     let mut c1 = a0;
    //     c1.c0 = c1.c0.add(a1.c0, m);
    //     c1.c1 = c1.c1.add(a1.c1, m);
    //     let c1 = c1.mul(b, m);

    //     let u = a0.mul(b0, m);
    //     let v = a1.mul_01_by_01(b1, m);

    //     let c0 = v.mul_by_nonresidue(m).add(u, m);
    //     let c1 = c1.sub((u.add(v, m)), m);

    //     Fq12 { c0, c1, }
    // }
}
