pub use plonk_verifier::curve::groups::{AffineG1, AffineG2};

use core::array::ArrayTrait;
use core::serde::Serde;

#[starknet::interface]
trait IPairing<T> {
    fn valid_pairing(
        ref self: T, point1G1: AffineG1, point1G2: AffineG2, point2G1: AffineG1, point2G2: AffineG2
    ) -> bool;
}

#[starknet::contract]
mod pairing {
    use super::{AffineG1, AffineG2};
    use plonk_verifier::curve::groups::{ECOperationsCircuitFq};
    use plonk_verifier::curve::pairing::optimal_ate::single_ate_pairing;
    use plonk_verifier::curve::constants::FIELD_U384;

    use core::circuit::{CircuitModulus, u384};
    #[storage]
    struct Storage {}

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

            let res: bool = ec_pair_1.c0 == ec_pair_2.c0;

            res
        }
    }
}
