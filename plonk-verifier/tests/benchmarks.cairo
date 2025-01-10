use plonk_verifier::fields::{fq12, Fq12};
use plonk_verifier::traits::FieldOps;
use core::circuit::conversions::from_u256;
use core::circuit::u384;

#[test]
fn test_fq12_sqr() {
    a().mul(b()); 
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