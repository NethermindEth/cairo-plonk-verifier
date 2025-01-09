use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
// Sparse mul_034_by_034

// let  (zC0B0_c0, zC0B0_c1, c3d3_c0, c3d3_c1, x34_c0, x34_c1, x03_c0, x03_c1, x04_c0, x04_c1) = mul_034_by_034_circuit(); 

// let outputs = match (zC0B0_c0, zC0B0_c1, c3d3_c0, c3d3_c1, x34_c0, x34_c1, x03_c0, x03_c1, x04_c0, x04_c1).new_inputs()
//     .next(self.c3.c0.c0)
//     .next(self.c3.c1.c0)
//     .next(self.c4.c0.c0)
//     .next(self.c4.c1.c0)
//     .next(rhs.c3.c0.c0)
//     .next(rhs.c3.c1.c0)
//     .next(rhs.c4.c0.c0)
//     .next(rhs.c4.c1.c0)
//     .done().eval(m) {
//         Result::Ok(outputs) => { outputs },
//         Result::Err(_) => { panic!("Expected success") }
// };

// let mut zC0B0 = fq2(outputs.get_output(zC0B0_c0), outputs.get_output(zC0B0_c1));
// let c3d3 = fq2(outputs.get_output(c3d3_c0), outputs.get_output(c3d3_c1));
// let x34 = fq2(outputs.get_output(x34_c0), outputs.get_output(x34_c1));
// let x03 = fq2(outputs.get_output(x03_c0), outputs.get_output(x03_c1));
// let x04 = fq2(outputs.get_output(x04_c0), outputs.get_output(x04_c1));
// Fq6
type M034034_zC0B0C0 = CE<S<A<A<A<A<S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>, S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>, A<S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>, S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>, A<A<S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>, S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>, A<S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>, S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>>, S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>, S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>>;
type M034034_zC0B0C1 = CE<A<A<A<A<A<S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>, S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>, A<S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>, S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>>, A<A<S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>, S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>, A<S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>, S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>>>, S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>, S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>;
type M034034_C3D3C0 = CE<S<M<CI<0>, CI<4>>, M<CI<1>, CI<5>>>>;
type M034034_C3D3C1 = CE<S<M<A<CI<0>, CI<1>>, A<CI<4>, CI<5>>>, A<M<CI<0>, CI<4>>, M<CI<1>, CI<5>>>>>;
type M034034_X34C0 = CE<S<S<S<M<A<CI<4>, CI<6>>, A<CI<0>, CI<2>>>, M<A<CI<5>, CI<7>>, A<CI<1>, CI<3>>>>, S<M<CI<0>, CI<4>>, M<CI<1>, CI<5>>>>, S<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>;
type M034034_X34C1 = CE<S<S<S<M<A<A<CI<4>, CI<6>>, A<CI<5>, CI<7>>>, A<A<CI<0>, CI<2>>, A<CI<1>, CI<3>>>>, A<M<A<CI<4>, CI<6>>, A<CI<0>, CI<2>>>, M<A<CI<5>, CI<7>>, A<CI<1>, CI<3>>>>>, S<M<A<CI<0>, CI<1>>, A<CI<4>, CI<5>>>, A<M<CI<0>, CI<4>>, M<CI<1>, CI<5>>>>>, S<M<A<CI<2>, CI<3>>, A<CI<6>, CI<7>>>, A<M<CI<2>, CI<6>>, M<CI<3>, CI<7>>>>>>;
// Fq6Sparse01
type M034034_X03C0 = CE<A<CI<0>, CI<4>>>;
type M034034_X03C1 = CE<A<CI<1>, CI<5>>>;
type M034034_X04C0 = CE<A<CI<2>, CI<6>>>;
type M034034_X04C1 = CE<A<CI<3>, CI<7>>>;

// Sparse mul_01
// // core::internal::revoke_ap_tracking();
// // Input:a = (a0 + a1v + a2v2) and b = (b0 + b1v) ∈ Fp6
// // Output:c = a · b = (c0 + c1v + c2v2) ∈ Fp6
// let Fq6 { c0: a0, c1: a1, c2: a2 } = self;
// let Fq6Sparse01 { c0: b0, c1: b1, } = rhs;

// // b2 is zero so all ops associated ar removed

// // v0 = a0b0, v1 = a1b1, v2 = a2b2
// // let (V0, V1,) = (a0.u_mul(b0), a1.u_mul(b1),);

// // c0 = v0 + ξ((a1 + a2)(b1 + b2) - v1 - v2)
// // let C0 = V0 + mul_by_xi_nz(a1.u_add(a2).u_mul(b1) - V1, field_nz);
// // c1 =(a0 + a1)(b0 + b1) - v0 - v1 + ξv2
// // let C1 = a0.u_add(a1).u_mul(b0.u_add(b1)) - V0 - V1;

// // https://eprint.iacr.org/2006/471.pdf Sec 4
// // Karatsuba:
// // c2 = (a0 + a2)(b0 + b2) - v0 + v1 - v2,
// // c2 = (a0 + a2)(b0) - v0 + v1 - v2, b2 = 0
// // Schoolbook will be faster than Karatsuba for this,
// // c2 = a0b2 + a1b1 + a2b0,
// // c2 = V1 + a2b0 ∵ b2 = 0, V1 = a1b1
// // let C2 = a2.u_mul(b0) + V1;
// let v0 = a0.mul(b0, m);
// let v1 = a1.mul(b1, m);
// let c0 = Fq2Ops::add(
//     v0, mul_by_xi_nz_as_circuit(Fq2Ops::sub(Fq2Ops::mul(Fq2Ops::add(a1, a2, m), b1, m), v1, m), m), m
// );
// let c1 = Fq2Ops::sub(
//     Fq2Ops::sub(Fq2Ops::mul(Fq2Ops::add(a0, a1, m), Fq2Ops::add(b0, b1, m), m), v0, m), v1, m
// );
// let c2 = Fq2Ops::add(Fq2Ops::mul(a2, b0, m), v1, m);

// Fq6 { c0: c0, c1: c1, c2: c2 }
// Fq6
type M01_C0C0 = CE<A<S<A<A<A<A<S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>, S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>, A<S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>, S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>, A<A<S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>, S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>, A<S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>, S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>>, S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>, S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>, S<M<CI<0>, CI<6>>, M<CI<1>, CI<7>>>>>;
type M01_C0C1 = CE<A<A<A<A<A<A<S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>, S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>, A<S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>, S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>>, A<A<S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>, S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>, A<S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>, S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>>>, S<S<M<A<A<CI<2>, CI<4>>, A<CI<3>, CI<5>>>, A<CI<8>, CI<9>>>, A<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>, S<S<M<A<CI<2>, CI<4>>, CI<8>>, M<A<CI<3>, CI<5>>, CI<9>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>, S<M<A<CI<0>, CI<1>>, A<CI<6>, CI<7>>>, A<M<CI<0>, CI<6>>, M<CI<1>, CI<7>>>>>>;
type M01_C1C0 = CE<S<S<S<M<A<CI<0>, CI<2>>, A<CI<6>, CI<8>>>, M<A<CI<1>, CI<3>>, A<CI<7>, CI<9>>>>, S<M<CI<0>, CI<6>>, M<CI<1>, CI<7>>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>;
type M01_C1C1 = CE<S<S<S<M<A<A<CI<0>, CI<2>>, A<CI<1>, CI<3>>>, A<A<CI<6>, CI<8>>, A<CI<7>, CI<9>>>>, A<M<A<CI<0>, CI<2>>, A<CI<6>, CI<8>>>, M<A<CI<1>, CI<3>>, A<CI<7>, CI<9>>>>>, S<M<A<CI<0>, CI<1>>, A<CI<6>, CI<7>>>, A<M<CI<0>, CI<6>>, M<CI<1>, CI<7>>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>;
type M01_C2C0 = CE<A<S<M<CI<4>, CI<6>>, M<CI<5>, CI<7>>>, S<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>;
type M01_C2C1 = CE<A<S<M<A<CI<4>, CI<5>>, A<CI<6>, CI<7>>>, A<M<CI<4>, CI<6>>, M<CI<5>, CI<7>>>>, S<M<A<CI<2>, CI<3>>, A<CI<8>, CI<9>>>, A<M<CI<2>, CI<8>>, M<CI<3>, CI<9>>>>>>;

