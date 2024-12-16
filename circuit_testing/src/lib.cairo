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

    use to_byte_array::FormatAsByteArray;
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

        }
    }
    fn test() {
        // let y = 5; 
        
        // let x = point_on_slope_fq!(20, 4);
        // pt_on_slope(); 
        // assert(5 == x, 'ne');
        let test_fq2_a = fq2(2, 4);
        let test_fq2_b = fq2(5, 10);


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

        let t0 = circuit_mul(t4, t4);
        let t1 = circuit_mul(t3, t3);
        let a0_add_a1 = circuit_add(t4, t3);
        let b0_add_b1 = circuit_add(t4, t3);
        let t2 = circuit_mul(a0_add_a1, b0_add_b1);
        let t3 = circuit_add(t0, t1);
        let t3 = circuit_sub(t2, t3);
        let t4 = circuit_sub(t0, t1);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let a0 = from_u256(test_fq2_a.c0.c0);
        let a1 = from_u256(test_fq2_a.c1.c0);
        let b0 = from_u256(test_fq2_b.c0.c0);
        let b1 = from_u256(test_fq2_b.c1.c0);

        let outputs =
            match (t3, t4,).new_inputs().next(a0).next(a1).next(b0).next(b1).done().eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        
        let fq_c0 = outputs.get_output(t4);
        let fq_c1 = outputs.get_output(t3);

        
        // let a0 = CircuitElement::<CircuitInput<0>> {};
        // let a1 = CircuitElement::<CircuitInput<1>> {};
        // // let b0 = CircuitElement::<CircuitInput<2>> {};
        // // let b1 = CircuitElement::<CircuitInput<3>> {};

        // let t0 = circuit_mul(a0, a0);
        // let t1 = circuit_mul(a1, a1);
        // let a0_add_a1 = circuit_add(a0, a1);
        // let b0_add_b1 = circuit_add(a0, a1);
        // let t2 = circuit_mul(a0_add_a1, b0_add_b1);
        // let t3 = circuit_add(t0, t1);
        // let t3 = circuit_sub(t2, t3);
        // let t4 = circuit_sub(t0, t1);

        // let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();


        // let outputs =
        //     match (t3, t4,).new_inputs().next(fq_c0).next(fq_c1).done().eval(modulus) {
        //     Result::Ok(outputs) => { outputs },
        //     Result::Err(_) => { panic!("Expected success") }
        // };

        // let fq_c0 = outputs.get_output(t4);
        // let fq_c1 = outputs.get_output(t3);

        // let fq_c0 = Fq { c0: outputs.get_output(t4).try_into().unwrap() };
        // let fq_c1 = Fq { c0: outputs.get_output(t3).try_into().unwrap() };

        // let fq_t = Fq2 { c0: fq_c0, c1: fq_c1 };

        // let fq_t = fq_t * fq_t; 
        //println!("out: {:?}", fq_t);

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

    // Output Circuit Types
    type PointOnSlopeCircuit = CircuitElement::<
        SubModGate::<
            SubModGate::<
                MulModGate::<CircuitInput::<0>, CircuitInput::<0>>, 
                CircuitInput::<1>>, 
            CircuitInput::<3>>>;

    // // Testing
    // #[derive(Drop)]
    // pub struct CircuitBuilder<T> {
    //     circuit: Gates<T>,
    //     inputs: Array<u384>, 
    //     idx: usize, // current idx of input
    // }

    // // Create pattern matching logic
    // #[derive(Drop)]
    // pub enum Gates {
    //     PointOnSlope {
    //         out: (Box<)
    //     }
    // }

    // trait CircuitEval<T> {
    //     fn new() -> CircuitBuilder<T>;
    //     //fn eval(self: @CircuitBuilder<T>) -> u384;
    //     fn increment(ref self: CircuitBuilder<T>); 
    // }

    // impl CircuitEvalImpl of CircuitEval<T> {
    //     fn new() -> CircuitBuilder<T> {
    //         CircuitBuilder {circuit: Gates::And, inputs: ArrayTrait::<u384>::new(), idx: 0}
    //     }

    //     fn increment(ref self: CircuitBuilder<T>) {
    //         self.idx = self.idx + 1; 
    //     }
    // }

    // // trait CircuitECOperations<T> {
    // //     // fn x_on_slope(self: @Affine<Fq>, slope: Fq, x2: Fq) -> Fq;
    // //     // fn y_on_slope(self: @Affine<Fq>, slope: Fq, x: Fq) -> Fq;
    // //     fn pt_on_slope(self: CircuitBuilder<T>, lhs: @Affine<Fq>, slope: Fq, x2: Fq) -> (CircuitElement<T>, CircuitElement<T>);
    // //     // fn chord(self: CircuitBuilder<T>, lhs: @Affine<Fq>, rhs: Affine<Fq>) -> (CircuitElement<T>, CircuitElement<T>);
    // //     // fn add_as_circuit(self: CircuitBuilder<T>, lhs: @Affine<Fq>, rhs: Affine<Fq>) -> (CircuitElement<T>, CircuitElement<T>);
    // //     // // fn tangent(self: @Affine<Fq>) -> Fq;
    // //     // fn double_as_circuit(self: CircuitBuilder<T>, lhs: @Affine<Fq>,) -> (CircuitElement<T>, CircuitElement<T>);
    // //     // fn multiply_as_circuit(self: CircuitBuilder<T>, lhs: @Affine<Fq>, multiplier: u256) -> (CircuitElement<T>, CircuitElement<T>);
    // //     // fn neg(self: @Affine<Fq>) -> Affine<Fq>;
    // // }

    fn pt_on_slope() {
        // let x_2 = x2;
        // x = λ^2 - x1 - x2
        // slope.sqr() - *self.x - x2
        //let x = self.x_on_slope(slope, x2);
        // y = λ(x1 - x) - y1
        // slope * (*self.x - x) - *self.y
        //let y = self.y_on_slope(slope, x);
        
        let lambda = CircuitElement::<CircuitInput<0>> {};
        let x1 = CircuitElement::<CircuitInput<1>> {};
        let y1 = CircuitElement::<CircuitInput<2>> {};
        let x2 = CircuitElement::<CircuitInput<3>> {};        
        
        let lambda_sqr = circuit_mul(lambda, lambda);  // slope.sqr()
        let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
        let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x2); // slope.sqr() - *self.x - x2

        let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
        let y_slope_mul_lambda_x1_x = circuit_mul(lambda, y_slope_sub_x1_x); // slope * (*self.x - x)
        let y_slope_lambda_sub_lambda_x_y = circuit_sub(y_slope_mul_lambda_x1_x, y1); // slope * (*self.x - x) - *self.y
        // let tmp = core::circuit::CircuitElement::<core::circuit::SubModGate::<core::circuit::MulModGate::<core::circuit::CircuitInput::<0>, core::circuit::SubModGate::<core::circuit::CircuitInput::<1>, core::circuit::SubModGate::<core::circuit::SubModGate::<core::circuit::MulModGate::<core::circuit::CircuitInput::<0>, core::circuit::CircuitInput::<0>>, core::circuit::CircuitInput::<1>>, core::circuit::CircuitInput::<3>>>>, core::circuit::CircuitInput::<2>>> {};
        (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y);

    }        
}

#[cfg(test)]
mod test {
    use super::PLONK_Verifier;
    #[test]
    fn test_circuit() {
        PLONK_Verifier::test(); 

    }
}