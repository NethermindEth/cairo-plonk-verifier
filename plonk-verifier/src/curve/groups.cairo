use core::circuit::{
    AddInputResultTrait, AddMod, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
    CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, MulMod, RangeCheck96, u96, u384,
    circuit_add, circuit_inverse, circuit_mul, circuit_sub, U384Serde
};
use core::circuit::conversions::from_u256;
use core::circuit::{
    AddModGate as A, CircuitElement as CE, CircuitInput as CI, InverseGate as I, MulModGate as M,
    SubModGate as S,
};

use plonk_verifier::circuits::affine_circuits::{
    fq2_add_circuit, fq2_chord_circuit, fq2_double_circuit, fq2_pt_on_slope_circuit,
    fq2_tangent_circuit, fq2_y_on_slope_circuit,
};
use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::fields::{fq, fq2, Fq, Fq2};
use plonk_verifier::traits::{FieldOps as FOps};

type AffineG1 = Affine<Fq>;
type AffineG2 = Affine<Fq2>;

// #[inline(always)]
fn affine_fq1(c0: u384, c1: u384) -> Affine<Fq> {
    Affine { x: fq(c0), y: fq(c1) }
}

// #[inline(always)]
fn affine_fq2(c0: u384, c1: u384, c2: u384, c3: u384) -> Affine<Fq2> {
    Affine { x: fq2(c0, c1), y: fq2(c2, c3) }
}

#[derive(Copy, Drop, Serde)]
struct Affine<T> {
    x: T,
    y: T
}

trait ECGroup<TCoord> {
    fn one() -> Affine<TCoord>;
}

trait ECOperationsCircuitFq {
    // fn x_on_slope(self: @Affine<Fq>, slope: Fq, x2: Fq) -> Fq;
    // fn y_on_slope(self: @Affine<Fq>, slope: Fq, x: Fq) -> Fq;
    fn pt_on_slope(self: @Affine<Fq>, slope: Fq, x2: Fq, m: CircuitModulus) -> Affine<Fq>;
    fn chord(self: @Affine<Fq>, rhs: Affine<Fq>, m: CircuitModulus) -> Fq;
    fn add_as_circuit(self: @Affine<Fq>, rhs: Affine<Fq>, m: CircuitModulus) -> Affine<Fq>;
    // fn tangent(self: @Affine<Fq>) -> Fq;
    fn double_as_circuit(self: @Affine<Fq>, m: CircuitModulus) -> Affine<Fq>;
    fn multiply_as_circuit(self: @Affine<Fq>, multiplier: u384, m: CircuitModulus) -> Affine<Fq>;
    fn neg(self: @Affine<Fq>, m: CircuitModulus) -> Affine<Fq>;
}

trait ECOperationsCircuitFq2 {
    fn x_on_slope(self: @Affine<Fq2>, slope: Fq2, x2: Fq2, m: CircuitModulus) -> Fq2;
    fn y_on_slope_as_circuit(self: @Affine<Fq2>, slope: Fq2, x: Fq2, m: CircuitModulus) -> Fq2;
    fn pt_on_slope_as_circuit(
        self: @Affine<Fq2>, slope: Fq2, x2: Fq2, m: CircuitModulus
    ) -> Affine<Fq2>;
    fn chord_as_circuit(self: @Affine<Fq2>, rhs: Affine<Fq2>, m: CircuitModulus) -> Fq2;
    fn add_as_circuit(self: @Affine<Fq2>, rhs: Affine<Fq2>, m: CircuitModulus) -> Affine<Fq2>;
    fn tangent_as_circuit(self: @Affine<Fq2>, m: CircuitModulus) -> Fq2;
    fn double_as_circuit(self: @Affine<Fq2>, m: CircuitModulus) -> Affine<Fq2>;
    // fn multiply_as_circuit(self: @Affine<Fq2>, multiplier: u384) -> Affine<Fq2>;
    fn neg(self: @Affine<Fq2>, m: CircuitModulus) -> Affine<Fq2>;
}

impl AffinePartialEq<T, +PartialEq<T>> of PartialEq<Affine<T>> {
    fn eq(lhs: @Affine<T>, rhs: @Affine<T>) -> bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
    fn ne(lhs: @Affine<T>, rhs: @Affine<T>) -> bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}

// Use only the highest level circuit when implementing (less steps)
impl AffineOpsFqCircuit of ECOperationsCircuitFq {
    fn double_as_circuit(self: @Affine<Fq>, m: CircuitModulus) -> Affine<Fq> {
        // λ = (3x^2 + a) / 2y
        // But BN curve has a == 0 so that's one less addition
        // λ = 3x^2 / 2y
        // let x_2 = x.sqr();
        // (x_2 + x_2 + x_2) / y.u_add(y)
        let x1 = CircuitElement::<CircuitInput<0>> {};
        let y1 = CircuitElement::<CircuitInput<1>> {};

        let x1_sqr = circuit_mul(x1, x1);
        let x1_add_x1_x1 = circuit_add(x1_sqr, x1_sqr);
        let x1_add_x1_x1_x1 = circuit_add(x1_add_x1_x1, x1_sqr);

        let y1_double = circuit_add(y1, y1);
        let y1_inv = circuit_inverse(y1_double);

        let tangent = circuit_mul(x1_add_x1_x1_x1, y1_inv);

        let lambda_sqr = circuit_mul(tangent, tangent); // slope.sqr()
        let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
        let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x1); // slope.sqr() - *self.x - x2

        let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
        let y_slope_mul_lambda_x1_x = circuit_mul(
            tangent, y_slope_sub_x1_x
        ); // slope * (*self.x - x)
        let y_slope_lambda_sub_lambda_x_y = circuit_sub(
            y_slope_mul_lambda_x1_x, y1
        ); // slope * (*self.x - x) - *self.y

        let x1 = *self.x.c0;
        let y1 = *self.y.c0;

        let outputs =
            match (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y,)
                .new_inputs()
                .next(x1)
                .next(y1)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let x = Fq { c0: outputs.get_output(x_slope_sub_x1_x2) };
        let y = Fq { c0: outputs.get_output(y_slope_lambda_sub_lambda_x_y) };

        Affine { x, y }
    }

    fn add_as_circuit(self: @Affine<Fq>, rhs: Affine<Fq>, m: CircuitModulus) -> Affine<Fq> {
        let x1 = CircuitElement::<CircuitInput<0>> {};
        let y1 = CircuitElement::<CircuitInput<1>> {};
        let x2 = CircuitElement::<CircuitInput<2>> {};
        let y2 = CircuitElement::<CircuitInput<3>> {};

        let y2_y1 = circuit_sub(y2, y1);
        let x2_x1 = circuit_sub(x2, x1);
        let x2_x1_inv = circuit_inverse(x2_x1);
        let lambda = circuit_mul(y2_y1, x2_x1_inv);

        let lambda_sqr = circuit_mul(lambda, lambda); // slope.sqr()
        let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
        let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x2); // slope.sqr() - *self.x - x2

        let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
        let y_slope_mul_lambda_x1_x = circuit_mul(
            lambda, y_slope_sub_x1_x
        ); // slope * (*self.x - x)
        let y_slope_lambda_sub_lambda_x_y = circuit_sub(
            y_slope_mul_lambda_x1_x, y1
        ); // slope * (*self.x - x) - *self.y

        let x1 = *self.x.c0;
        let y1 = *self.y.c0;
        let x2 = rhs.x.c0;
        let y2 = rhs.y.c0;

        let outputs =
            match (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y,)
                .new_inputs()
                .next(x1)
                .next(y1)
                .next(x2)
                .next(y2)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let x = Fq { c0: outputs.get_output(x_slope_sub_x1_x2) };
        let y = Fq { c0: outputs.get_output(y_slope_lambda_sub_lambda_x_y) };

        Affine { x, y }
    }

    fn multiply_as_circuit(
        self: @Affine<Fq>, mut multiplier: u384, m: CircuitModulus
    ) -> Affine<Fq> {
        let nz2: NonZero<u256> = 2_u256.try_into().unwrap();
        let mut dbl_step = *self;
        let mut result = g1(1, 2);
        let mut first_add_done = false;
        let mut multiplier: u256 = multiplier.try_into().unwrap();

        // TODO:: outside loop reduce down to u256-> felt252, then use loop using felt252
        loop {
            let (q, r, _) = integer::u256_safe_divmod(multiplier, nz2);

            if r == 1 {
                result =
                    if !first_add_done {
                        first_add_done = true;
                        // self is zero, return rhs
                        dbl_step
                    } else {
                        result.add_as_circuit(dbl_step, m)
                    }
            }
            if q == 0 {
                break;
            }
            dbl_step = dbl_step.double_as_circuit(m);
            multiplier = q;
        };
        result
    }
    // fn multiply_as_circuit(self: @Affine<Fq>, mut multiplier: u256) -> Affine<Fq> {
    //     let nz2: NonZero<u256> = 2_u256.try_into().unwrap();
    //     let mut dbl_step = *self;
    //     let mut result = g1(1, 2);
    //     let mut first_add_done = false;

    //     // TODO:: outside loop reduce down to u256-> felt252, then use loop using felt252
    //     loop {
    //         let (q, r, _) = integer::u256_safe_divmod(multiplier, nz2);

    //         if r == 1 {
    //             result =
    //                 if !first_add_done {
    //                     first_add_done = true;
    //                     // self is zero, return rhs
    //                     dbl_step
    //                 } else {
    //                     result.add_as_circuit(dbl_step)
    //                 }
    //         }
    //         if q == 0 {
    //             break;
    //         }
    //         dbl_step = dbl_step.double_as_circuit();
    //         multiplier = q;
    //     };
    //     result
    // }
    fn pt_on_slope(self: @Affine<Fq>, slope: Fq, x2: Fq, m: CircuitModulus) -> Affine<Fq> {
        let x_2 = x2;
        // x = λ^2 - x1 - x2
        // slope.sqr() - *self.x - x2
        //let x = self.x_on_slope(slope, x2);
        // y = λ(x1 - x) - y1
        // slope * (*self.x - x) - *self.y
        //let y = self.y_on_slope(slope, x);

        let lambda = CircuitElement::<CircuitInput<0>> {};
        let x1 = CircuitElement::<CircuitInput<1>> {};
        let y1 = CircuitElement::<CircuitInput<2>> {};
        let x2 = CircuitElement::<CircuitInput<3>> {};

        let lambda_sqr = circuit_mul(lambda, lambda); // slope.sqr()
        let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
        let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x2); // slope.sqr() - *self.x - x2

        let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
        let y_slope_mul_lambda_x1_x = circuit_mul(
            lambda, y_slope_sub_x1_x
        ); // slope * (*self.x - x)
        let y_slope_lambda_sub_lambda_x_y = circuit_sub(
            y_slope_mul_lambda_x1_x, y1
        ); // slope * (*self.x - x) - *self.y

        let lambda = slope.c0;
        let x1 = *self.x.c0;
        let y1 = *self.y.c0;
        let x2 = x_2.c0;

        let outputs =
            match (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y,)
                .new_inputs()
                .next(lambda)
                .next(x1)
                .next(y1)
                .next(x2)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let x = Fq { c0: outputs.get_output(x_slope_sub_x1_x2) };
        let y = Fq { c0: outputs.get_output(y_slope_lambda_sub_lambda_x_y) };

        Affine { x, y }
    }

    // #[inline(always)]
    fn chord(self: @Affine<Fq>, rhs: Affine<Fq>, m: CircuitModulus) -> Fq {
        let x1 = CircuitElement::<CircuitInput<0>> {};
        let y1 = CircuitElement::<CircuitInput<1>> {};
        let x2 = CircuitElement::<CircuitInput<2>> {};
        let y2 = CircuitElement::<CircuitInput<3>> {};

        let y2_y1 = circuit_sub(y2, y1);
        let x2_x1 = circuit_sub(x2, x1);
        let x2_x1_inv = circuit_inverse(x2_x1);
        let mul = circuit_mul(y2_y1, x2_x1_inv);

        let x1 = *self.x.c0;
        let y1 = *self.y.c0;
        let x2 = rhs.x.c0;
        let y2 = rhs.y.c0;

        let outputs = match (mul,).new_inputs().next(x1).next(x2).next(y1).next(y2).done().eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        Fq { c0: outputs.get_output(mul) }
    }

    fn neg(self: @Affine<Fq>, m: CircuitModulus) -> Affine<Fq> {
        Affine { x: *self.x, y: FOps::neg(*self.y, m) }
    }
}

impl AffineOpsFq2Circuit of ECOperationsCircuitFq2 {
    fn x_on_slope(self: @Affine<Fq2>, slope: Fq2, x2: Fq2, m: CircuitModulus) -> Fq2 {
        // x = λ^2 - x1 - x2
        slope.sqr(m).sub(*self.x, m).sub(x2, m)
    }

    fn y_on_slope_as_circuit(self: @Affine<Fq2>, slope: Fq2, x: Fq2, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = fq2_y_on_slope_circuit();

        let out =
            match (c0, c1,)
                .new_inputs()
                .next(*self.x.c0.c0)
                .next(*self.x.c1.c0)
                .next(*self.y.c0.c0)
                .next(*self.y.c1.c0)
                .next(slope.c0.c0)
                .next(slope.c1.c0)
                .next(x.c0.c0)
                .next(x.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(out) => { out },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(out.get_output(c0), out.get_output(c1))
    }

    fn pt_on_slope_as_circuit(
        self: @Affine<Fq2>, slope: Fq2, x2: Fq2, m: CircuitModulus
    ) -> Affine<Fq2> {
        let (c0, c1, c2, c3) = fq2_pt_on_slope_circuit();

        let out =
            match (c0, c1, c2, c3)
                .new_inputs()
                .next(*self.x.c0.c0)
                .next(*self.x.c1.c0)
                .next(*self.y.c0.c0)
                .next(*self.y.c1.c0)
                .next(slope.c0.c0)
                .next(slope.c1.c0)
                .next(x2.c0.c0)
                .next(x2.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        affine_fq2(out.get_output(c0), out.get_output(c1), out.get_output(c2), out.get_output(c3))
    }

    fn chord_as_circuit(self: @Affine<Fq2>, rhs: Affine<Fq2>, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = fq2_chord_circuit();

        let out =
            match (c0, c1,)
                .new_inputs()
                .next(*self.x.c0.c0)
                .next(*self.x.c1.c0)
                .next(*self.y.c0.c0)
                .next(*self.y.c1.c0)
                .next(rhs.x.c0.c0)
                .next(rhs.x.c1.c0)
                .next(rhs.y.c0.c0)
                .next(rhs.y.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(out.get_output(c0), out.get_output(c1))
    }

    fn add_as_circuit(self: @Affine<Fq2>, rhs: Affine<Fq2>, m: CircuitModulus) -> Affine<Fq2> {
        let (c0, c1, c2, c3) = fq2_add_circuit();

        let out =
            match (c0, c1, c2, c3)
                .new_inputs()
                .next(*self.x.c0.c0)
                .next(*self.x.c1.c0)
                .next(*self.y.c0.c0)
                .next(*self.y.c1.c0)
                .next(rhs.x.c0.c0)
                .next(rhs.x.c1.c0)
                .next(rhs.y.c0.c0)
                .next(rhs.y.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        affine_fq2(out.get_output(c0), out.get_output(c1), out.get_output(c2), out.get_output(c3))
    }

    fn tangent_as_circuit(self: @Affine<Fq2>, m: CircuitModulus) -> Fq2 {
        let (c0, c1) = fq2_tangent_circuit();

        let out =
            match (c0, c1,)
                .new_inputs()
                .next(*self.x.c0.c0)
                .next(*self.x.c1.c0)
                .next(*self.y.c0.c0)
                .next(*self.y.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        fq2(out.get_output(c0), out.get_output(c1))
    }

    fn double_as_circuit(self: @Affine<Fq2>, m: CircuitModulus) -> Affine<Fq2> {
        let (c0, c1, c2, c3) = fq2_double_circuit();

        let out =
            match (c0, c1, c2, c3)
                .new_inputs()
                .next(*self.x.c0.c0)
                .next(*self.x.c1.c0)
                .next(*self.y.c0.c0)
                .next(*self.y.c1.c0)
                .done()
                .eval(m) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        affine_fq2(out.get_output(c0), out.get_output(c1), out.get_output(c2), out.get_output(c3))
    }

    fn neg(self: @Affine<Fq2>, m: CircuitModulus) -> Affine<Fq2> {
        Affine { x: *self.x, y: FOps::neg(*self.y, m) }
    }
}

// trait ECOperations<TCoord> {
//     fn x_on_slope(self: @Affine<TCoord>, slope: TCoord, x2: TCoord) -> TCoord;
//     fn y_on_slope(self: @Affine<TCoord>, slope: TCoord, x: TCoord) -> TCoord;
//     fn pt_on_slope(self: @Affine<TCoord>, slope: TCoord, x2: TCoord) -> Affine<TCoord>;
//     fn chord(self: @Affine<TCoord>, rhs: Affine<TCoord>) -> TCoord;
//     fn add(self: @Affine<TCoord>, rhs: Affine<TCoord>) -> Affine<TCoord>;
//     fn tangent(self: @Affine<TCoord>) -> TCoord;
//     fn double(self: @Affine<TCoord>) -> Affine<TCoord>;
//     fn multiply(self: @Affine<TCoord>, multiplier: u384) -> Affine<TCoord>;
//     fn neg(self: @Affine<TCoord>) -> Affine<TCoord>;
// }

// impl AffineOps<
//     T, +FOps<T>, +Copy<T>, +Drop<T>, impl ECGImpl: ECGroup<T>
// > of ECOperations<T> {
//     // #[inline(always)]
//     fn x_on_slope(self: @Affine<T>, slope: T, x2: T) -> T {
//         // x = λ^2 - x1 - x2
//         slope.sqr().sub(*self.x).sub(x2)
//     }

//     // #[inline(always)]
//     fn y_on_slope(self: @Affine<T>, slope: T, x: T) -> T {
//         // y = λ(x1 - x) - y1
//         slope * (*self.x - x) - *self.y
//     }

//     // // #[inline(always)]
//     fn pt_on_slope(self: @Affine<T>, slope: T, x2: T) -> Affine<T> {
//         let x = self.x_on_slope(slope, x2);
//         let y = self.y_on_slope(slope, x);
//         Affine { x, y }
//     }

//     // #[inline(always)]
//     fn chord(self: @Affine<T>, rhs: Affine<T>) -> T {
//         let Affine { x: x1, y: y1 } = *self;
//         let Affine { x: x2, y: y2 } = rhs;
//         // λ = (y2-y1) / (x2-x1)
//         (y2 - y1) / (x2 - x1)
//     }

//     // // #[inline(always)]
//     fn add(self: @Affine<T>, rhs: Affine<T>) -> Affine<T> {
//         self.pt_on_slope(self.chord(rhs), rhs.x)
//     }

//     // // #[inline(always)]
//     fn tangent(self: @Affine<T>) -> T {
//         let Affine { x, y } = *self;

//         // λ = (3x^2 + a) / 2y
//         // But BN curve has a == 0 so that's one less addition
//         // λ = 3x^2 / 2y
//         let x_2 = x.sqr();
//         (x_2 + x_2 + x_2) / y.add(y)
//     }

//     // // #[inline(always)]
//     fn double(self: @Affine<T>) -> Affine<T> {
//         self.pt_on_slope(self.tangent(), *self.x)
//     }

//     fn multiply(self: @Affine<T>, mut multiplier: u384) -> Affine<T> {
//         let nz2: NonZero<u256> = 2_u256.try_into().unwrap();
//         let mut dbl_step = *self;
//         let mut result = ECGImpl::one();
//         let mut first_add_done = false;
//         let mut multiplier_256: u256 = multiplier.try_into().unwrap();

//         // TODO: optimise with u128 ops
//         // Replace u256 multiplier loop with 2x u128 loops
//         loop {
//             let (q, r, _) = integer::u256_safe_divmod(multiplier_256, nz2);

//             if r == 1 {
//                 result =
//                     if !first_add_done {
//                         first_add_done = true;
//                         // self is zero, return rhs
//                         dbl_step
//                     } else {
//                         result.add(dbl_step)
//                     }
//             }
//             if q == 0 {
//                 break;
//             }
//             dbl_step = dbl_step.double();
//             multiplier_256 = q;
//         };
//         result
//     }
//     // fn multiply(self: @Affine<T>, mut multiplier: u256) -> Affine<T> {
//     //     let nz2: NonZero<u256> = 2_u256.try_into().unwrap();
//     //     let mut dbl_step = *self;
//     //     let mut result = ECGImpl::one();
//     //     let mut first_add_done = false;

//     //     // TODO: optimise with u128 ops
//     //     // Replace u256 multiplier loop with 2x u128 loops
//     //     loop {
//     //         let (q, r, _) = integer::u256_safe_divmod(multiplier, nz2);

//     //         if r == 1 {
//     //             result =
//     //                 if !first_add_done {
//     //                     first_add_done = true;
//     //                     // self is zero, return rhs
//     //                     dbl_step
//     //                 } else {
//     //                     result.add(dbl_step)
//     //                 }
//     //         }
//     //         if q == 0 {
//     //             break;
//     //         }
//     //         dbl_step = dbl_step.double();
//     //         multiplier = q;
//     //     };
//     //     result
//     // }

//     fn neg(self: @Affine<T>) -> Affine<T> {
//         Affine { x: *self.x, y: (*self.y).neg() }
//     }
// }

// #[inline(always)]
fn g1(x: u256, y: u256) -> Affine<Fq> {
    Affine { x: fq(from_u256(x)), y: fq(from_u256(y)) }
}

// #[inline(always)]
fn g2(x1: u256, x2: u256, y1: u256, y2: u256) -> Affine<Fq2> {
    Affine { x: fq2(from_u256(x1), from_u256(x2)), y: fq2(from_u256(y1), from_u256(y2)) }
}

impl AffineG1Impl of ECGroup<Fq> {
    // #[inline(always)]
    fn one() -> Affine<Fq> {
        g1(1, 2)
    }
}

impl AffineG2Impl of ECGroup<Fq2> {
    // #[inline(always)]
    fn one() -> AffineG2 {
        g2(
            10857046999023057135944570762232829481370756359578518086990519993285655852781,
            11559732032986387107991004021392285783925812861821192530917403151452391805634,
            8495653923123431417604973247489272438418190587263600148770280649306958101930,
            4082367875863433681332203403145435568316851327593401208105741076214120093531
        )
    }
}
