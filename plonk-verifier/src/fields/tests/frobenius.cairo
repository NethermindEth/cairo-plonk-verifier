use core::circuit::conversions::from_u256;
use plonk_verifier::traits::{FieldOps, FieldUtils};
use plonk_verifier::fields::{fq12, Fq12, Fq6, fq6, Fq12Ops};
use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq};
use debug::PrintTrait;

fn frobenius_fq12() -> Array<Fq12> {
    array![
        fq12(
            from_u256(0x1da92e958487e1515456e89aa06f4b08040231ec5492a3873c0e5a51743b93ae),
            from_u256(0x13b8616ce25df6105d793af41913a57b0ab221b193d48107e89204e19568411f),
            from_u256(0x1c8ab87de856aafdfb56d051cd79517ae10b4490cc01bd75b347a669d58698da),
            from_u256(0x2e7918e3f3702ec1f031bcd571b3c23730ab030a0e7a875c6f99f4536ab3f0bb),
            from_u256(0x21f3d1e320a26684b45a7f73a82bbcdabcee7b6b7f1b1073985de6d4f3867bcd),
            from_u256(0x2cbf9b28de156b9f479d3a97a216b566d98f9b976f25a5ca31fbab41d9de224d),
            from_u256(0x2da44e38ec26bde1ad31495943114856dd885beb7889c590079bb300bb6ec023),
            from_u256(0x1c40f4619c21dbd91ba610a8943188e35402e587a071361f60288e7e96fa33b),
            from_u256(0x9ebfb41a99f28109afed1112aab3c8ab4ff6dd90097e880669c960f11106b52),
            from_u256(0x2d0c275838257edb77665b9aafbbd40626b6a35fe12b4ccacee5613bf3408fc2),
            from_u256(0x289d6d934bc5994e10f4dc4bfe3a5ac9cddfce66ee76df1e751b064bfdb5533d),
            from_u256(0x1e18e64906693e6f4c9cd40273060c504a78843d903489abb13377666679d33f),
        ),
        fq12(
            from_u256(0x1da92e958487e1515456e89aa06f4b08040231ec5492a3873c0e5a51743b93ae),
            from_u256(0x1cabed05fed3aa195ad70ac2686db2e28ccf48dfd49d4985538e87354314bc28),
            from_u256(0x210fee6a80e0af180d53ba3486b1e290a7ca6eaf838db44cef69521387db92ac),
            from_u256(0x10d14b7f2127f81e89c4678c5c100f7a1cbaf9bb8835e4f5927d9f66da9114d7),
            from_u256(0x1fb725796926535e7d527be5ec4e49984322d769d3167011eacf38fa9f5ec4d9),
            from_u256(0xacf5ceac1dc780786ad2177908c734283d52498371c3b5aa661a5ae4e06afa5),
            from_u256(0x118cf24be0f6571d2b5a834143435f3ccb0e17f01218cea61f3f41c9fd3a54a9),
            from_u256(0xf4daafb717af193454617ea66f0dd8a36d5cb7cf704530f4327ac4eb369cfe5),
            from_u256(0x537929a89d7c274be0a4665355726071a3efd5a7f9a2ebec75902e39868bdec),
            from_u256(0x1a1a45294d7ffee8485e249d409373b941f120fbeac33bdee24f8aedcbd2e9e2),
            from_u256(0xc01a7aeb72452da867b00a61eaf175e59b1febc687a99e5127f7085514e7492),
            from_u256(0x18e1e1c3c30021f6c16383318a0c2c198f0a3b39647c89743659158f73841704),
        ),
        fq12(
            from_u256(0x1da92e958487e1515456e89aa06f4b08040231ec5492a3873c0e5a51743b93ae),
            from_u256(0x13b8616ce25df6105d793af41913a57b0ab221b193d48107e89204e19568411f),
            from_u256(0x11d39d54c80149a00e50510c0c8d6d2777d22a42646147233d6dd55c97095f88),
            from_u256(0x1ffabaa3134fd66d2f1c13c6181e6e5af5280422a7f530f8b3e70009822a1d46),
            from_u256(0x1fb0e8c9138700bb8e4573760403b67a1422520c17b57ba0c88ca553a99567f0),
            from_u256(0x1ad2d38a612cc3689924050a65f40795dbf40f1a59dc9877c37fb1393d3cd7eb),
            from_u256(0x2b292a1be09a58191905677ac92707867784beb9c4c66d36c13ecec89d174f0c),
            from_u256(0x4c033e9b233f579e384c6f13455ad6372230969dc40af64039cdd1eca619931),
            from_u256(0x26785331379278191d5174a556d61bd2e281fcb867d9e20cd583f607c76c91f5),
            from_u256(0x358271aa90c214e40e9ea1bd1c5845770cac73187467dc26d3b2adae53c6d85),
            from_u256(0x155bf1e813f4b46eb9bca31ccc0601b25bdd4f330c76e7af566b15ae4487b8c2),
            from_u256(0x21cecc3195e9b2eb591861cdd8cfcdc95084aa0c1b2d6cd13a9620c0f75a0c71),
        ),
        // Continue replacing all numbers similarly
    ]
}

// #[test]
// fn fq12_frobenius_all() {
//     let frobenius_maps = frobenius_fq12();
//     let input = *frobenius_maps[0];
//     let mut i = 0;
//     loop {
//         i += 1;
//         if i == frobenius_maps.len() {
//             break;
//         }
//         assert(input.frobenius_map(i) == *frobenius_maps[i], 'incorrect frobenius 0' + i.into())
//     }
// }
