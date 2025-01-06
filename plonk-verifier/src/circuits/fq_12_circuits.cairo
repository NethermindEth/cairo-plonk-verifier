use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use plonk_verifier::circuits::typedefs::add_sub_neg::{Add, Sub, Neg};
use plonk_verifier::circuits::typedefs::fq_12_type::{
	Fq12MulC0, Fq12MulC1, Fq12MulC2, Fq12MulC3, Fq12MulC4, Fq12MulC5, Fq12MulC6, Fq12MulC7, Fq12MulC8, Fq12MulC9, Fq12MulC10, Fq12MulC11, 
	Fq12SqrC0, Fq12SqrC1, Fq12SqrC2, Fq12SqrC3, Fq12SqrC4,Fq12SqrC5, Fq12SqrC6, Fq12SqrC7, Fq12SqrC8, Fq12SqrC9, Fq12SqrC10, Fq12SqrC11
};

fn add_circuit() -> (        
	Add::<0, 12>,
	Add::<1, 13>,
	Add::<2, 14>,
	Add::<3, 15>,
	Add::<4, 16>,
	Add::<5, 17>,
	Add::<6, 18>,
	Add::<7, 19>,
	Add::<8, 20>,
	Add::<9, 21>,
	Add::<10, 22>,
	Add::<11, 23> ) { 
	(
        Add::<0, 12> {},
        Add::<1, 13> {},
        Add::<2, 14> {},
        Add::<3, 15> {},
        Add::<4, 16> {},
        Add::<5, 17> {},
        Add::<6, 18> {},
        Add::<7, 19> {},
        Add::<8, 20> {},
        Add::<9, 21> {},
        Add::<10, 22> {},
        Add::<11, 23> {},
    )
}

fn sub_circuit() -> (        
	Sub::<0, 12>,
	Sub::<1, 13>,
	Sub::<2, 14>,
	Sub::<3, 15>,
	Sub::<4, 16>,
	Sub::<5, 17>,
	Sub::<6, 18>,
	Sub::<7, 19>,
	Sub::<8, 20>,
	Sub::<9, 21>,
	Sub::<10, 22>,
	Sub::<11, 23> ) {
	(
        Sub::<0, 12> {},
        Sub::<1, 13> {},
        Sub::<2, 14> {},
        Sub::<3, 15> {},
        Sub::<4, 16> {},
        Sub::<5, 17> {},
        Sub::<6, 18> {},
        Sub::<7, 19> {},
        Sub::<8, 20> {},
        Sub::<9, 21> {},
        Sub::<10, 22> {},
        Sub::<11, 23> {},
    )
}

fn neg_circuit() -> (        
	Neg::<0>,
	Neg::<1>,
	Neg::<2>,
	Neg::<3>,
	Neg::<4>,
	Neg::<5>,
	Neg::<6>,
	Neg::<7>,
	Neg::<8>,
	Neg::<9>,
	Neg::<10>,
	Neg::<11> ) {
	(
        Neg::<0> {},
        Neg::<1> {},
        Neg::<2> {},
        Neg::<3> {},
        Neg::<4> {},
        Neg::<5> {},
        Neg::<6> {},
        Neg::<7> {},
        Neg::<8> {},
        Neg::<9> {},
        Neg::<10> {},
        Neg::<11> {},
    )
}

fn mul_circuit() -> (
	Fq12MulC0, 
	Fq12MulC1, 
	Fq12MulC2, 
	Fq12MulC3, 
	Fq12MulC4, 
	Fq12MulC5, 
	Fq12MulC6, 
	Fq12MulC7, 
	Fq12MulC8, 
	Fq12MulC9, 
	Fq12MulC10, 
	Fq12MulC11 ) {
	(
		Fq12MulC0 {}, 
		Fq12MulC1 {}, 
		Fq12MulC2 {}, 
		Fq12MulC3 {}, 
		Fq12MulC4 {}, 
		Fq12MulC5 {}, 
		Fq12MulC6 {}, 
		Fq12MulC7 {}, 
		Fq12MulC8 {}, 
		Fq12MulC9 {}, 
		Fq12MulC10 {}, 
		Fq12MulC11 {}
	)
}
fn sqr_circuit() -> (
	Fq12SqrC0, 
	Fq12SqrC1, 
	Fq12SqrC2, 
	Fq12SqrC3, 
	Fq12SqrC4, 
	Fq12SqrC5, 
	Fq12SqrC6, 
	Fq12SqrC7, 
	Fq12SqrC8, 
	Fq12SqrC9, 
	Fq12SqrC10, 
	Fq12SqrC11 ) {
	(
		Fq12SqrC0 {}, 
		Fq12SqrC1 {}, 
		Fq12SqrC2 {}, 
		Fq12SqrC3 {}, 
		Fq12SqrC4 {}, 
		Fq12SqrC5 {}, 
		Fq12SqrC6 {}, 
		Fq12SqrC7 {}, 
		Fq12SqrC8 {}, 
		Fq12SqrC9 {}, 
		Fq12SqrC10 {}, 
		Fq12SqrC11 {}
	)
}