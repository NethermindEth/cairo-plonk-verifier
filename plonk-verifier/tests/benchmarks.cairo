use core::circuit::conversions::from_u256;
use core::circuit::u384;

use plonk_verifier::curve::groups::{g1, g2, affine_fq1, affine_fq2, AffineG1, AffineG2, AffineG2Impl, Fq, Fq2};
use plonk_verifier::fields::{fq12, Fq12};
use plonk_verifier::traits::FieldOps;
use plonk_verifier::pairing::optimal_ate::{ate_miller_loop, single_ate_pairing};
use plonk_verifier::plonk::utils::{field_modulus, order_modulus};

// Final benchmarked stepcounts have their type conversions excluded. 
#[test]
fn test_get_circuit_modules() {
    field_modulus();
    order_modulus();
}

#[test]
fn test_get_field_circuit_modulus() {
    field_modulus();
}

#[test]
fn test_fq12_sqr() {
    a().sqr(field_modulus()); 
}

#[test]
fn test_fq12_mul() {
    a().mul(b(), field_modulus()); 
}

#[test]
fn test_from_u256() {
    from_u256(324234324982374982374982374932);
}

#[test]
fn test_single_pairing() {
    let m = field_modulus();
    let b1 = b1();
    let one = AffineG2Impl::one();

    single_ate_pairing(b1, one, m);
}

#[test]
fn test_double_pairing() {
    let m = field_modulus();
    let a1 = a1();
    let b1 = b1();
    let one = AffineG2Impl::one();
    let vk_x2 = vk_x2(); 

    single_ate_pairing(a1, vk_x2, m);
    single_ate_pairing(b1, one, m);
}

#[inline(always)]
fn a() -> Fq12 {
    fq12(
        u384{
            limb0: 26174016235031374933186548654,
            limb1: 26101806886862998257149293036,
            limb2: 2137290717872513361,
            limb3: 0,
        },
        u384{
            limb0: 45751198048657987718099779871,
            limb1: 28928664337626991769481781681,
            limb2: 1420992802717562384,
            limb3: 0,
        },
        u384{
            limb0: 63137045627826804665612671194,
            limb1: 77785688846865132053783594128,
            limb2: 2056659030756469501,
            limb3: 0,
        },
        u384{
            limb0: 4480918312109185153600057531,
            limb1: 74336531464532306206355292938,
            limb2: 3348735165247532737,
            limb3: 0,
        },
        u384{
            limb0: 39337314934658898375578385357,
            limb1: 55816706965644308787753810795,
            limb2: 2446529796027606660,
            limb3: 0,
        },
        u384{
            limb0: 34398349265808680915033793101,
            limb1: 22163513745389080366426332055,
            limb2: 3224466458047507359,
            limb3: 0,
        },
        u384{
            limb0: 37304756978925112973572620323,
            limb1: 53600490443600009176264760299,
            limb2: 3288839634274401761,
            limb3: 0,
        },
        u384{
            limb0: 37765725210965632074650723131,
            limb1: 45100644890450411289963408984,
            limb2: 127243483227495869,
            limb3: 0,
        },
        u384{
            limb0: 183645756363025877583293266,
            limb1: 47968745961933443139953978841,
            limb2: 714941225305581584,
            limb3: 0,
        },
        u384{
            limb0: 69686473661049499551545724866,
            limb1: 36952459191152231743221048159,
            limb2: 3246012691279871707,
            limb3: 0,
        },
        u384{
            limb0: 73801139233760999991540011837,
            limb1: 5247778379578581725460024934,
            limb2: 2926615812259551566,
            limb3: 0,
        },
        u384{
            limb0: 44629355688263721009395913535,
            limb1: 23710454361158289589750236221,
            limb2: 2168736421893455471,
            limb3: 0,
        }
    )    
}

#[inline(always)]
fn b() -> Fq12 {
    fq12(
        u384{
            limb0: 74481645295340537121393535066,
            limb1: 57617686646819143765144676231,
            limb2: 1163356145721461810,
            limb3: 0,
        },
        u384{
            limb0: 27666878897283860319899320214,
            limb1: 5425620461672034561606309024,
            limb2: 1922951244050410524,
            limb3: 0,
        },
        u384{
            limb0: 59745191948859227732945586862,
            limb1: 6790793394273898164773709516,
            limb2: 174647772033068895,
            limb3: 0,
        },
        u384{
            limb0: 14748380680993117639923510437,
            limb1: 28545552140878282898975398856,
            limb2: 2118308183036723365,
            limb3: 0,
        },
        u384{
            limb0: 353054123236628932558455683,
            limb1: 70081324422934474181410539840,
            limb2: 629727801899095145,
            limb3: 0,
        },
        u384{
            limb0: 67277666211725539239167007349,
            limb1: 78252954473211898103990066126,
            limb2: 1032212499980698161,
            limb3: 0,
        },
        u384{
            limb0: 44300817267560279913117988891,
            limb1: 34363975953662963556046649679,
            limb2: 3133535617508878151,
            limb3: 0,
        },
        u384{
            limb0: 39059258580555213854019877395,
            limb1: 69379254055848948361546835754,
            limb2: 2983524042084627122,
            limb3: 0,
        },
        u384{
            limb0: 35566011981443714845592558830,
            limb1: 22178712944836417125230143991,
            limb2: 2960612292916053446,
            limb3: 0,
        },
        u384{
            limb0: 59279168701009722773987995781,
            limb1: 10097715971630388928280920008,
            limb2: 2575108705474278931,
            limb3: 0,
        },
        u384{
            limb0: 37634642850252162347295708916,
            limb1: 43047936007388699694846592005,
            limb2: 2551644000629977901,
            limb3: 0,
        },
        u384{
            limb0: 3955846485032787047031991839,
            limb1: 17341046610821538944480438297,
            limb2: 1223946940893925553,
            limb3: 0,
        }
    )
}

fn a1() -> AffineG1 {
    affine_fq1(
        u384 { limb0: 3209527847428690266530783740, limb1: 55337686315757186000162450659, limb2: 2212770980232976579, limb3: 0 },
        u384 { limb0: 46346148385340027716068912668, limb1: 18720056049288877884169473976, limb2: 575822920149061695, limb3: 0 }
    )
}

fn b1() -> AffineG1 {
    affine_fq1(
        u384 { limb0: 32095932548263576516832882190, limb1: 27627422231292153826551667087, limb2: 462671122537780448, limb3: 0 },
        u384 { limb0: 78044359350417384183944496129, limb1: 6173955170862308429817299390, limb2: 2915957127384411288, limb3: 0 }
    )
}

fn vk_x2() -> AffineG2 {
    affine_fq2(
        u384 { limb0: 18353151190051857166641552021, limb1: 52786476996209570262942893618, limb2: 326064827328795136, limb3: 0 }, 
        u384 { limb0: 20192752979982682526746928346, limb1: 52899724692943572339616162160, limb2: 228410087665646553, limb3: 0 }, 
        u384 { limb0: 63095858333796245672569770745, limb1: 40333516049151993280954701381, limb2: 161315476375980791, limb3: 0 }, 
        u384 { limb0: 43875589942346715297683682426, limb1: 18625475627853803198435279565, limb2: 667673862985451015, limb3: 0 }
    )
}