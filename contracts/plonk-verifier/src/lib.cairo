pub use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};
pub use plonk_verifier::plonk::verify;
use core::array::ArrayTrait;

#[starknet::interface]
trait IVerifier<T> {
    // fn verify(
    //     ref self: T,
    //     verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: Array<u256>
    // );
    fn verify(ref self: T) -> bool;
}

#[starknet::contract]
mod PLONK_Verifier {
    use core::array::ArrayTrait;

    use plonk_verifier::plonk::verify;
    use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};
    use plonk_verifier::plonk::constants;
    use plonk_verifier::curve::groups::{AffineG1, AffineG2, fq, fq2};
    use plonk_verifier::curve::constants::{FIELD_U384};
    use core::circuit::{CircuitModulus, u384};
    use core::starknet::{ContractAddress, ClassHash};
    use starknet::SyscallResultTrait;

    const PAIRING_CLASS_HASH: felt252 =
        0x0225d938fb98c4614ee1a9f8fef4fab4d4c6b2c0b961f07e7d970319c09ac223;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl PLONK_verifier of super::IVerifier<ContractState> {
        // fn verify(ref self: ContractState, verification_key: PlonkVerificationKey, proof:
        // PlonkProof, publicSignals: Array<u256>) {
        fn verify(ref self: ContractState) -> bool {
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
            // let verified: bool = plonk_verifier::plonk::verify::PlonkVerifier::verify(
            //     verification_key, proof, public_signals
            // );

            let A1: AffineG1 = AffineG1 {
                x: fq(
                    u384 {
                        limb0: 3209527847428690266530783740,
                        limb1: 55337686315757186000162450659,
                        limb2: 2212770980232976579,
                        limb3: 0
                    }
                ),
                y: fq(
                    u384 {
                        limb0: 46346148385340027716068912668,
                        limb1: 18720056049288877884169473976,
                        limb2: 575822920149061695,
                        limb3: 0
                    }
                )
            };

            let vk_X2: AffineG2 = AffineG2 {
                x: fq2(
                    c0: u384 {
                        limb0: 18353151190051857166641552021,
                        limb1: 52786476996209570262942893618,
                        limb2: 326064827328795136,
                        limb3: 0
                    },
                    c1: u384 {
                        limb0: 20192752979982682526746928346,
                        limb1: 52899724692943572339616162160,
                        limb2: 228410087665646553,
                        limb3: 0
                    }
                ),
                y: fq2(
                    c0: u384 {
                        limb0: 63095858333796245672569770745,
                        limb1: 40333516049151993280954701381,
                        limb2: 161315476375980791,
                        limb3: 0
                    },
                    c1: u384 {
                        limb0: 43875589942346715297683682426,
                        limb1: 18625475627853803198435279565,
                        limb2: 667673862985451015,
                        limb3: 0
                    }
                )
            };

            let B1: AffineG1 = AffineG1 {
                x: fq(
                    u384 {
                        limb0: 32095932548263576516832882190,
                        limb1: 27627422231292153826551667087,
                        limb2: 462671122537780448,
                        limb3: 0
                    }
                ),
                y: fq(
                    u384 {
                        limb0: 78044359350417384183944496129,
                        limb1: 6173955170862308429817299390,
                        limb2: 2915957127384411288,
                        limb3: 0
                    }
                )
            };

            let g2_one: AffineG2 = AffineG2 {
                x: fq2(
                    c0: u384 {
                        limb0: 76557470010646440223880443629,
                        limb1: 20554158673455205572365460180,
                        limb2: 1729627375292849782,
                        limb3: 0
                    },
                    c1: u384 {
                        limb0: 16608105193690117206132855490,
                        limb1: 35398253349670310571043080499,
                        limb2: 1841571559660931130,
                        limb3: 0
                    }
                ),
                y: fq2(
                    c0: u384 {
                        limb0: 3795816841589068238738324906,
                        limb1: 23109153040746773545607096169,
                        limb2: 1353435754470862315,
                        limb3: 0
                    },
                    c1: u384 {
                        limb0: 34879393886474593551643744091,
                        limb1: 73230198318264633228027179315,
                        limb2: 650358724130500725,
                        limb3: 0
                    }
                )
            };

            let mut call_data: Array<felt252> = array![];
            Serde::serialize(@A1, ref call_data);
            Serde::serialize(@vk_X2, ref call_data);
            Serde::serialize(@B1, ref call_data);
            Serde::serialize(@g2_one, ref call_data);

            let mut res_serialized = core::starknet::syscalls::library_call_syscall(
                PAIRING_CLASS_HASH.try_into().unwrap(), selector!("valid_pairing"), call_data.span()
            )
                .unwrap_syscall();
            let call_res = Serde::<bool>::deserialize(ref res_serialized).unwrap();
            let verified: bool = call_res;
            assert(verified, 'plonk verification failed');
            verified
        }
    }
}

