use core::array::ArrayTrait;
use debug::PrintTrait;
use core::fmt::{Display, Formatter, Error};
use core::circuit::conversions::from_u256;
use core::circuit::u384;
use plonk_verifier::fields::{fq, fq2, fq12, fq6, Fq, Fq12, Fq6};
use plonk_verifier::curve::groups::{g1, g2, AffineG1, AffineG2};

// proof
pub fn proof() -> (
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    Fq,
    Fq,
    Fq,
    Fq,
    Fq,
    Fq
) {
    let A = g1(
        10145682537857657061034453444250060542160735082214568006588482889852729429283,
        4636457826231461981000328909301601529288749856075547745551595540417983094478
    );
    let B = g1(
        21660564883979151853810406117414553745840873935312762552528448427975132123801,
        431924083945838741254227896932504399854190081296419391191918676581449466215
    );
    let C = g1(
        300524113486380036443084320133730704976390221208117258926514144708824506219,
        21619727022743235605210745845312693737352347919465737051661426044094665308814
    );
    let Z = g1(
        11621036917319382368213455539721258895318811708043524885256212235043994348221,
        21246039196291803367698080346255509005358193717060539557589380305575336049896
    );
    let T1 = g1(
        17107906628706336518761596247056028047831631661889424881370327119591791568242,
        4376713913108253438479025804063534613295822606800001423899857948301712836950
    );
    let T2 = g1(
        4946882210289577446362628360627239417903541212231788376323842461238273988498,
        6108750262973085054062535975592877457236993968361694004663488360844602093018
    );
    let T3 = g1(
        18739110241153474740846380343626289353986477668973757185874134865481030609116,
        16807204443624490686473433635066127740967762692116088923481529964422349920723
    );
    let Wxi = g1(
        249137365643743198372736343396439639356782224949744369780220478170143087608,
        7204659473206915962965531490350212209027925663732793950265779901148420044018
    );
    let Wxiw = g1(
        11635031187290428307047811112227226487860489293794570551122061051173340592497,
        19858679635667039421260152403491512225506984963090642670774417328490692605798
    );
    let eval_a = fq(
        from_u256(2571844106989263132471587893183233146441179658087841933671176168068791528026)
    );
    let eval_b = fq(
        from_u256(1745727970934740515253692627472813536705686771154120819099934574357205996472)
    );
    let eval_c = fq(
        from_u256(21569936656389818010443741721610486034148258376828241332837239799889300662695)
    );
    let eval_s1 = fq(
        from_u256(7125532818257293020292427451672312101472703975447783515659573445866782468653)
    );
    let eval_s2 = fq(
        from_u256(5073230176805731877376434031491636687409869382035533898445070196212679413525)
    );
    let eval_zw = fq(
        from_u256(9997443779015206626452921708994799579253015848032484174058762432410849598559)
    );
    (A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2, eval_zw)
}

pub fn public_inputs() -> Array<u384> {
    array![
        from_u256(18830187580832391953292633656724590808884826987965006042179076864562655717112),
        from_u256(3142850441180811825929099504508009930706757625639242073235848449635957522737),
        from_u256(1390849295786071768276380950238675083608645509734),
        from_u256(642829559307850963015472508762062935916233390536),
        from_u256(0)
    ]
}
// verification_key

pub fn verification_key() -> (
    u256,
    u256,
    u384,
    u384,
    u256,
    u256,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG1,
    AffineG2,
    u384
) {
    let n = 4096;
    let power = 12;
    let k1 = u384 { limb0: 2, limb1: 0, limb2: 0, limb3: 0 };
    let k2 = u384 { limb0: 3, limb1: 0, limb2: 0, limb3: 0 };

    let nPublic: u256 = 5;
    let nLagrange: u256 = 5;

    // selector polynomials
    let mut Qm = g1(
        11240482550383658688279521830679253871322560915360199636916520528135605482444,
        3431122764236897545617224694179094663789418620279588141187823308980051568523
    );
    let mut Ql = g1(
        19520750151267480379403043633816096744187706921431743101456667401780936673048,
        2904046169698301367666378414613480674999945406696556734725765383213671080350
    );
    let mut Qr = g1(
        5361193342619395087772132966137528554334571919393439342516983798992339846953,
        10621881966959679780791508865914482336415559306143030367209878920501383639883
    );
    let mut Qo = g1(
        19736095359050112872741097174535800702036232155053734659598153018982327851919,
        9875023053467384224267823499571286781146309118843035684902387371421534071923
    );
    let mut Qc = g1(
        4168551058994119169098599756126849341890494780709237376665473361288000628985,
        16318122550996159765231944745563350163224658415565022435373632000800032685915
    );

    // permutation polynomials
    let mut S1 = g1(
        19470080834542947757713990185384842568927167697587581102802424986481100757727,
        9463077273605123182680585591052993934200194532393159841270184988908955846072
    );
    let mut S2 = g1(
        16816859138521257634566357998076491135190740882013031315753941298090146677616,
        9082632736126755326333353351746099363611335761325714850511274468208520863106
    );
    let mut S3 = g1(
        12367430526798682210810421015155635850495584234395224982416917765827629877906,
        6135953264122108771254717049243374646557646249824573987481865482904018160665
    );

    let mut X_2 = g2(
        2046742093474138364318819827031777645206433195128565824360788617741298981525,
        1433753357665853869090569273359618677040253248059110079322274768858965861594,
        1012593656704398130331921245405877456331931988986547477234119259528482165497,
        4191056764018303486822079644163839762717699764181526746691927713416713155706
    );
    let w = from_u256(4158865282786404163413953114870269622875596290766033564087307867933865333818);
    (n, power, k1, k2, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w)
}
