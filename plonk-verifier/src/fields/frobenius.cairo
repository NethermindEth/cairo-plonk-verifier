use core::circuit::u384;
use core::circuit::conversions::from_u256;

mod fp {
    // NONRESIDUE, β = -1 = (FIELD - 1)
    const NONRESIDUE_C0: u256 =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
}

mod fp2 {
    // NONRESIDUE, ξ = 9+U
    const NONRESIDUE_C0: u256 = 9;
    const NONRESIDUE_C1: u256 = 1;
}

mod fp6 {
    // FQ6 Frobenius coefficients
    // https://github.com/arkworks-rs/algebra/blob/master/curves/bn254/src/fields/fq6.rs

    // Fp2::NONRESIDUE^(((q^0) - 1) / 3)
    const Q_0_C0: u256 = 1;
    const Q_0_C1: u256 = 0;

    // Fp2::NONRESIDUE^(((q^1) - 1) / 3)
    const Q_1_C0: u256 =
        21575463638280843010398324269430826099269044274347216827212613867836435027261;
    const Q_1_C1: u256 =
        10307601595873709700152284273816112264069230130616436755625194854815875713954;

    // Fp2::NONRESIDUE^(((q^2) - 1) / 3)
    const Q_2_C0: u256 =
        21888242871839275220042445260109153167277707414472061641714758635765020556616;
    const Q_2_C1: u256 = 0;

    // Fp2::NONRESIDUE^(((q^3) - 1) / 3)
    const Q_3_C0: u256 =
        3772000881919853776433695186713858239009073593817195771773381919316419345261;
    const Q_3_C1: u256 =
        2236595495967245188281701248203181795121068902605861227855261137820944008926;

    // Fp2::NONRESIDUE^(((q^4) - 1) / 3)
    const Q_4_C0: u256 = 2203960485148121921418603742825762020974279258880205651966;
    const Q_4_C1: u256 = 0;

    // Fp2::NONRESIDUE^(((q^5) - 1) / 3)
    const Q_5_C0: u256 =
        18429021223477853657660792034369865839114504446431234726392080002137598044644;
    const Q_5_C1: u256 =
        9344045779998320333812420223237981029506012124075525679208581902008406485703;

    // Fp2::NONRESIDUE^((2*(q^0) - 2) / 3)
    const Q2_0_C0: u256 = 1;
    const Q2_0_C1: u256 = 0;

    // Fp2::NONRESIDUE^((2*(q^1) - 2) / 3)
    const Q2_1_C0: u256 =
        2581911344467009335267311115468803099551665605076196740867805258568234346338;
    const Q2_1_C1: u256 =
        19937756971775647987995932169929341994314640652964949448313374472400716661030;

    // Fp2::NONRESIDUE^((2*(q^2) - 2) / 3)
    const Q2_2_C0: u256 = 2203960485148121921418603742825762020974279258880205651966;
    const Q2_2_C1: u256 = 0;

    // Fp2::NONRESIDUE^((2*(q^3) - 2) / 3)
    const Q2_3_C0: u256 =
        5324479202449903542726783395506214481928257762400643279780343368557297135718;
    const Q2_3_C1: u256 =
        16208900380737693084919495127334387981393726419856888799917914180988844123039;

    // Fp2::NONRESIDUE^((2*(q^4) - 2) / 3)
    const Q2_4_C0: u256 =
        21888242871839275220042445260109153167277707414472061641714758635765020556616;
    const Q2_4_C1: u256 = 0;

    // Fp2::NONRESIDUE^((2*(q^5) - 2) / 3)
    const Q2_5_C0: u256 =
        13981852324922362344252311234282257507216387789820983642040889267519694726527;
    const Q2_5_C1: u256 =
        7629828391165209371577384193250820201684255241773809077146787135900891633097;
}

mod fp12 {
    use super::u384;
    // FQ12 Frobenius coefficients
    // https://github.com/arkworks-rs/algebra/blob/master/curves/bn254/src/fields/fq12.rs

    // Fp2::NONRESIDUE^(((q^0) - 1) / 6)
    const Q_0_C0: u384 = u384 { limb0: 1, limb1: 0, limb2: 0, limb3: 0 };
    const Q_0_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^1) - 1) / 6)
    const Q_1_C0: u384 = u384 { limb0: 12745862946430251347930113136, limb1: 72024928496749667491970686472, limb2: 1334392721173227487, limb3: 0 };
    const Q_1_C1: u384 = u384 { limb0: 44235539729515559427878642348, limb1: 51435548181543843798942585463, limb2: 2623794231377586150, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^2) - 1) / 6)
    const Q_2_C0: u384 = u384 { limb0: 58055556311580632348199025993, limb1: 29224392868458634600130741919, limb2: 3486998266802970665, limb3: 0 };
    const Q_2_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^3) - 1) / 6)
    const Q_3_C0: u384 = 
    const Q_3_C1: u384 = 

    // Fp2::NONRESIDUE^(((q^4) - 1) / 6)
    const Q_4_C0: u384 = 
    const Q_4_C1: u384 = 

    // Fp2::NONRESIDUE^(((q^5) - 1) / 6)
    const Q_5_C0: u384 = 
    const Q_5_C1: u384 = 

    // Fp2::NONRESIDUE^(((q^6) - 1) / 6)
    const Q_6_C0: u384 = 
    const Q_6_C1: u384 = 

    // Fp2::NONRESIDUE^(((q^7) - 1) / 6)
    const Q_7_C0: u384 = 
    const Q_7_C1: u384 = 

    // Fp2::NONRESIDUE^(((q^8) - 1) / 6)
    const Q_8_C0: u384 = 
    const Q_8_C1: u384 = 

    // Fp2::NONRESIDUE^(((q^9) - 1) / 6)
    const Q_9_C0: u384 = 
    const Q_9_C1: u384 = 

    // Fp2::NONRESIDUE^(((q^10) - 1) / 6)
    const Q_10_C0: u384 = 
    const Q_10_C1: u384 = 

    // Fp2::NONRESIDUE^(((q^11) - 1) / 6)
    const Q_11_C0: u384 = 
    const Q_11_C1: u384 = 
}

mod pi {
    use super::u384;
    // π (Pi) - Untwist-Frobenius-Twist Endomorphisms on twisted curves
    // -----------------------------------------------------------------
    // BN254_Snarks is a D-Twist: pi1_coef1 = ξ^((p-1)/6)
    // https://github.com/mratsim/constantine/blob/976c8bb215a3f0b21ce3d05f894eb506072a6285/constantine/math/constants/bn254_snarks_frobenius.nim#L131
    // In the link above this is referred to as ψ (Psi)

    // pi2_coef3 is always -1 (mod p^m) with m = embdeg/twdeg
    // Recap, with ξ (xi) the sextic non-residue for D-Twist or 1/SNR for M-Twist
    // pi_2 ≡ ξ^((p-1)/6)^2 ≡ ξ^(2(p-1)/6) ≡ ξ^((p-1)/3)
    // pi_3 ≡ pi_2 * ξ^((p-1)/6) ≡ ξ^((p-1)/3) * ξ^((p-1)/6) ≡ ξ^((p-1)/2)

    // -----------------------------------------------------------------
    // for πₚ mapping

    // Fp2::NONRESIDUE^(2((q^1) - 1) / 6)
    const Q1X2_C0: u384 = u384 { limb0: 60276073513306222166899905853, limb1: 23535274533411944519468630800, limb2: 3437169660107756023, limb3: 0 };
    const Q1X2_C1: u384 = u384 { limb0: 3554987122848029851499088802, limb1: 23410605513395334791406955037, limb2: 1642095672556236320, limb3: 0 };

    // Fp2::NONRESIDUE^(3((q^1) - 1) / 6)
    const Q1X3_C0: u384 = u384 { limb0: 52546383859948247669333300058, limb1: 68201279033386767691767537901, limb2: 449501266848708060, limb3: 0 };
    const Q1X3_C1: u384 = u384 { limb0: 44452636005823129879501320419, limb1: 2172088618007306609220419017, limb2: 558513134835401882, limb3: 0 };

    // -----------------------------------------------------------------
    // for π² mapping

    // Fp2::NONRESIDUE^(2(p^2-1)/6)
    const Q2X2_C0: u256 = 0x30644e72e131a0295e6dd9e7e0acccb0c28f069fbb966e3de4bd44e5607cfd48;
    const Q2X2_C1: u256 = 0x0;
    // Fp2::NONRESIDUE^(3(p^2-1)/6)
    const Q2X3_C0: u256 = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd46;
    const Q2X3_C1: u256 = 0x0;
}


#[test]
fn test_out() {
    println!("{:?}", from_u256(pi::Q2X2_C0));
    println!("{:?}", from_u256(pi::Q2X3_C0));
    println!("fp12 1{:?}", from_u256(fp12::Q_1_C0));
    println!("fp12 1{:?}", from_u256(fp12::Q_1_C1));
    println!("fp12 2{:?}", from_u256(fp12::Q_2_C0));
    println!("fp12 2{:?}", from_u256(fp12::Q_2_C1));
    println!("fp12 3{:?}", from_u256(fp12::Q_3_C0));
    println!("fp12 3{:?}", from_u256(fp12::Q_3_C1));
    println!("fp12 4{:?}", from_u256(fp12::Q_4_C0));
    println!("fp12 4{:?}", from_u256(fp12::Q_4_C1));
    println!("fp12 5{:?}", from_u256(fp12::Q_5_C0));
    println!("fp12 5{:?}", from_u256(fp12::Q_5_C1));
    println!("fp12 6{:?}", from_u256(fp12::Q_6_C0));
    println!("fp12 6{:?}", from_u256(fp12::Q_6_C1));
    println!("fp12 7{:?}", from_u256(fp12::Q_7_C0));
    println!("fp12 7{:?}", from_u256(fp12::Q_7_C1));
    println!("fp12 8{:?}", from_u256(fp12::Q_8_C0));
    println!("fp12 8{:?}", from_u256(fp12::Q_8_C1));
    println!("fp12 9{:?}", from_u256(fp12::Q_9_C0));
    println!("fp12 9{:?}", from_u256(fp12::Q_9_C1));
    println!("fp12 10{:?}", from_u256(fp12::Q_10_C0));
    println!("fp12 10{:?}", from_u256(fp12::Q_10_C1));
    println!("fp12 11{:?}", from_u256(fp12::Q_11_C0));
    println!("fp12 11{:?}", from_u256(fp12::Q_11_C1));

}