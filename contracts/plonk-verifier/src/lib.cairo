pub use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};
pub use plonk_verifier::plonk::verify;
use core::array::ArrayTrait;
use core::circuit::u384;

#[starknet::interface]
trait IVerifier<T> {
    fn verify(
        ref self: T,
        verification_key: PlonkVerificationKey,
        proof: PlonkProof,
        public_signals: Array<u384>
    ) -> bool;
}

#[starknet::contract]
mod PLONK_Verifier {
    use super::u384;
    use core::array::ArrayTrait;

    use plonk_verifier::plonk::verify;
    use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};
    use plonk_verifier::plonk::constants;
    use plonk_verifier::curve::groups::{AffineG1, AffineG2, fq, fq2};
    use plonk_verifier::curve::constants::{FIELD_U384};
    use core::circuit::{CircuitModulus, U384Serde};
    use core::starknet::{ContractAddress, ClassHash};
    use starknet::SyscallResultTrait;

    const PAIRING_CLASS_HASH: felt252 = 0x04816a82902119418e5205a092322022e7b1694cf5804d54d0c6001dde74674e;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl PLONK_verifier of super::IVerifier<ContractState> {
        #[derive(Serde)]
        fn verify(
            ref self: ContractState,
            verification_key: PlonkVerificationKey,
            proof: PlonkProof,
            public_signals: Array<u384>
        ) -> bool {
            let (n, power, k1, k2, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w) =
                constants::verification_key();
            let vk: PlonkVerificationKey = PlonkVerificationKey {
                n, power, k1, k2, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w
            };

            // proof
            let (
                A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2, eval_zw
            ) =
                constants::proof();
            let pf: PlonkProof = PlonkProof {
                A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2, eval_zw
            };

            //public_signals
            let pi = constants::public_inputs();

            let (A1, vk_X2, B1, g2_one) =
                plonk_verifier::plonk::verify::PlonkVerifier::verify_except_pairing(
                    vk, pf, pi
            );

            let mut call_data: Array<felt252> = array![];
            Serde::serialize(@A1, ref call_data);
            Serde::serialize(@vk_X2, ref call_data);
            Serde::serialize(@B1, ref call_data);
            Serde::serialize(@g2_one, ref call_data);

            let mut res_serialized = core::starknet::syscalls::library_call_syscall(
                PAIRING_CLASS_HASH.try_into().unwrap(), selector!("valid_pairing"), call_data.span()
            ).unwrap_syscall();

            let call_res = Serde::<bool>::deserialize(ref res_serialized).unwrap();
            let verified: bool = call_res;
            assert(verified, 'plonk verification failed');

            verified
        }
    }
}

