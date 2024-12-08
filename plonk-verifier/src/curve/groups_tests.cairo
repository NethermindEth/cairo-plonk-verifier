use plonk_verifier::curve::groups::{
    ECOperations,
    ECOperationsCircuitFq2,
    ECOperationsCircuitFq6
    };
use plonk_verifier::fields::fq;
use plonk_verifier::curve::groups::{
    Affine, AffineOps,
    AffineG1, AffineG1Impl, g1,
    AffineG2, AffineG2Impl, g2,
    AffineG6, AffineG6Impl, g6
};
use debug::PrintTrait;

const DBL_X: u256 = 1368015179489954701390400359078579693043519447331113978918064868415326638035;
const DBL_Y: u256 = 9918110051302171585080402603319702774565515993150576347155970296011118125764;

const TPL_X: u256 = 3353031288059533942658390886683067124040920775575537747144343083137631628272;
const TPL_Y: u256 = 19321533766552368860946552437480515441416830039777911637913418824951667761761;

#[cfg(test)]
fn g1_dbl() {
    let doubled  = AffineG1Impl::one().double();
    assert(doubled.x.c0 == DBL_X, 'wrong double x');
    assert(doubled.y.c0 == DBL_Y, 'wrong double y');
}

#[cfg(test)]
fn g1_add() {
    let g_3x = AffineG1Impl::one().add(g1(DBL_X, DBL_Y));

    assert(g_3x.x.c0 == TPL_X, 'wrong add x');
    assert(g_3x.y.c0 == TPL_Y, 'wrong add y');
}

#[cfg(test)]
fn g1_mul() {
    let pt = g1(
        0x17c139df0efee0f766bc0204762b774362e4ded88953a39ce849a8a7fa163fa9,
        0x1e0559bacb160664764a357af8a9fe70baa9258e0b959273ffc5718c6d4cc7c
    );

    let ptx125 = pt.multiply(0x1e424966e10667c3d185512e7409ca7a);
    assert(
        ptx125 == g1(
            7752846241341734434024187269145433576429990719025134712626574884614125378714,
            19213841682166110169098922493057250403196082236710892128510232260429666209717
        ),
        'wrong mul 125 bit'
    );

    let ptx250 = pt.multiply(0x2150ec3e42dd5b118e4bd9c40a05b7adf1fa64af817e7c3d185512e7409ca7a);
    assert(
        ptx250 == g1(
            8453943020253287278117062548565477428817612735773430345154413404924876875605,
            16097656260318801850592723545014363253891988068036964887917237907198917754434
        ),
        'wrong mul 250 bit'
    );
}


const DBL_X_0: u256 = 18029695676650738226693292988307914797657423701064905010927197838374790804409;
const DBL_X_1: u256 = 14583779054894525174450323658765874724019480979794335525732096752006891875705;
const DBL_Y_0: u256 = 2140229616977736810657479771656733941598412651537078903776637920509952744750;
const DBL_Y_1: u256 = 11474861747383700316476719153975578001603231366361248090558603872215261634898;

const TPL_X_0: u256 = 2725019753478801796453339367788033689375851816420509565303521482350756874229;
const TPL_X_1: u256 = 7273165102799931111715871471550377909735733521218303035754523677688038059653;
const TPL_Y_0: u256 = 2512659008974376214222774206987427162027254181373325676825515531566330959255;
const TPL_Y_1: u256 = 957874124722006818841961785324909313781880061366718538693995380805373202866;

fn assert_g2_match(self: AffineG2, x0: u256, x1: u256, y0: u256, y1: u256, msg: felt252) {
    assert((self.x.c0.c0, self.x.c1.c0, self.y.c0.c0, self.y.c1.c0,) == (x0, x1, y0, y1,), msg);
}

#[cfg(test)]
fn g2_dbl() {
    let doubled = AffineG2Impl::one().double();
    assert_g2_match(doubled, DBL_X_0, DBL_X_1, DBL_Y_0, DBL_Y_1, 'wrong double');
}

#[cfg(test)]
fn g2_add() {
    let g_3x = AffineG2Impl::one().add(g2(DBL_X_0, DBL_X_1, DBL_Y_0, DBL_Y_1,));
    assert_g2_match(g_3x, TPL_X_0, TPL_X_1, TPL_Y_0, TPL_Y_1, 'wrong add operation');
}

#[cfg(test)]
fn g2_mul() {
    let g_3x = AffineG2Impl::one().multiply(3);
    assert_g2_match(g_3x, TPL_X_0, TPL_X_1, TPL_Y_0, TPL_Y_1, 'wrong multiply');
}

/////////////////////////////////////////////////////////////
/// Fq6 with circuit
////////////////////////////////////////////////////////////

const INIT_X_C0_0: u256 = 20484134632227413105288852818573307096537828350605883914293261499202706558932;
const INIT_X_C0_1: u256 = 283027205451805829911283416334749444152166604350404893963662054653109752570;
const INIT_X_C1_0: u256 = 4872883918153764825330855961068725807551808808739107813150077196882906638099;
const INIT_X_C1_1: u256 = 8274794029246137792464104733459993037041262152389379057883240989711411681544;
const INIT_X_C2_0: u256 = 11410622344362579270341021334220993326208891893123481318972114230329275021689;
const INIT_X_C2_1: u256 = 10370876545384681187779998897369692590180150910970520885980650649565193430448;

const INIT_Y_C0_0: u256 = 21888242871839275222246405745257275088696311157297823662689037894645226208582;
const INIT_Y_C0_1: u256 = 0;
const INIT_Y_C1_0: u256 = 0;
const INIT_Y_C1_1: u256 = 0;
const INIT_Y_C2_0: u256 = 0;
const INIT_Y_C2_1: u256 = 0;


const INIT2_X_C0_0: u256 = 6332630470069007818510410782711727428171086725301393848166167962318143698476;
const INIT2_X_C0_1: u256 = 21122961909958299544456203858674009958311208418362239338094445142237396147255;
const INIT2_X_C1_0: u256 = 8692152477966235408165675855509521949699839283589879884614965015832111741961;
const INIT2_X_C1_1: u256 = 3376125027674839115102766051486897822318641200585443824118985307324136852655;
const INIT2_X_C2_0: u256 = 13271672509281395900621201224912043504467382985910919724262711257466623229598;
const INIT2_X_C2_1: u256 = 16423729737344100214055990811066351451964461357546777880451630277184403077966;

const INIT2_Y_C0_0: u256 = 1;
const INIT2_Y_C0_1: u256 = 0;
const INIT2_Y_C1_0: u256 = 0;
const INIT2_Y_C1_1: u256 = 0;
const INIT2_Y_C2_0: u256 = 0;
const INIT2_Y_C2_1: u256 = 0;



/// Helper function to assert `Fq6` components match
fn assert_g6_match(
    self: AffineG6, 
    xc0_0: u256, xc0_1: u256, xc1_0: u256, xc1_1: u256, xc2_0: u256, xc2_1: u256,
    yc0_0: u256, yc0_1: u256, yc1_0: u256, yc1_1: u256, yc2_0: u256, yc2_1: u256,
    msg: felt252
) {
    assert(
        (
            self.x.c0.c0, self.x.c0.c1, 
            self.x.c1.c0, self.x.c1.c1, 
            self.x.c2.c0, self.x.c2.c1, 
            self.y.c0.c0, self.y.c0.c1, 
            self.y.c1.c0, self.y.c1.c1, 
            self.y.c2.c0, self.y.c2.c1,
        ) == (
            xc0_0, xc0_1, xc1_0, xc1_1, xc2_0, xc2_1, 
            yc0_0, yc0_1, yc1_0, yc1_1, yc2_0, yc2_1,
        ),
        msg
    );
}



/// Test doubling operation for Fq6
#[cfg(test)]
fn g6_dbl() {
    let doubled = AffineG6Impl::one().double();
    assert_g6_match(
        doubled,
        DBL_X_C0_0, DBL_X_C0_1, DBL_X_C1_0, DBL_X_C1_1, DBL_X_C2_0, DBL_X_C2_1,
        DBL_Y_C0_0, DBL_Y_C0_1, DBL_Y_C1_0, DBL_Y_C1_1, DBL_Y_C2_0, DBL_Y_C2_1,
        'wrong double operation for Fq6'
    );
}

/// Test addition operation for Fq6
#[cfg(test)]
fn g6_add() {
    let g_3x = AffineG6Impl::one().add_as_circuit(g6(
        DBL_X_C0_0, DBL_X_C0_1, DBL_X_C1_0, DBL_X_C1_1, DBL_X_C2_0, DBL_X_C2_1,
        DBL_Y_C0_0, DBL_Y_C0_1, DBL_Y_C1_0, DBL_Y_C1_1, DBL_Y_C2_0, DBL_Y_C2_1
    ));
    assert_g6_match(
        g_3x,
        TPL_X_C0_0, TPL_X_C0_1, TPL_X_C1_0, TPL_X_C1_1, TPL_X_C2_0, TPL_X_C2_1,
        TPL_Y_C0_0, TPL_Y_C0_1, TPL_Y_C1_0, TPL_Y_C1_1, TPL_Y_C2_0, TPL_Y_C2_1,
        'wrong add operation for Fq6'
    );
}

/// Test multiplication operation for Fq6
#[cfg(test)]
fn g6_mul() {
    // Scalar values for testing
    const MUL_SCALAR_2: u256 = 2; // Double
    const MUL_SCALAR_3: u256 = 3; // Triple

    // Initialize the base point
    let point = AffineG6Impl::one();

    // Test double multiplication
    let doubled = point.multiply_as_circuit(MUL_SCALAR_2);
    assert_g6_match(
        doubled,
        DBL_X_C0_0, DBL_X_C0_1, DBL_X_C1_0, DBL_X_C1_1, DBL_X_C2_0, DBL_X_C2_1,
        DBL_Y_C0_0, DBL_Y_C0_1, DBL_Y_C1_0, DBL_Y_C1_1, DBL_Y_C2_0, DBL_Y_C2_1,
        "wrong double operation for Fq6"
    );

    // Test triple multiplication
    let tripled = point.multiply_as_circuit(MUL_SCALAR_3);
    assert_g6_match(
        tripled,
        TPL_X_C0_0, TPL_X_C0_1, TPL_X_C1_0, TPL_X_C1_1, TPL_X_C2_0, TPL_X_C2_1,
        TPL_Y_C0_0, TPL_Y_C0_1, TPL_Y_C1_0, TPL_Y_C1_1, TPL_Y_C2_0, TPL_Y_C2_1,
        "wrong triple operation for Fq6"
    );
}

/////////////////////////////////////////////////////////////
/// Fq2 with circuit
////////////////////////////////////////////////////////////

fn assert_g2_match(self: AffineG2, x0: u256, x1: u256, y0: u256, y1: u256, msg: felt252) {
    assert((self.x.c0.c0, self.x.c1.c0, self.y.c0.c0, self.y.c1.c0,) == (x0, x1, y0, y1,), msg);
}

#[cfg(test)]
fn g2_dbl() {
    let doubled = AffineG2Impl::one().double_as_circuit();
    assert_g2_match(doubled, DBL_X_0, DBL_X_1, DBL_Y_0, DBL_Y_1, 'wrong Fq2 circuit double');
}

#[cfg(test)]
fn g2_add() {
    let g_3x = AffineG2Impl::one().add_as_circuit(g2(DBL_X_0, DBL_X_1, DBL_Y_0, DBL_Y_1,));
    assert_g2_match(g_3x, TPL_X_0, TPL_X_1, TPL_Y_0, TPL_Y_1, 'wrong Fq2 circuit add');
}

#[cfg(test)]
fn g2_mul() {
    let g_3x = AffineG2Impl::one().multiply_as_circuit(3);
    assert_g2_match(g_3x, TPL_X_0, TPL_X_1, TPL_Y_0, TPL_Y_1, 'wrong Fq2 circuit multiply');
}
