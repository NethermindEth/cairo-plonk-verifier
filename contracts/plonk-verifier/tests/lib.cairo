use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use pairing_contract::{IPairingDispatcher, IPairingDispatcherTrait};
use plonk_verifier_contract::{IVerifierDispatcher, IVerifierDispatcherTrait};

#[test]
fn call_and_invoke() {
    let pairing_contract = declare("pairing").unwrap().contract_class();
    let (pairing_contract_address, _) = pairing_contract.deploy(@array![]).unwrap();
    let pairing_class_hash = pairing_contract.class_hash;

    let contract = declare("PLONK_Verifier").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    let dispatcher = IVerifierDispatcher { contract_address };

    let valid = dispatcher.verify();
    assert(valid, 'invalid plonk proof');
}
