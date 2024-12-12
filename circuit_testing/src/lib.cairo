pub use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};
pub use plonk_verifier::plonk::verify;
use core::array::ArrayTrait;

#[starknet::interface]
trait IVerifier<T> {
    // fn verify(
    //     ref self: T,
    //     verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: Array<u256>
    // );
    fn verify(ref self: T);
}

#[starknet::contract]
mod PLONK_Verifier{

    use core::array::ArrayTrait;
    
    use plonk_verifier::plonk::verify;
    use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};
    use plonk_verifier::plonk::constants;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl PLONK_verifier of super::IVerifier<ContractState> {
        
        // fn verify(ref self: ContractState, verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: Array<u256>) { 
        fn verify(ref self: ContractState) {     
            // let (n, power, k1, k2, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w) =
            // constants::verification_key();
            // let verification_key:PlonkVerificationKey  = PlonkVerificationKey {
            //     n, power, k1, k2, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w
            // };

            // // proof
            // let (A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2,
            // eval_zw) =
            //     constants::proof();
            // let proof: PlonkProof = PlonkProof {
            //     A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2, eval_zw
            // };

            // //public_signals
            // let public_signals = constants::public_inputs();
            // let verified: bool = plonk_verifier::plonk::verify::PlonkVerifier::verify(verification_key, proof, public_signals);
            // assert(verified, 'plonk verification failed'); 
            let mut tmp = CircuitEval::new();
            tmp.increment(); 
            tmp.increment(); 
            tmp.increment(); 
            tmp.increment(); 
            tmp.increment(); 
            tmp.increment(); 
            tmp.increment(); 
            tmp.increment(); 
            tmp.increment(); 
            tmp.increment(); 
            let mut tmp = CircuitEval::new();

        }

        
    }
    use plonk_verifier::curve::groups::Affine;
    use plonk_verifier::traits::{FieldOps as FOps, FieldShortcuts as FShort};
    use plonk_verifier::fields::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg};
    use plonk_verifier::fields::print::{FqPrintImpl, Fq2PrintImpl};
    use plonk_verifier::fields::{fq, Fq, fq2, Fq2};
    use plonk_verifier::curve::constants::FIELD_U384;
    use core::circuit::{
        RangeCheck96, AddMod, MulMod, u96, CircuitElement, CircuitInput, circuit_add, circuit_sub,
        circuit_mul, circuit_inverse, EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus,
        AddInputResultTrait, CircuitInputs, EvalCircuitResult, CircuitElementTrait, IntoCircuitInputValue, 
    };
    use core::circuit::{AddModGate, SubModGate, MulModGate, InverseGate};

    use core::circuit::conversions::from_u256;
    use core::fmt::{Display, Formatter, Error};

    use debug::PrintTrait as Print;

    type AffineG1 = Affine<Fq>;
    type AffineG2 = Affine<Fq2>;

    // Testing
    #[derive(Drop)]
    pub struct CircuitBuilder {
        circuit: Gates,
        inputs: Array<u384>, 
        idx: usize, // current idx of input
    }

    #[derive(Drop)]
    pub enum Gates {
        And,
    }

    trait CircuitEval {
        fn new() -> CircuitBuilder;
        //fn eval(self: @CircuitBuilder<T>) -> u384;
        fn increment(ref self: CircuitBuilder); 
    }

    impl CircuitEvalImpl of CircuitEval {
        fn new() -> CircuitBuilder {
            CircuitBuilder {circuit: Gates::And, inputs: ArrayTrait::<u384>::new(), idx: 0}
        }
        fn increment(ref self: CircuitBuilder) {
            self.idx = self.idx + 1; 
        }
    }

    // trait CircuitECOperations<T> {
    //     // fn x_on_slope(self: @Affine<Fq>, slope: Fq, x2: Fq) -> Fq;
    //     // fn y_on_slope(self: @Affine<Fq>, slope: Fq, x: Fq) -> Fq;
    //     fn pt_on_slope(self: CircuitBuilder<T>, lhs: @Affine<Fq>, slope: Fq, x2: Fq) -> (CircuitElement<T>, CircuitElement<T>);
    //     // fn chord(self: CircuitBuilder<T>, lhs: @Affine<Fq>, rhs: Affine<Fq>) -> (CircuitElement<T>, CircuitElement<T>);
    //     // fn add_as_circuit(self: CircuitBuilder<T>, lhs: @Affine<Fq>, rhs: Affine<Fq>) -> (CircuitElement<T>, CircuitElement<T>);
    //     // // fn tangent(self: @Affine<Fq>) -> Fq;
    //     // fn double_as_circuit(self: CircuitBuilder<T>, lhs: @Affine<Fq>,) -> (CircuitElement<T>, CircuitElement<T>);
    //     // fn multiply_as_circuit(self: CircuitBuilder<T>, lhs: @Affine<Fq>, multiplier: u256) -> (CircuitElement<T>, CircuitElement<T>);
    //     // fn neg(self: @Affine<Fq>) -> Affine<Fq>;
    // }
}

