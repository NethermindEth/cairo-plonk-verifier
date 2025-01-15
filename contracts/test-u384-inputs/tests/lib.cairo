// use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
// use test_circuit_contract::{ICircuitDispatcher, ICircuitDispatcherTrait};
// use plonk_verifier::curve::groups::{AffineG1, AffineG2, fq, fq2};
// use core::circuit::u384;

// #[test]
// fn call_and_invoke() {
//     // First declare and deploy a contract
//     let contract = declare("Circuit").unwrap().contract_class();

//     // Alternatively we could use `deploy_syscall` here
//     let (contract_address, _) = contract.deploy(@array![]).unwrap();

//     // Create a Dispatcher object that will allow interacting with the deployed contract
//     let dispatcher = ICircuitDispatcher { contract_address };

//     let mut call_data: Array<felt252> = array![];
//     let a: u384 = u384 { limb0: 1, limb1: 0, limb2: 1, limb3: 0 };

//     let b: u384 = u384 { limb0: 1, limb1: 0, limb2: 1, limb3: 0 };
//     Serde::serialize(@a, ref call_data);

//     println!("call data: {:?}", call_data.span());
//     Serde::serialize(@b, ref call_data);

//     println!("call data: {:?}", call_data.span());

//     let valid = dispatcher.input_test(a, b);

//     assert(valid, 'invalid pairing');
// }
