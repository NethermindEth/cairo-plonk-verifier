use plonk_verifier::curve::groups::{AffineG1, AffineG2};

#[starknet::interface]
trait IPairing<T> {
    fn valid_pairing(
        ref self: T, point1G1: AffineG1, point1G2: AffineG2, point2G1: AffineG1, point2G2: AffineG2
    ) -> bool;
}

#[starknet::contract]
mod pairing {
    use starknet::event::EventEmitter;
    use super::IPairing;
    use plonk_verifier::curve::groups::{AffineG1, AffineG2, ECOperationsCircuitFq};
    use plonk_verifier::curve::pairing::optimal_ate::single_ate_pairing;
    use plonk_verifier::fields::{Fq2Ops, Fq2, fq, Fq12Exponentiation, fq12, Fq, Fq12};
    use plonk_verifier::curve::constants::FIELD_U384;
    use plonk_verifier::curve::pairing::optimal_ate::ate_miller_loop;
    use plonk_verifier::curve::pairing::optimal_ate_impls::{
        SingleMillerPrecompute, SingleMillerSteps
    };

    use core::circuit::{u384, CircuitModulus};

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        PairingCheck: PairingCheck,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct PairingCheck {
        pub res: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl Pairing_check of super::IPairing<ContractState> {
        fn valid_pairing(
            ref self: ContractState,
            point1G1: AffineG1,
            point1G2: AffineG2,
            point2G1: AffineG1,
            point2G2: AffineG2
        ) -> bool {
            let m = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
            let ec_pair_1 = single_ate_pairing(point1G1, point1G2, m);
            let ec_pair_2 = single_ate_pairing(point2G1, point2G2, m);

            let res: bool = ec_pair_1 == ec_pair_2;

            self.emit(PairingCheck { res: res });

            res
        }
    }
}