use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};

type Fq2MulC0 = CE<S<M<CI<0>, CI<2>>, M<CI<1>, CI<3>>>>;
type Fq2MulC1 = CE<S<M<A<CI<0>, CI<1>>, A<CI<2>, CI<3>>>, A<M<CI<0>, CI<2>>, M<CI<1>, CI<3>>>>>;

type Fq2SqrC0 = CE<M<A<CI<0>, CI<1>>, S<CI<0>, CI<1>>>>;
type Fq2SqrC1 = CE<M<A<CI<0>, CI<0>>, CI<1>>>;

type Fq2DivC0 = CE<S<M<CI<0>, M<CI<2>, I<A<M<CI<2>, CI<2>>, M<CI<3>, CI<3>>>>>>, M<CI<1>, M<CI<3>, S<S<CI<0>, CI<0>>, I<A<M<CI<2>, CI<2>>, M<CI<3>, CI<3>>>>>>>>>;
type Fq2DivC1 = CE<S<M<A<CI<0>, CI<1>>, A<M<CI<2>, I<A<M<CI<2>, CI<2>>, M<CI<3>, CI<3>>>>>, M<CI<3>, S<S<CI<0>, CI<0>>, I<A<M<CI<2>, CI<2>>, M<CI<3>, CI<3>>>>>>>>, A<M<CI<0>, M<CI<2>, I<A<M<CI<2>, CI<2>>, M<CI<3>, CI<3>>>>>>, M<CI<1>, M<CI<3>, S<S<CI<0>, CI<0>>, I<A<M<CI<2>, CI<2>>, M<CI<3>, CI<3>>>>>>>>>>;

type Fq2InvC0 = CE<M<CI<0>, I<A<M<CI<0>, CI<0>>, M<CI<1>, CI<1>>>>>>;
type Fq2InvC1 = CE<M<CI<1>, S<S<CI<0>, CI<0>>, I<A<M<CI<0>, CI<0>>, M<CI<1>, CI<1>>>>>>>;