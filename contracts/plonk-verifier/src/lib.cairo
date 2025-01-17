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

    const PAIRING_CLASS_HASH: felt252 = 0x076a5e592f61c4b87741ad5f7026f2dc818f227b21936cc3ef5220ff3693c0b7;

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
            let (A1, vk_X2, B1, g2_one) =
                plonk_verifier::plonk::verify::PlonkVerifier::verify_except_pairing(
                    verification_key, proof, public_signals
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

