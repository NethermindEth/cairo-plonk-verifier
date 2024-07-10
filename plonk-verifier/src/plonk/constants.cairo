use core::array::ArrayTrait;
use core::fmt::{Display, Formatter, Error};
use plonk_verifier::fields::{fq, fq2, fq12, fq6, Fq, Fq12, Fq6};
use plonk_verifier::curve::groups::{g1, g2, AffineG1, AffineG2};
// proof
#[cairofmt::skip]
fn proof() -> (AffineG1, AffineG1, AffineG1, AffineG1, AffineG1, AffineG1, AffineG1, AffineG1, AffineG1, Fq, Fq, Fq, Fq, Fq, Fq) { 
    let A = g1(
        4693417943536520268746058560989260808135478372449023987176805259899316401080,
        8186764010206899711756657704517859444555824539207093839904632766037261603989
    );
    let B = g1(
        21232572615312016219095998604516214105582153097645445226211380371890243117225,
        18225042204903980255728735992984175898507928948420331879174001082476558612870
    );
    let C = g1(
        20573819936899745995487032740255878539447252296879649378030240347304284105099,
        17224014747839541284343114142197466503584903893727299093320495587333259654038
    );
    let Z = g1(
        4341941154197671108078160656059118705209458710869819707217879123116133630669,
        16073660851802128682970774587331799715982441265731195218321327525270604194124
    );
    let T1 = g1(
        7926905109444664893422103419480175727819513498547385534029465432545015310132,
        10513159929545667138442819220050833870985877374305711267071751294775197932015
    );
    let T2 = g1(
        17928046690558061872572049674505305173637221577630431815976556195718708384395,
        14432316551762148216994550490542363948642605099568736784736433358009449947585
    );
    let T3 = g1(
        18208202618419394434478755850576914501451528190510066853301760688741607332442,
        12280407943225401319265404528256628206124104061703345619582419767996396265698
    );
    let Wxi = g1(
        2029901107882208863351828750543251619224999993610614485188198275715563322522,
        17276897646043284157577563970816740958958814332008206516210486896170503826442
    );
    let Wxiw = g1(
        16577720179487333217918945335378885787823307200569318659335648820637704044530,
        6595768204203169773770662387880315200772987572817173880685075063294956368165
    );
    let eval_a = fq(12414878641105079363695639132995965092423960984837736008191365473346709965275);
    let eval_b = fq(19739046478844971989337832098705270030352467091634038664369165215653027469500);
    let eval_c = fq(15253880047088558478970017789114306499811076046680327031634696430090595867452);
    let eval_s1 = fq(12335570008584925992572913156034617452826613521385468615090304614804130616195);
    let eval_s2 = fq(21681562496924100584010248593736757866646800218726643699422842635715426828949);
    let eval_zw = fq(15186282915139912604826047127152403305203700954911731020352856365666878273585);
    (
        A, B, C, Z, T1, T2, T3, Wxi, Wxiw, eval_a, eval_b, eval_c, eval_s1, eval_s2, eval_zw
    )
}

// verification_key
fn vk() -> (
    u256,
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
    u256
) {
    let n = 4096;
    let _power = 12;
    let _k1 = 2;
    let _k2 = 3;

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
    let w = 4158865282786404163413953114870269622875596290766033564087307867933865333818;
    (n, nPublic, nLagrange, Qm, Ql, Qr, Qo, Qc, S1, S2, S3, X_2, w)
}
// verification_key.json
// {
//     "protocol": "plonk",
//     "curve": "bn128",
//     "nPublic": 5,
//     "power": 12,
//     "k1": "2",
//     "k2": "3",
//     "Qm": [
//      "11240482550383658688279521830679253871322560915360199636916520528135605482444",
//      "3431122764236897545617224694179094663789418620279588141187823308980051568523",
//      "1"
//     ],
//     "Ql": [
//      "19520750151267480379403043633816096744187706921431743101456667401780936673048",
//      "2904046169698301367666378414613480674999945406696556734725765383213671080350",
//      "1"
//     ],
//     "Qr": [
//      "5361193342619395087772132966137528554334571919393439342516983798992339846953",
//      "10621881966959679780791508865914482336415559306143030367209878920501383639883",
//      "1"
//     ],
//     "Qo": [
//      "19736095359050112872741097174535800702036232155053734659598153018982327851919",
//      "9875023053467384224267823499571286781146309118843035684902387371421534071923",
//      "1"
//     ],
//     "Qc": [
//      "4168551058994119169098599756126849341890494780709237376665473361288000628985",
//      "16318122550996159765231944745563350163224658415565022435373632000800032685915",
//      "1"
//     ],
//     "S1": [
//      "19470080834542947757713990185384842568927167697587581102802424986481100757727",
//      "9463077273605123182680585591052993934200194532393159841270184988908955846072",
//      "1"
//     ],
//     "S2": [
//      "16816859138521257634566357998076491135190740882013031315753941298090146677616",
//      "9082632736126755326333353351746099363611335761325714850511274468208520863106",
//      "1"
//     ],
//     "S3": [
//      "12367430526798682210810421015155635850495584234395224982416917765827629877906",
//      "6135953264122108771254717049243374646557646249824573987481865482904018160665",
//      "1"
//     ],
//     "X_2": [
//      [
//       "2046742093474138364318819827031777645206433195128565824360788617741298981525",
//       "1433753357665853869090569273359618677040253248059110079322274768858965861594"
//      ],
//      [
//       "1012593656704398130331921245405877456331931988986547477234119259528482165497",
//       "4191056764018303486822079644163839762717699764181526746691927713416713155706"
//      ],
//      [
//       "1",
//       "0"
//      ]
//     ],
//     "w": "4158865282786404163413953114870269622875596290766033564087307867933865333818"
//    }


