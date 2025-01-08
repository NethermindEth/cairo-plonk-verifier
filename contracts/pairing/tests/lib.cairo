use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use pairing_contract::{IPairingDispatcher, IPairingDispatcherTrait};
use plonk_verifier::curve::groups::{AffineG1, AffineG2, fq, fq2};
use core::circuit::u384;

#[test]
fn call_and_invoke() {
    // First declare and deploy a contract
    let contract = declare("pairing").unwrap().contract_class();

    // Alternatively we could use `deploy_syscall` here
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    // Create a Dispatcher object that will allow interacting with the deployed contract
    let dispatcher = IPairingDispatcher { contract_address };

    // Call a view function of the contract
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
    let A1_serialized = Serde::serialize(@A1, ref call_data);
    Serde::serialize(@vk_X2, ref call_data);
    Serde::serialize(@B1, ref call_data);
    Serde::serialize(@g2_one, ref call_data);

    let valid = dispatcher.valid_pairing(A1, vk_X2, B1, g2_one);

    assert(valid, 'invalid pairing');
}
