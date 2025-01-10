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

    use plonk_verifier::curve::pairing::optimal_ate::single_ate_pairing;
    use plonk_verifier::curve::pairing::optimal_ate_impls::{SingleMillerPrecompute, SingleMillerSteps};
    use plonk_verifier::curve::constants::{FIELD_U384};
    use core::circuit::CircuitModulus;
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

            //public_signals
            let public_signals = constants::public_inputs();
            let verified: bool = plonk_verifier::plonk::verify::PlonkVerifier::verify(verification_key, proof, public_signals);
            assert(verified, 'plonk verification failed');             
        }
    }
}

