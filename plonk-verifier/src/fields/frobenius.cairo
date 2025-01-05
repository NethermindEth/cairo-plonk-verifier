use core::circuit::{u384, conversions::from_u256};


mod fp {
    use super::u384;

    // NONRESIDUE, β = -1 = (FIELD - 1)
    const NONRESIDUE_C0: u384 = u384 { limb0: 32324006162389411176778628423, limb1: 57042285082623239461879769745, limb2: 3486998266802970665, limb3: 0 };
}

mod fp2 {
    use super::u384;

    // NONRESIDUE, ξ = 9+U
    const NONRESIDUE_C0: u384 = u384 { limb0: 9, limb1: 0, limb2: 0, limb3: 0 };
    const NONRESIDUE_C1: u384 = u384 { limb0: 1, limb1: 0, limb2: 0, limb3: 0 };
}

mod fp6 {
    use super::u384;

    // FQ6 Frobenius coefficients
    // https://github.com/arkworks-rs/algebra/blob/master/curves/bn254/src/fields/fq6.rs

    // Fp2::NONRESIDUE^(((q^0) - 1) / 3)
    const Q_0_C0: u384 = u384 { limb0: 1, limb1: 0, limb2: 0, limb3: 0 };
    const Q_0_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^1) - 1) / 3)
    const Q_1_C0: u384 = u384 { limb0: 60276073513306222166899905853, limb1: 23535274533411944519468630800, limb2: 3437169660107756023, limb3: 0 };
    const Q_1_C1: u384 = u384 { limb0: 3554987122848029851499088802, limb1: 23410605513395334791406955037, limb2: 1642095672556236320, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^2) - 1) / 3)
    const Q_2_C0: u384 = u384 { limb0: 58055556311580632348199025992, limb1: 29224392868458634600130741919, limb2: 3486998266802970665, limb3: 0 };
    const Q_2_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^3) - 1) / 3)
    const Q_3_C0: u384 = u384 { limb0: 28909358701791353512801401709, limb1: 57872622342977355799628610877, limb2: 600914409377099530, limb3: 0 };
    const Q_3_C1: u384 = u384 { limb0: 47350177934701780713882355422, limb1: 52596803774815834190555066815, limb2: 356310219310069359, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^4) - 1) / 3)
    const Q_4_C0: u384 = u384 { limb0: 53496612365073116422123552766, limb1: 27817892214164604861749027825, limb2: 0, limb3: 0 };
    const Q_4_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^5) - 1) / 3)
    const Q_5_C0: u384 = u384 { limb0: 54690742623945584267399899620, limb1: 32676673288857178604662297812, limb2: 2935912464121085777, limb3: 0 };
    const Q_5_C1: u384 = u384 { limb0: 60647003619103938204941134535, limb1: 60263038308676408073461698228, limb2: 1488592374936664985, limb3: 0 };

    // Fp2::NONRESIDUE^((2*(q^0) - 2) / 3)
    const Q2_0_C0: u384 = u384 { limb0: 1, limb1: 0, limb2: 0, limb3: 0 };
    const Q2_0_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^((2*(q^1) - 2) / 3)
    const Q2_1_C0: u384 = u384 { limb0: 58982189478327790226900952930, limb1: 39908760307909372565636998647, limb2: 411322207813150721, limb3: 0 };
    const Q2_1_C1: u384 = u384 { limb0: 8625418388212319703725211942, limb1: 49278841972922804394128691946, limb2: 3176267935786044142, limb3: 0 };

    // Fp2::NONRESIDUE^((2*(q^2) - 2) / 3)
    const Q2_2_C0: u384 = u384 { limb0: 53496612365073116422123552766, limb1: 27817892214164604861749027825, limb2: 0, limb3: 0 };
    const Q2_2_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^((2*(q^3) - 2) / 3)
    const Q2_3_C0: u384 = u384 { limb0: 36423026132268547793721487462, limb1: 7967883530790957440480512325, limb2: 848238474841591211, limb3: 0 };
    const Q2_3_C1: u384 = u384 { limb0: 35745022294732191648619176863, limb1: 78823129550724274519485881864, limb2: 2582226808490494482, limb3: 0 };

    // Fp2::NONRESIDUE^((2*(q^4) - 2) / 3)
    const Q2_4_C0: u384 = u384 { limb0: 58055556311580632348199025992, limb1: 29224392868458634600130741919, limb2: 3486998266802970665, limb3: 0 };
    const Q2_4_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^((2*(q^5) - 2) / 3)
    const Q2_5_C0: u384 = u384 { limb0: 16146953066057410749700138367, limb1: 9165641243922909455762258772, limb2: 2227437584148228733, limb3: 0 };
    const Q2_5_C1: u384 = u384 { limb0: 20277571641834311001212868041, limb1: 65210761155863737603688916016, limb2: 1215501789329402705, limb3: 0 };
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
    const Q_3_C0: u384 = u384 { limb0: 58905903639492013841058145919, limb1: 74249053008034786621845713805, limb2: 1863507075313886395, limb3: 0 };
    const Q_3_C1: u384 = u384 { limb0: 46988802293647173226506273025, limb1: 2103450114795955940866893283, limb2: 48405681784978803, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^4) - 1) / 6)
    const Q_4_C0: u384 = u384 { limb0: 58055556311580632348199025992, limb1: 29224392868458634600130741919, limb2: 3486998266802970665, limb3: 0 };
    const Q_4_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^5) - 1) / 6)
    const Q_5_C0: u384 = u384 { limb0: 46160040693061762493128032783, limb1: 2224124511285119129875027333, limb2: 529114354140658908, limb3: 0 };
    const Q_5_C1: u384 = u384 { limb0: 35077268726521024975406259100, limb1: 7710187015875351603804077565, limb2: 911609717210363318, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^6) - 1) / 6)
    const Q_6_C0: u384 = u384 { limb0: 32324006162389411176778628422, limb1: 57042285082623239461879769745, limb2: 3486998266802970665, limb3: 0 };
    const Q_6_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^7) - 1) / 6)
    const Q_7_C0: u384 = u384 { limb0: 19578143215959159828848515287, limb1: 64245519100137909563453033609, limb2: 2152605545629743177, limb3: 0 };
    const Q_7_C1: u384 = u384 { limb0: 67316628947138189342443936411, limb1: 5606736901079395662937184281, limb2: 863204035425384515, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^8) - 1) / 6)
    const Q_8_C0: u384 = u384 { limb0: 53496612365073116422123552766, limb1: 27817892214164604861749027825, limb2: 0, limb3: 0 };
    const Q_8_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^9) - 1) / 6)
    const Q_9_C0: u384 = u384 { limb0: 52646265037161734929264432840, limb1: 62021394588852790433578006275, limb2: 1623491191489084269, limb3: 0 };
    const Q_9_C1: u384 = u384 { limb0: 64563366383006575543816305734, limb1: 54938834967827283521012876461, limb2: 3438592585017991862, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^10) - 1) / 6)
    const Q_10_C0: u384 = u384 { limb0: 53496612365073116422123552767, limb1: 27817892214164604861749027825, limb2: 0, limb3: 0 };
    const Q_10_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };

    // Fp2::NONRESIDUE^(((q^11) - 1) / 6)
    const Q_11_C0: u384 = u384 { limb0: 65392127983591986277194545976, limb1: 54818160571338120332004742411, limb2: 2957883912662311757, limb3: 0 };
    const Q_11_C1: u384 = u384 { limb0: 76474899950132723794916319659, limb1: 49332098066747887858075692179, limb2: 2575388549592607347, limb3: 0 };
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
    const Q2X2_C0: u384 = u384 { limb0: 58055556311580632348199025992, limb1: 29224392868458634600130741919, limb2: 3486998266802970665, limb3: 0 };
    const Q2X2_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };
    // Fp2::NONRESIDUE^(3(p^2-1)/6)
    const Q2X3_C0: u384 = u384 { limb0: 32324006162389411176778628422, limb1: 57042285082623239461879769745, limb2: 3486998266802970665, limb3: 0 };
    const Q2X3_C1: u384 = u384 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };
}
