use core::{
    fmt::{Display, Formatter, Error},
    integer::{u128, u256, u512},
    internal::bounded_int::BoundedInt,
    traits::{Into, TryInto},
    circuit::{
        CircuitElement, CircuitInput, CircuitModulus, CircuitInputs, u384,
        circuit_add, circuit_sub, circuit_inverse, circuit_mul,
        EvalCircuitTrait, CircuitOutputsTrait, AddInputResultTrait,
        conversions::{from_u128, from_u256},
    },
};
use plonk_verifier::{
    curve::{
        FIELD, get_field_nz, add, sub_field, mul, scl, sqr, div, neg, inv,
        add_u, sub_u, mul_u, sqr_u, scl_u, u512_reduce, u512_add_u256, u512_sub_u256,
        constants::FIELD_U384,
    },
    fields::{
        fq, Fq, fq2, Fq2,
        fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq},
        print::{FqPrintImpl, Fq2PrintImpl},
    },
    traits::{
        FieldUtils, FieldOps as FOps, FieldShortcuts as FShort, FieldMulShortcuts,
    },
};
use debug::PrintTrait as Print;



type AffineG1 = Affine<Fq>;
type AffineG2 = Affine<Fq2>;

#[derive(Copy, Drop, Serde)]
struct Affine<T> {
    x: T,
    y: T
}

trait ECGroup<TCoord> {
    fn one() -> Affine<TCoord>;
}

//======================================================



//======================================================
trait ECOperations<TCoord> {
    fn x_on_slope(self: @Affine<TCoord>, slope: TCoord, x2: TCoord) -> TCoord;
    fn y_on_slope(self: @Affine<TCoord>, slope: TCoord, x: TCoord) -> TCoord;
    fn pt_on_slope(self: @Affine<TCoord>, slope: TCoord, x2: TCoord) -> Affine<TCoord>;
    fn chord(self: @Affine<TCoord>, rhs: Affine<TCoord>) -> TCoord;
    fn add(self: @Affine<TCoord>, rhs: Affine<TCoord>) -> Affine<TCoord>;
    fn tangent(self: @Affine<TCoord>) -> TCoord;
    fn double(self: @Affine<TCoord>) -> Affine<TCoord>;
    fn multiply(self: @Affine<TCoord>, multiplier: u256) -> Affine<TCoord>;
    fn neg(self: @Affine<TCoord>) -> Affine<TCoord>;
}

impl AffinePartialEq<T, +PartialEq<T>> of PartialEq<Affine<T>> {
    fn eq(lhs: @Affine<T>, rhs: @Affine<T>) -> bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
    fn ne(lhs: @Affine<T>, rhs: @Affine<T>) -> bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}

impl AffineOps<
    T, +FOps<T>, +FShort<T>, +Copy<T>, +Print<T>, +Drop<T>, impl ECGImpl: ECGroup<T>
> of ECOperations<T> {
    #[inline(always)]
    fn x_on_slope(self: @Affine<T>, slope: T, x2: T) -> T {
        // x = λ^2 - x1 - x2
        //slope.sqr() - *self.x - x2

    let slope_element    = CircuitElement::<CircuitInput<0>>{};
    let x_affine_element = CircuitElement::<CircuitInput<1>>{};
    let x2_element       = CircuitElement::<CircuitInput<2>>{};

    // Step 2: Construct the Circuit
    let slope_squared = circuit_mul(slope_element, slope_element);
    let sub_1 = circuit_sub(slope_squared, x_affine_element);
    let result = circuit_sub(sub_1, x2_element);

    // Step 3: Set the Modulus
    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    // Step 4: Here neew to combert from T to 384
    let slope_u384    = 0;
    let x_affine_u384 = 0;
    let x2_u384       = 0;

    // Step 5: Evaluate the Circuit
    let outputs = match (result,)
        .new_inputs()
        .next(slope_u384)
        .next(x_affine_u384)
        .next(x2_u384)
        .done()
        .eval(modulus)
    {
        Result::Ok(outputs) => outputs,
        Result::Err(_) => panic!("ERROR in circuit evaluation"),
    };

    // Step 6: Here I recover the result of the circuit in u384 but need return T
    let x_result: T = outputs.get_output(result).try_into().unwrap();
    x_result

    }

    

    #[inline(always)]
    fn y_on_slope(self: @Affine<T>, slope: T, x: T) -> T {
        // y = λ(x1 - x) - y1
        //slope * (*self.x - x) - *self.y

        let slope_el  = CircuitElement::<CircuitInput<0>>{};
        let x_Affine  = CircuitElement::<CircuitInput<1>>{};
        let y_Affine  = CircuitElement::<CircuitInput<2>>{};
        let x_element = CircuitElement::<CircuitInput<3>>{};
        
        let sub_1  = circuit_sub(x_Affine,x_element);
        let temp_1 = circuit_mul(slope_el,sub_1);
        let result  = circuit_sub(temp_1,y_Affine);

        // Step 3: Set the Modulus
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        // Here need to be comberted the data type from T to 384
        let slope_u384    = slope;
        let x_affine_u384 = self.x;
        let y_affine_u384 = self.y;
        let x2_u384       = x;

        let outputs = match (result,)
        .new_inputs()
        .next(x_affine_u384)
        .next(x2_u384)
        .next(slope_u384)
        .next(y_affine_u384)
        .done()
        .eval(modulus)
    {
        Result::Ok(outputs) => outputs,
        Result::Err(_) => panic!("ERROR in circuit evaluation"),
    };

    // Step 6: Here I recover the result of the circuit in u384 but need return T
    let y_result: T = outputs.get_output(result).try_into().unwrap();
    y_result


    }

    // #[inline(always)]
    fn pt_on_slope(self: @Affine<T>, slope: T, x2: T) -> Affine<T> {
        let x = self.x_on_slope(slope, x2);
        let y = self.y_on_slope(slope, x);
        Affine { x, y }
    }

    #[inline(always)]
    fn chord(self: @Affine<T>, rhs: Affine<T>) -> T {
        //let Affine { x: x1, y: y1 } = *self;
        //let Affine { x: x2, y: y2 } = rhs;
        // λ = (y2-y1) / (x2-x1)
        //(y2 - y1) / (x2 - x1)

         // Step 1: Define Circuit Elements
        let x_self_element = CircuitElement::<CircuitInput<0>>{};
        let y_self_element = CircuitElement::<CircuitInput<1>>{};
        let x_rhs_element = CircuitElement::<CircuitInput<2>>{};
        let y_rhs_element = CircuitElement::<CircuitInput<3>>{};

        // Step 2: Construct the Circuit
        let y_diff = circuit_sub(y_rhs_element, y_self_element);
        let x_diff = circuit_sub(x_rhs_element, x_self_element);
        let x_diff_inv = circuit_inverse(x_diff);
        let lambda = circuit_mul(y_diff, x_diff_inv);

        // Step 3: Set the Modulus
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        // Step 4: Convert Inputs to u384
        let x_self_u384 = from_u256(self.x.to_u256());
        let y_self_u384 = from_u256(self.y.to_u256());
        let x_rhs_u384 = from_u256(rhs.x.to_u256());
        let y_rhs_u384 = from_u256(rhs.y.to_u256());

        // Step 5: Evaluate the Circuit
        let outputs = match (lambda,)
            .new_inputs()
            .next(x_self_u384)
            .next(y_self_u384)
            .next(x_rhs_u384)
            .next(y_rhs_u384)
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("ERROR in circuit evaluation"),
        };

        // Step 6: Retrieve and Return the Output
        let lambda_result: T = outputs.get_output(lambda).try_into().unwrap();
        lambda_result

    }

    // #[inline(always)]
    fn add(self: @Affine<T>, rhs: Affine<T>) -> Affine<T> {
        self.pt_on_slope(self.chord(rhs), rhs.x)
    }

    // #[inline(always)]
    fn tangent(self: @Affine<T>) -> T {
        //let Affine { x, y } = *self;
        // λ = (3x^2 + a) / 2y
        // But BN curve has a == 0 so that's one less addition
        // λ = 3x^2 / 2y
        //let x_2 = x.sqr();
        //(x_2 + x_2 + x_2) / y.u_add(y)

        let x_element = CircuitElement::<CircuitInput<0>>{};
        let y_element = CircuitElement::<CircuitInput<1>>{};

        // Step 2: Construct the Circuit
        let x_squared = circuit_mul(x_element, x_element);
        let x_doubled = circuit_add(x_element, x_element);
        let numerator = circuit_add(x_squared, x_doubled);
        let y_doubled = circuit_add(y_element, y_element);
        let denominator_inv = circuit_inverse(y_doubled);
        let lambda = circuit_mul(numerator, denominator_inv);

        // Step 3: Set the Modulus
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        // Step 4: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        let x_u384 = from_u256(self.x.to_u256());
        let y_u384 = from_u256(self.y.to_u256());

        // Step 5: Evaluate the Circuit
        let outputs = match (lambda,)
            .new_inputs()
            .next(x_u384)
            .next(y_u384)
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Error evaluating tangent slope circuit"),
        };

        // Step 6: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        let lambda_result: T = outputs.get_output(lambda).try_into().unwrap();
        lambda_result

    }

    // #[inline(always)]
    fn double(self: @Affine<T>) -> Affine<T> {
        self.pt_on_slope(self.tangent(), *self.x)
    }

    fn multiply(self: @Affine<T>, mut multiplier: u256) -> Affine<T> {
        let nz2: NonZero<u256> = 2_u256.try_into().unwrap();
        let mut dbl_step = *self;
        let mut result = ECGImpl::one();
        let mut first_add_done = false;

        // TODO: optimise with u128 ops
        // Replace u256 multiplier loop with 2x u128 loops
        loop {
            let (q, r, _) = integer::u256_safe_divmod(multiplier, nz2);

            if r == 1 {
                result =
                    if !first_add_done {
                        first_add_done = true;
                        // self is zero, return rhs
                        dbl_step
                    } else {
                        result.add(dbl_step)
                    }
            }

            if q == 0 {
                break;
            }
            dbl_step = dbl_step.double();
            multiplier = q;
        };
        result
    }

    #[inline(always)]
    fn neg(self: @Affine<T>) -> Affine<T> {
        Affine { x: *self.x, y: (*self.y).neg() }
    }
}

#[inline(always)]
fn g1(x: u256, y: u256) -> Affine<Fq> {
    Affine { x: fq(x), y: fq(y) }
}

#[inline(always)]
fn g2(x1: u256, x2: u256, y1: u256, y2: u256) -> Affine<Fq2> {
    Affine { x: fq2(x1, x2), y: fq2(y1, y2) }
}

impl AffineG1Impl of ECGroup<Fq> {
    #[inline(always)]
    fn one() -> Affine<Fq> {
        g1(1, 2)
    }
}

impl AffineG2Impl of ECGroup<Fq2> {
    #[inline(always)]
    fn one() -> AffineG2 {
        g2(
            10857046999023057135944570762232829481370756359578518086990519993285655852781,
            11559732032986387107991004021392285783925812861821192530917403151452391805634,
            8495653923123431417604973247489272438418190587263600148770280649306958101930,
            4082367875863433681332203403145435568316851327593401208105741076214120093531
        )
    }
}
