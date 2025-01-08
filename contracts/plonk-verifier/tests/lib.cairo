use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use pairing_contract::{IPairingDispatcher, IPairingDispatcherTrait};
use plonk_verifier_contract::{IVerifierDispatcher, IVerifierDispatcherTrait};

#[test]
fn call_and_invoke() {
    //pairing contract
    let pairing_contract = declare("pairing").unwrap().contract_class();
    let (pairing_contract_address, _) = pairing_contract.deploy(@array![]).unwrap();
    let pairing_class_hash = pairing_contract.class_hash;
    // First declare and deploy a contract
    let contract = declare("PLONK_Verifier").unwrap().contract_class();
    // Alternatively we could use `deploy_syscall` here
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    // Create a Dispatcher object that will allow interacting with the deployed contract
    let dispatcher = IVerifierDispatcher { contract_address };

    let valid = dispatcher.verify();
    assert(valid, 'invalid plonk proof');
}
