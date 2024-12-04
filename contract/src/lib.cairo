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
    
    // testing
    use plonk_verifier::curve::{t_naf, get_field_nz, FIELD_X2};
    use plonk_verifier::curve::{u512, mul_by_v, U512BnAdd, U512BnSub, Tuple2Add, Tuple2Sub,};
    use plonk_verifier::curve::{u512_add, u512_sub, u512_high_add, u512_high_sub, U512Fq2Ops};
    use plonk_verifier::fields::{
        FieldUtils, FieldOps, fq, Fq, Fq2, Fq6, Fq12, fq12, Fq12Frobenius, Fq12Squaring, Fq12SquaringCircuit
    };

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl PLONK_verifier of super::IVerifier<ContractState> {
        
        // fn verify(ref self: ContractState, verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: Array<u256>) { 
        fn verify(ref self: ContractState) {     
            let (n, power, k1, k2, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w) =
            constants::verification_key();
            let verification_key:PlonkVerificationKey  = PlonkVerificationKey {
                n, power, k1, k2, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w
            };

            // proof
            let (A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2,
            eval_zw) =
                constants::proof();
            let proof: PlonkProof = PlonkProof {
                A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2, eval_zw
            };

            // Testing
            // Narrowed down problem to stack load - deep function calls create compile errors on starknet
            // It is not tool related, tried independent contract declaration and other tools besides Starkli
            // Possible Errors:
            // 1. Deep Stack Trace
            // 2. Name Mangling
            // 3. Recursive Errors? (via import names?)

            // It errors when placed in the verify proof function with previous calculations of Circuits,
            // Maybe 
            // let field_nz = get_field_nz();

            // let t1: Fq12 = Default::default();
            // let t2: Fq12 = Default::default();//.frob2();
            // // let t3 = t1 / t2; 
            // let t3 = t2.inv(get_field_nz());
            // let t4 = t1 * t1;
            //self

            //plonk_verifier::plonk::verify::PlonkVerifier::produce_error(); 

            //public_signals
            let public_signals = constants::public_inputs();
            let verified: bool = plonk_verifier::plonk::verify::PlonkVerifier::verify(verification_key, proof, public_signals);
            assert(verified, 'plonk verification failed'); 
        }

    }
}

