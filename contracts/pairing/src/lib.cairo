use plonk_verifier::curve::groups::{AffineG1, AffineG2};

#[starknet::interface]
trait IPairing<T> {
    // fn valid_pairing(
    //     ref self: T, point1G1: AffineG1, point1G2: AffineG2, point2G1: AffineG1, point2G2:
    //     AffineG2
    // ) -> bool;
    fn test(ref self: T);
}

#[starknet::contract]
mod pairing {
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

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl Pairing_check of super::IPairing<ContractState> {
        // fn valid_pairing(
        //     ref self: ContractState,
        //     point1G1: AffineG1,
        //     point1G2: AffineG2,
        //     point2G1: AffineG1,
        //     point2G2: AffineG2
        // ) -> bool {
        //     let ec_pair_1 = single_ate_pairing(point1G1, point1G2);
        //     let ec_pair_2 = single_ate_pairing(point2G1, point2G2);

        //     let res: bool = ec_pair_1 == ec_pair_2;

        //     res
        // }
        fn test(ref self: ContractState) {
            // let zero = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };
            // let one = u384 { limb0: 1, limb1: 0, limb2: 0, limb3: 0 };
            // let two = u384 { limb0: 2, limb1: 0, limb2: 0, limb3: 0 };
            // let fq12_var = fq12(
            //     zero, // a0
            //     one, // a1
            //     two, // a2
            //     zero, // a3
            //     one, // a4
            //     two, // a5
            //     one, // b0
            //     two, // b1
            //     zero, // b2
            //     one, // b3
            //     two, // b4
            //     zero // b5
            // );
            // let a: Fq2 = Fq2 { c0: fq(zero), c1: fq(one) };
            // let b: Fq2 = Fq2 { c0: fq(zero), c1: fq(two) };
            let m = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
            // let o = a.mul(b, m);
            // let o = Fq12Exponentiation::final_exponentiation(fq12_var, m);
            let a1_x = Fq {
                c0: u384 {
                    limb0: 3209527847428690266530783740,
                    limb1: 55337686315757186000162450659,
                    limb2: 2212770980232976579,
                    limb3: 0,
                },
            };
            let a1_y = Fq {
                c0: u384 {
                    limb0: 78044359350417384183944496129,
                    limb1: 6173955170862308429817299390,
                    limb2: 2915957127384411288,
                    limb3: 0,
                },
            };

            // Create AffineG1
            let affine_g1: AffineG1 = AffineG1 { x: a1_x, y: a1_y };

            // vk x2 values for AffineG2
            let vk_x2_x_c0 = Fq {
                c0: u384 {
                    limb0: 18353151190051857166641552021,
                    limb1: 52786476996209570262942893618,
                    limb2: 326064827328795136,
                    limb3: 0,
                },
            };
            let vk_x2_x_c1 = Fq {
                c0: u384 {
                    limb0: 20192752979982682526746928346,
                    limb1: 52899724692943572339616162160,
                    limb2: 228410087665646553,
                    limb3: 0,
                },
            };

            let vk_x2_y_c0 = Fq {
                c0: u384 {
                    limb0: 63095858333796245672569770745,
                    limb1: 40333516049151993280954701381,
                    limb2: 161315476375980791,
                    limb3: 0,
                },
            };
            let vk_x2_y_c1 = Fq {
                c0: u384 {
                    limb0: 43875589942346715297683682426,
                    limb1: 18625475627853803198435279565,
                    limb2: 667673862985451015,
                    limb3: 0,
                },
            };

            // Create Fq2 values for vk x2
            let vk_x2_x = Fq2 { c0: vk_x2_x_c0, c1: vk_x2_x_c1 };
            let vk_x2_y = Fq2 { c0: vk_x2_y_c0, c1: vk_x2_y_c1 };

            // Create AffineG2
            let affine_g2: AffineG2 = AffineG2 { x: vk_x2_x, y: vk_x2_y };

            let o: Fq12 = ate_miller_loop(affine_g1, affine_g2, m);
            // println!("{:?}", o);
        }
    }
}
