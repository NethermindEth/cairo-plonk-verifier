pub use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};
pub use plonk_verifier::plonk::verify;
use core::array::ArrayTrait;

#[starknet::interface]
trait IVerifier<T> {
    fn verify(ref self: T);
    // fn test_byte(ref self: T, a: u256, b: u256);
}

#[starknet::contract]
mod PLONK_Verifier {
    use core::array::ArrayTrait;

    use plonk_verifier::plonk::verify;
    use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};
    use plonk_verifier::plonk::constants;
    use plonk_verifier::math::fast_mod::div_inv::div_circuit;
    use plonk_verifier::math::fast_mod::div_inv::inv_circuit;
    use plonk_verifier::math::fast_mod::add_sub::add_circuit;
    use plonk_verifier::math::fast_mod::add_sub::sub_circuit;
    // use plonk_verifier::math::fast_mod::mul_scale_sqr::{mul_circuit, mul_nz};
    // use plonk_verifier::curve::get_field_nz;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl PLONK_verifier of super::IVerifier<ContractState> {
        fn verify(ref self: ContractState) {
            let (n, power, k1, k2, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w) =
                constants::verification_key();
            let verification_key: PlonkVerificationKey = PlonkVerificationKey {
                n, power, k1, k2, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w
            };

            // proof
            let (
                A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2, eval_zw
            ) =
                constants::proof();
            let proof: PlonkProof = PlonkProof {
                A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2, eval_zw
            };

            //public_signals
            let public_signals = constants::public_inputs();
            let verified: bool = plonk_verifier::plonk::verify::PlonkVerifier::verify(
                verification_key, proof, public_signals
            );
            assert(verified, 'plonk verification failed');
        }
        // fn test_byte(ref self: ContractState, a: u256, b: u256) {
    //     let o = mul_circuit(a, b);
    //     // let o1 = mul_nz(a, b, get_field_nz());
    // }
    }
}
