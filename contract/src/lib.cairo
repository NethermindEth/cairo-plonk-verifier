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
            // let verified: bool = plonk_verifier::plonk::verify::PlonkVerifier::verify(verification_key, proof, public_signals);
            // assert(verified, 'plonk verification failed'); 

            let m = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

            // pairing 
            single_ate_pairing(Wxiw, verification_key.X_2, m);
            
            // miller
            // let g1 = Wxiw;
            // let g2 = verification_key.X_2;
            // let (pre, mut q) = SingleMillerPrecompute::precompute((g1, g2), m);

            // let mut f = SingleMillerSteps::miller_first_second(@pre, 1, 2, ref q);

            // SingleMillerSteps::sqr_target(@pre, 3, ref q, ref f);
            // SingleMillerSteps::sqr_target(@pre, 3, ref q, ref f);

            // SingleMillerSteps::miller_bit_o(@pre, 3, ref q, ref f);
            // SingleMillerSteps::miller_bit_p(@pre, 3, ref q, ref f);
            // SingleMillerSteps::miller_bit_n(@pre, 3, ref q, ref f);
            

            // SingleMillerSteps::miller_last(@pre, ref q, ref f);

            
        }
    }
}

