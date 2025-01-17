use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use plonk_verifier::circuits::typedefs::add_sub_neg::{Add, Sub, Neg};
use plonk_verifier::circuits::typedefs::fq_6_type::{
    Fq6MulC0, Fq6MulC1, Fq6MulC2, Fq6MulC3, Fq6MulC4, Fq6MulC5, 
    Fq6SqrC0, Fq6SqrC1, Fq6SqrC2, Fq6SqrC3, Fq6SqrC4, Fq6SqrC5, 
    // Fq6DivC0, Fq6DivC1, Fq6DivC2, Fq6DivC3, Fq6DivC4, Fq6DivC5, 
    // Fq6InvC0, Fq6InvC1, Fq6InvC2, Fq6InvC3, Fq6InvC4, Fq6InvC5, 
};

fn add_circuit() -> (        
	Add::<0, 6>,
	Add::<1, 7>,
	Add::<2, 8>,
	Add::<3, 9>,
	Add::<4, 10>,
	Add::<5, 11> ) { 
	(
        Add::<0, 6> {},
        Add::<1, 7> {},
        Add::<2, 8> {},
        Add::<3, 9> {},
        Add::<4, 10> {},
        Add::<5, 11> {}
    )
}

fn sub_circuit() -> (        
	Sub::<0, 6>,
	Sub::<1, 7>,
	Sub::<2, 8>,
	Sub::<3, 9>,
	Sub::<4, 10>,
	Sub::<5, 11> ) {
	(
        Sub::<0, 6> {},
        Sub::<1, 7> {},
        Sub::<2, 8> {},
        Sub::<3, 9> {},
        Sub::<4, 10> {},
        Sub::<5, 11> {}
    )
}

fn neg_circuit() -> (        
	Neg::<0>,
	Neg::<1>,
	Neg::<2>,
	Neg::<3>,
	Neg::<4>,
	Neg::<5> ) {
	(
        Neg::<0> {},
        Neg::<1> {},
        Neg::<2> {},
        Neg::<3> {},
        Neg::<4> {},
        Neg::<5> {}
    )
}

// Todo: Refactor as above
fn mul_circuit() -> (Fq6MulC0, Fq6MulC1, Fq6MulC2, Fq6MulC3, Fq6MulC4, Fq6MulC5) {
    // let Fq6 { c0: a0, c1: a1, c2: a2 } = self;
    // let Fq6 { c0: b0, c1: b1, c2: b2 } = rhs;
    // let field_nz = get_field_nz();

    // // v0 = a0b0, v1 = a1b1, v2 = a2b2
    // let (V0, V1, V2,) = (a0.u_mul(b0), a1.u_mul(b1), a2.u_mul(b2),);

    // // c0 = v0 + ξ((a1 + a2)(b1 + b2) - v1 - v2)
    // let C0 = V0 + mul_by_xi_nz(a1.u_add(a2).u_mul(b1.u_add(b2)) - V1 - V2, field_nz);
    // // c1 =(a0 + a1)(b0 + b1) - v0 - v1 + ξv2
    // let C1 = a0.u_add(a1).u_mul(b0.u_add(b1)) - V0 - V1 + mul_by_xi_nz(V2, field_nz);
    // // c2 = (a0 + a2)(b0 + b2) - v0 + v1 - v2,
    // let C2 = a0.u_add(a2).u_mul(b0.u_add(b2)) - V0 + V1 - V2;

    // (C0, C1, C2)

    // let v0 = Fq2Ops::mul(self.c0, rhs.c0);
    // let v1 = Fq2Ops::mul(self.c1, rhs.c1);
    // let v2 = Fq2Ops::mul(self.c2, rhs.c2);

    // let a1_add_a2 = Fq2Ops::add(self.c1, self.c2);
    // let b1_add_b2 = Fq2Ops::add(rhs.c1, rhs.c2);
    // let t0 = Fq2Ops::mul(a1_add_a2, b1_add_b2);
    // let t0 = Fq2Ops::sub(t0, v1);
    // let t0 = Fq2Ops::sub(t0, v2);
    // let t0_scaled = mul_by_xi_nz_as_circuit(t0);
    // let c0 = Fq2Ops::add(v0, t0_scaled);

    // let a0_add_a1 = Fq2Ops::add(self.c0, self.c1);
    // let b0_add_b1 = Fq2Ops::add(rhs.c0, rhs.c1);
    // let t1 = Fq2Ops::mul(a0_add_a1, b0_add_b1);
    // let t1 = Fq2Ops::sub(t1, v0);
    // let t1 = Fq2Ops::sub(t1, v1);
    // let t1_scaled = mul_by_xi_nz_as_circuit(v2);
    // let c1 = Fq2Ops::add(t1, t1_scaled);

    // let a0_add_a2 = Fq2Ops::add(self.c0, self.c2);
    // let b0_add_b2 = Fq2Ops::add(rhs.c0, rhs.c2);
    // let t2 = Fq2Ops::mul(a0_add_a2, b0_add_b2);
    // let t2 = Fq2Ops::sub(t2, v0);
    // let t2 = Fq2Ops::add(t2, v1);
    // let c2 = Fq2Ops::sub(t2, v2);

    // let res = Fq6 { c0: c0, c1: c1, c2: c2 };
    // res
    (Fq6MulC0 {}, Fq6MulC1 {}, Fq6MulC2 {}, Fq6MulC3 {}, Fq6MulC4 {}, Fq6MulC5 {})
}

fn sqr_circuit() -> (Fq6SqrC0, Fq6SqrC1, Fq6SqrC2, Fq6SqrC3, Fq6SqrC4, Fq6SqrC5) {
    // let s0 = Fq2Ops::sqr(self.c0);
    // let ab = Fq2Ops::mul(self.c0, self.c1);
    // let s1 = Fq2Ops::add(ab, ab);
    // let s2 = Fq2Ops::sqr(Fq2Ops::sub(Fq2Ops::add(self.c0, self.c2), self.c1));
    // let bc = Fq2Ops::mul(self.c1, self.c2);
    // let s3 = Fq2Ops::add(bc, bc);
    // let s4 = Fq2Ops::sqr(self.c2);
    // let c0 = Fq2Ops::add(s0, Fq2Utils::mul_by_nonresidue(s3));
    // let c1 = Fq2Ops::add(s1, Fq2Utils::mul_by_nonresidue(s4));
    // let c2 = Fq2Ops::sub(Fq2Ops::add(Fq2Ops::add(s1, s2), s3), Fq2Ops::add(s0, s4));
    // let res = Fq6 { c0: c0, c1: c1, c2: c2 };
    // res
    (Fq6SqrC0 {}, Fq6SqrC1 {}, Fq6SqrC2 {}, Fq6SqrC3 {}, Fq6SqrC4 {}, Fq6SqrC5 {})
}

// fn inv_circuit() -> (Fq6InvC0, Fq6InvC1, Fq6InvC2, Fq6InvC3, Fq6InvC4, Fq6InvC5) {
//     (Fq6InvC0 {}, Fq6InvC1 {}, Fq6InvC2 {}, Fq6InvC3 {}, Fq6InvC4 {}, Fq6InvC5 {})
// }