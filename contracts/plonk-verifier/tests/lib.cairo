use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use plonk_verifier_contract::{IVerifierDispatcher, IVerifierDispatcherTrait};
use plonk_verifier::curve::groups::{AffineG1, AffineG2, fq, fq2};
use core::circuit::{u384, conversions::from_u256};
use plonk_verifier::plonk::types::{PlonkProof, PlonkVerificationKey};
use plonk_verifier::plonk::constants;
use core::array::ArrayTrait;

#[test]
fn call_and_invoke() {
    // let pairing_contract = declare("pairing").unwrap().contract_class();
    // let (pairing_contract_address, _) = pairing_contract.deploy(@array![]).unwrap();

    // First declare and deploy a contract
    let contract = declare("PLONK_Verifier").unwrap().contract_class();

    // Alternatively we could use `deploy_syscall` here
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    // Create a Dispatcher object that will allow interacting with the deployed contract
    let dispatcher = IVerifierDispatcher { contract_address };

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

    

    let mut call_data: Array<felt252> = array![];
    
    
    Serde::serialize(@verification_key, ref call_data);
    Serde::serialize(@proof, ref call_data);
    Serde::serialize(@public_signals, ref call_data);

    let valid = dispatcher.verify(verification_key, proof, public_signals);

    assert(valid, 'invalid pairing');
}
