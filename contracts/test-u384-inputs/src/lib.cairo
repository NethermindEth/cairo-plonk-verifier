use core::circuit::u384;
pub use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};

#[starknet::interface]
trait ICircuit<T> {
    fn input_test(ref self: T, c: u256, d:u256, a: u384, b: u384) -> bool;
    fn input_test_public_inputs(ref self: T, public_signals: Array<u384>) -> bool;
    fn input_test_vk(ref self: T, vk: PlonkVerificationKey) -> bool;
    fn input_test_proof(ref self: T, proof: PlonkProof) -> bool;
    fn input_test_proof_and_public_signals(ref self: T, proof: PlonkProof, public_signals:Array<u384>) -> bool;
}

#[starknet::contract]
mod Circuit {
    use starknet::event::EventEmitter;
    use super::ICircuit;
    use plonk_verifier::curve::groups::{AffineG1, AffineG2, ECOperationsCircuitFq};
    use plonk_verifier::curve::pairing::optimal_ate::single_ate_pairing;
    use plonk_verifier::fields::{Fq2Ops, Fq2, fq, Fq12Exponentiation, fq12, Fq, Fq12};
    use plonk_verifier::curve::constants::FIELD_U384;
    use plonk_verifier::curve::pairing::optimal_ate::ate_miller_loop;

    use plonk_verifier::plonk::types::{PlonkVerificationKey, PlonkProof};
    use core::circuit::{
        AddInputResultTrait, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
        CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, circuit_add, circuit_inverse,
        circuit_mul, circuit_sub, u384, U384Serde
    };

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl Circuit_test of super::ICircuit<ContractState> {
        fn input_test(ref self: ContractState,  c: u256, d:u256, a: u384, b: u384) -> bool {
            let in1 = CircuitElement::<CircuitInput<0>> {};
            let in2 = CircuitElement::<CircuitInput<1>> {};
            let add = circuit_add(in1, in2);
            let m = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

            let outputs = (add,).new_inputs().next(a).next(b).done().eval(m).unwrap();

            let o = outputs.get_output(add);
            let mut res: bool = false;
            let test_o = u384 { limb0: 2, limb1: 0, limb2: 0, limb3: 0 };
            if o == test_o {
                res = true;
            } else {
                res = false;
            }

            res
        }
        fn input_test_public_inputs(ref self: ContractState, public_signals: Array<u384>) -> bool{
            
            return true;
        }
        fn input_test_vk(ref self: ContractState, vk: PlonkVerificationKey) -> bool{
            return true;
        }
        fn input_test_proof(ref self: ContractState, proof: PlonkProof) -> bool{
            return true;
        }

        fn input_test_proof_and_public_signals(ref self: ContractState, proof: PlonkProof, public_signals:Array<u384>) -> bool{
            return true;
        }
    }
}

