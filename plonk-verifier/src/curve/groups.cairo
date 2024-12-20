use plonk_verifier::traits::{FieldOps as FOps, FieldShortcuts as FShort};
use plonk_verifier::fields::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg};
use plonk_verifier::fields::print::{FqPrintImpl, Fq2PrintImpl};
use plonk_verifier::fields::{fq, Fq, fq2, Fq2};
use plonk_verifier::curve::constants::FIELD_U384;
use core::circuit::{
    RangeCheck96, AddMod, MulMod, u96, CircuitInputs, circuit_add, circuit_sub,
    circuit_mul, circuit_inverse, EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus,
    AddInputResultTrait, EvalCircuitResult, CircuitElementTrait, IntoCircuitInputValue, 
};
use core::circuit::{
	AddModGate as A,
	SubModGate as S,
	MulModGate as M,
	InverseGate as I,
	CircuitInput as CI,
	CircuitElement as CE,
};
use core::circuit::conversions::from_u256;
use core::fmt::{Display, Formatter, Error};

use debug::PrintTrait as Print;

type AffineG1 = Affine<Fq>;
type AffineG2 = Affine<Fq2>;

// impl CircuitAffineOperations<T, +CircuitElementTrait<T>> of CircuitECOperations<T> {
//     fn pt_on_slope(self: CircuitBuilder<T>, lhs: @Affine<Fq>, slope: Fq, x2: Fq) -> (CircuitElement<T>, CircuitElement<T>) {
//         let x_2 = x2;
//         // x = λ^2 - x1 - x2
//         // slope.sqr() - *self.x - x2
//         //let x = self.x_on_slope(slope, x2);
//         // y = λ(x1 - x) - y1
//         // slope * (*self.x - x) - *self.y
//         //let y = self.y_on_slope(slope, x);
        
//         let lambda = CircuitElement::<CircuitInput<0>> {};
//         let x1 = CircuitElement::<CircuitInput<1>> {};
//         let y1 = CircuitElement::<CircuitInput<2>> {};
//         let x2 = CircuitElement::<CircuitInput<3>> {};        
        
//         let lambda_sqr = circuit_mul(lambda, lambda);  // slope.sqr()
//         let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
//         let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x2); // slope.sqr() - *self.x - x2

//         let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
//         let y_slope_mul_lambda_x1_x = circuit_mul(lambda, y_slope_sub_x1_x); // slope * (*self.x - x)
//         let y_slope_lambda_sub_lambda_x_y = circuit_sub(y_slope_mul_lambda_x1_x, y1); // slope * (*self.x - x) - *self.y

//         // let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
//         // let lambda = from_u256(slope.c0);
//         // let x1 = from_u256(*self.x.c0);
//         // let y1 = from_u256(*self.y.c0);
//         // let x2 = from_u256(x_2.c0);

//         // let outputs =
//         //     match (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y, )
//         //         .new_inputs()
//         //         .next(lambda)
//         //         .next(x1)
//         //         .next(y1)
//         //         .next(x2)
//         //         .done()
//         //         .eval(modulus) {
//         //     Result::Ok(outputs) => { outputs },
//         //     Result::Err(_) => { panic!("Expected success") }
//         // };
        
//         // let x = Fq{c0: outputs.get_output(x_slope_sub_x1_x2).try_into().unwrap()};
//         // let y = Fq{c0: outputs.get_output(y_slope_lambda_sub_lambda_x_y).try_into().unwrap()};

//         // Affine { x, y }
//         (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y)
//     }

    // fn double_as_circuit(self: CircuitBuilder<T>, lhs: @Affine<Fq>,) -> (CircuitElement<T>, CircuitElement<T>) {        // λ = (3x^2 + a) / 2y
    //     // But BN curve has a == 0 so that's one less addition
    //     // λ = 3x^2 / 2y
    //     // let x_2 = x.sqr();
    //     // (x_2 + x_2 + x_2) / y.u_add(y)
    //     let x1 = CircuitElement::<CircuitInput<0>> {};
    //     let y1 = CircuitElement::<CircuitInput<1>> {};

    //     let x1_sqr = circuit_mul(x1, x1); 
    //     let x1_add_x1_x1 = circuit_add(x1_sqr, x1_sqr);
    //     let x1_add_x1_x1_x1 = circuit_add(x1_add_x1_x1, x1_sqr); 

    //     let y1_double = circuit_add(y1, y1); 
    //     let y1_inv = circuit_inverse(y1_double);

    //     let tangent = circuit_mul(x1_add_x1_x1_x1, y1_inv); 

    //     let lambda_sqr = circuit_mul(tangent, tangent);  // slope.sqr()
    //     let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
    //     let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x1); // slope.sqr() - *self.x - x2

    //     let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
    //     let y_slope_mul_lambda_x1_x = circuit_mul(tangent, y_slope_sub_x1_x); // slope * (*self.x - x)
    //     let y_slope_lambda_sub_lambda_x_y = circuit_sub(y_slope_mul_lambda_x1_x, y1); // slope * (*self.x - x) - *self.y

    //     let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    //     let x1 = from_u256(*self.x.c0);
    //     let y1 = from_u256(*self.y.c0);
        
    //     let outputs =
    //         match (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y, )
    //             .new_inputs()
    //             .next(x1)
    //             .next(y1)
    //             .done()
    //             .eval(modulus) {
    //         Result::Ok(outputs) => { outputs },
    //         Result::Err(_) => { panic!("Expected success") }
    //     };
        
    //     let x = Fq{c0: outputs.get_output(x_slope_sub_x1_x2).try_into().unwrap()};
    //     let y = Fq{c0: outputs.get_output(y_slope_lambda_sub_lambda_x_y).try_into().unwrap()};

    //     Affine { x, y }

    // }

    // fn add_as_circuit(self: @Affine<Fq>, rhs: Affine<Fq>) -> Affine<Fq> {
    //     let x1 = CircuitElement::<CircuitInput<0>> {};
    //     let y1 = CircuitElement::<CircuitInput<1>> {};
    //     let x2 = CircuitElement::<CircuitInput<2>> {};
    //     let y2 = CircuitElement::<CircuitInput<3>> {};

    //     let y2_y1 = circuit_sub(y2, y1);
    //     let x2_x1 = circuit_sub(x2, x1);
    //     let x2_x1_inv = circuit_inverse(x2_x1); 
    //     let lambda = circuit_mul(y2_y1, x2_x1_inv); 

    //     let lambda_sqr = circuit_mul(lambda, lambda);  // slope.sqr()
    //     let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
    //     let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x2); // slope.sqr() - *self.x - x2

    //     let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
    //     let y_slope_mul_lambda_x1_x = circuit_mul(lambda, y_slope_sub_x1_x); // slope * (*self.x - x)
    //     let y_slope_lambda_sub_lambda_x_y = circuit_sub(y_slope_mul_lambda_x1_x, y1); // slope * (*self.x - x) - *self.y
        
    //     let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    //     let x1 = from_u256(*self.x.c0);
    //     let y1 = from_u256(*self.y.c0);
    //     let x2 = from_u256(rhs.x.c0);
    //     let y2 = from_u256(rhs.y.c0);
        
    //     let outputs =
    //         match (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y, )
    //             .new_inputs()
    //             .next(x1)
    //             .next(y1)
    //             .next(x2)
    //             .next(y2)
    //             .done()
    //             .eval(modulus) {
    //         Result::Ok(outputs) => { outputs },
    //         Result::Err(_) => { panic!("Expected success") }
    //     };
        
    //     let x = Fq{c0: outputs.get_output(x_slope_sub_x1_x2).try_into().unwrap()};
    //     let y = Fq{c0: outputs.get_output(y_slope_lambda_sub_lambda_x_y).try_into().unwrap()};

    //     Affine { x, y }
    // }

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

    

    // #[inline(always)]
    // fn chord(self: @Affine<Fq>, rhs: Affine<Fq>) -> Fq {
    //     let x1 = CircuitElement::<CircuitInput<0>> {};
    //     let y1 = CircuitElement::<CircuitInput<1>> {};
    //     let x2 = CircuitElement::<CircuitInput<2>> {};
    //     let y2 = CircuitElement::<CircuitInput<3>> {};

    //     let y2_y1 = circuit_sub(y2, y1);
    //     let x2_x1 = circuit_sub(x2, x1);
    //     let x2_x1_inv = circuit_inverse(x2_x1); 
    //     let mul = circuit_mul(y2_y1, x2_x1_inv); 
        
    //     let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    //     let x1 = from_u256(*self.x.c0);
    //     let y1 = from_u256(*self.y.c0);
    //     let x2 = from_u256(rhs.x.c0);
    //     let y2 = from_u256(rhs.y.c0);
        
    //     let outputs =
    //         match (mul, )
    //             .new_inputs()
    //             .next(x1)
    //             .next(x2)
    //             .next(y1)
    //             .next(y2)
    //             .done()
    //             .eval(modulus) {
    //         Result::Ok(outputs) => { outputs },
    //         Result::Err(_) => { panic!("Expected success") }
    //     };
    //     Fq{c0: outputs.get_output(mul).try_into().unwrap()}
    // }
// }



#[derive(Copy, Drop, Serde)]
struct Affine<T> {
    x: T,
    y: T
}

trait ECGroup<TCoord> {
    fn one() -> Affine<TCoord>;
}

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

trait ECOperationsCircuitFq {
    // fn x_on_slope(self: @Affine<Fq>, slope: Fq, x2: Fq) -> Fq;
    // fn y_on_slope(self: @Affine<Fq>, slope: Fq, x: Fq) -> Fq;
    fn pt_on_slope(self: @Affine<Fq>, slope: Fq, x2: Fq) -> Affine<Fq>;
    fn chord(self: @Affine<Fq>, rhs: Affine<Fq>) -> Fq;
    fn add_as_circuit(self: @Affine<Fq>, rhs: Affine<Fq>) -> Affine<Fq>;
    // fn tangent(self: @Affine<Fq>) -> Fq;
    fn double_as_circuit(self: @Affine<Fq>) -> Affine<Fq>;
    fn multiply_as_circuit(self: @Affine<Fq>, multiplier: u256) -> Affine<Fq>;
    // fn neg(self: @Affine<Fq>) -> Affine<Fq>;
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
    fn double_as_circuit(self: @Affine<Fq>) -> Affine<Fq> {
        // λ = (3x^2 + a) / 2y
        // But BN curve has a == 0 so that's one less addition
        // λ = 3x^2 / 2y
        // let x_2 = x.sqr();
        // (x_2 + x_2 + x_2) / y.u_add(y)
        let x1 = CE::<CI<0>> {};
        let y1 = CE::<CI<1>> {};

        let x1_sqr = circuit_mul(x1, x1); 
        let x1_add_x1_x1 = circuit_add(x1_sqr, x1_sqr);
        let x1_add_x1_x1_x1 = circuit_add(x1_add_x1_x1, x1_sqr); 

        let y1_double = circuit_add(y1, y1); 
        let y1_inv = circuit_inverse(y1_double);

        let tangent = circuit_mul(x1_add_x1_x1_x1, y1_inv); 

        let lambda_sqr = circuit_mul(tangent, tangent);  // slope.sqr()
        let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
        let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x1); // slope.sqr() - *self.x - x2

        let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
        let y_slope_mul_lambda_x1_x = circuit_mul(tangent, y_slope_sub_x1_x); // slope * (*self.x - x)
        let y_slope_lambda_sub_lambda_x_y = circuit_sub(y_slope_mul_lambda_x1_x, y1); // slope * (*self.x - x) - *self.y

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
        let x1 = from_u256(*self.x.c0);
        let y1 = from_u256(*self.y.c0);
        
        let outputs =
            match (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y, )
                .new_inputs()
                .next(x1)
                .next(y1)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        
        let x = Fq{c0: outputs.get_output(x_slope_sub_x1_x2).try_into().unwrap()};
        let y = Fq{c0: outputs.get_output(y_slope_lambda_sub_lambda_x_y).try_into().unwrap()};

        Affine { x, y }

    }

    fn add_as_circuit(self: @Affine<Fq>, rhs: Affine<Fq>) -> Affine<Fq> {
        let x1 = CE::<CI<0>> {};
        let y1 = CE::<CI<1>> {};
        let x2 = CE::<CI<2>> {};
        let y2 = CE::<CI<3>> {};

        let y2_y1 = circuit_sub(y2, y1);
        let x2_x1 = circuit_sub(x2, x1);
        let x2_x1_inv = circuit_inverse(x2_x1); 
        let lambda = circuit_mul(y2_y1, x2_x1_inv); 

        let lambda_sqr = circuit_mul(lambda, lambda);  // slope.sqr()
        let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
        let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x2); // slope.sqr() - *self.x - x2

        let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
        let y_slope_mul_lambda_x1_x = circuit_mul(lambda, y_slope_sub_x1_x); // slope * (*self.x - x)
        let y_slope_lambda_sub_lambda_x_y = circuit_sub(y_slope_mul_lambda_x1_x, y1); // slope * (*self.x - x) - *self.y
        
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
        let x1 = from_u256(*self.x.c0);
        let y1 = from_u256(*self.y.c0);
        let x2 = from_u256(rhs.x.c0);
        let y2 = from_u256(rhs.y.c0);
        
        let outputs =
            match (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y, )
                .new_inputs()
                .next(x1)
                .next(y1)
                .next(x2)
                .next(y2)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        
        let x = Fq{c0: outputs.get_output(x_slope_sub_x1_x2).try_into().unwrap()};
        let y = Fq{c0: outputs.get_output(y_slope_lambda_sub_lambda_x_y).try_into().unwrap()};

        Affine { x, y }
    }

    fn multiply_as_circuit(self: @Affine<Fq>, mut multiplier: u256) -> Affine<Fq> {
        let nz2: NonZero<u256> = 2_u256.try_into().unwrap();
        let mut dbl_step = *self;
        let mut result = g1(1, 2);
        let mut first_add_done = false;

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
                        result.add_as_circuit(dbl_step)
                    }
            }
            if q == 0 {
                break;
            }
            dbl_step = dbl_step.double_as_circuit();
            multiplier = q;
        };
        result
    }

    fn pt_on_slope(self: @Affine<Fq>, slope: Fq, x2: Fq) -> Affine<Fq> {
        let x_2 = x2;
        // x = λ^2 - x1 - x2
        // slope.sqr() - *self.x - x2
        //let x = self.x_on_slope(slope, x2);
        // y = λ(x1 - x) - y1
        // slope * (*self.x - x) - *self.y
        //let y = self.y_on_slope(slope, x);
        
        let lambda = CE::<CI<0>> {};
        let x1 = CE::<CI<1>> {};
        let y1 = CE::<CI<2>> {};
        let x2 = CE::<CI<3>> {};        
        
        let lambda_sqr = circuit_mul(lambda, lambda);  // slope.sqr()
        let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
        let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x2); // slope.sqr() - *self.x - x2

        let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
        let y_slope_mul_lambda_x1_x = circuit_mul(lambda, y_slope_sub_x1_x); // slope * (*self.x - x)
        let y_slope_lambda_sub_lambda_x_y = circuit_sub(y_slope_mul_lambda_x1_x, y1); // slope * (*self.x - x) - *self.y

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
        let lambda = from_u256(slope.c0);
        let x1 = from_u256(*self.x.c0);
        let y1 = from_u256(*self.y.c0);
        let x2 = from_u256(x_2.c0);

        let outputs =
            match (x_slope_sub_x1_x2, y_slope_lambda_sub_lambda_x_y, )
                .new_inputs()
                .next(lambda)
                .next(x1)
                .next(y1)
                .next(x2)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        
        let x = Fq{c0: outputs.get_output(x_slope_sub_x1_x2).try_into().unwrap()};
        let y = Fq{c0: outputs.get_output(y_slope_lambda_sub_lambda_x_y).try_into().unwrap()};

        Affine { x, y }
    }

    #[inline(always)]
    fn chord(self: @Affine<Fq>, rhs: Affine<Fq>) -> Fq {
        let x1 = CE::<CI<0>> {};
        let y1 = CE::<CI<1>> {};
        let x2 = CE::<CI<2>> {};
        let y2 = CE::<CI<3>> {};

        let y2_y1 = circuit_sub(y2, y1);
        let x2_x1 = circuit_sub(x2, x1);
        let x2_x1_inv = circuit_inverse(x2_x1); 
        let mul = circuit_mul(y2_y1, x2_x1_inv); 
        
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
        let x1 = from_u256(*self.x.c0);
        let y1 = from_u256(*self.y.c0);
        let x2 = from_u256(rhs.x.c0);
        let y2 = from_u256(rhs.y.c0);
        
        let outputs =
            match (mul, )
                .new_inputs()
                .next(x1)
                .next(x2)
                .next(y1)
                .next(y2)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        Fq{c0: outputs.get_output(mul).try_into().unwrap()}
    }
}

// Cairo does not support generic and specific implementations concurrently
impl AffineOps<
    T, +FOps<T>, +FShort<T>, +Copy<T>, +Print<T>, +Drop<T>, impl ECGImpl: ECGroup<T>
> of ECOperations<T> {
    #[inline(always)]
    fn x_on_slope(self: @Affine<T>, slope: T, x2: T) -> T {
        // x = λ^2 - x1 - x2
        slope.sqr() - *self.x - x2  
    }

    #[inline(always)]
    fn y_on_slope(self: @Affine<T>, slope: T, x: T) -> T {
        // y = λ(x1 - x) - y1
        slope * (*self.x - x) - *self.y
    }

    // #[inline(always)]
    fn pt_on_slope(self: @Affine<T>, slope: T, x2: T) -> Affine<T> {
        let x = self.x_on_slope(slope, x2);
        let y = self.y_on_slope(slope, x);
        Affine { x, y }
    }

    #[inline(always)]
    fn chord(self: @Affine<T>, rhs: Affine<T>) -> T {
        let Affine { x: x1, y: y1 } = *self;
        let Affine { x: x2, y: y2 } = rhs;
        // λ = (y2-y1) / (x2-x1)
        (y2 - y1) / (x2 - x1)
    }

    // #[inline(always)]
    fn add(self: @Affine<T>, rhs: Affine<T>) -> Affine<T> {
        self.pt_on_slope(self.chord(rhs), rhs.x)
    }

    // #[inline(always)]
    fn tangent(self: @Affine<T>) -> T {
        let Affine { x, y } = *self;

        // λ = (3x^2 + a) / 2y
        // But BN curve has a == 0 so that's one less addition
        // λ = 3x^2 / 2y
        let x_2 = x.sqr();
        (x_2 + x_2 + x_2) / y.u_add(y)
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

//
// #[inline(always)]
// fn chord(self: @Affine<T>, rhs: Affine<T>) -> T {
//     let Affine { x: x1, y: y1 } = *self;
//     let Affine { x: x2, y: y2 } = rhs;
//     // λ = (y2-y1) / (x2-x1)
//     (y2 - y1) / (x2 - x1)
// }

// div
// rhs inv
//     // #[inline(always)]
//     fn inv(self: Fq2, field_nz: NonZero<u256>) -> Fq2 {
//         let Fq2 { c0, c1 } = self;
//         let t = FqOps::inv(c0.sqr() + c1.sqr(), field_nz);
//         Fq2 { c0: c0.mul(t), c1: c1.mul(-t) }
//     }
fn chord_fq2(s: Affine<Fq2>, q: Affine<Fq2>) {
    // Testing
    let lhs_x_0 = CE::<CI<0>> {};
    let lhs_x_1 = CE::<CI<1>> {};
    let lhs_y_0 = CE::<CI<2>> {};
    let lhs_y_1 = CE::<CI<3>> {};
    let rhs_x_0 = CE::<CI<4>> {};
    let rhs_x_1 = CE::<CI<5>> {};
    let rhs_y_0 = CE::<CI<6>> {};
    let rhs_y_1 = CE::<CI<7>> {};

    // y2 - y1 lhs
    let y2_y1_0 = circuit_sub(rhs_y_0, lhs_y_0);
    let y2_y1_1 = circuit_sub(rhs_y_1, lhs_y_1);

    // x2 - x1 rhs
    let x2_x1_0 = circuit_sub(rhs_x_0, lhs_x_0);
    let x2_x1_1 = circuit_sub(rhs_x_1, lhs_x_1);

    // sqr let t = FqOps::inv(c0.sqr() + c1.sqr(), field_nz);
    let x2_x1_sqr_0 = circuit_mul(x2_x1_0, x2_x1_0);
    let x2_x1_sqr_1 = circuit_mul(x2_x1_1, x2_x1_1); 
    let x2_x1_add = circuit_add(x2_x1_sqr_0, x2_x1_sqr_1);
    let x2_x1_inv = circuit_inverse(x2_x1_add);

    //Fq2 { c0: c0.mul(t), c1: c1.mul(-t) }
    let x2_x1_out_0 = circuit_mul(x2_x1_0, x2_x1_inv);
    let zero = circuit_sub(lhs_x_0, lhs_x_0);
    let x2_x1_out_1_neg = circuit_sub(zero, x2_x1_inv);
    let x2_x1_out_1 = circuit_mul(x2_x1_1, x2_x1_out_1_neg); 

    // mul 
    let t0: core::circuit::CircuitElement::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<6>, core::circuit::CircuitInput::<2>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::InverseGate::<core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>>>>>>>  = circuit_mul(y2_y1_0, x2_x1_out_0);
    let t1: core::circuit::CircuitElement::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<7>, core::circuit::CircuitInput::<3>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<0>, core::circuit::CircuitInput::<0>>, core::circuit::InverseGate::<core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>>>>>>>> = circuit_mul(y2_y1_1, x2_x1_out_1);
    let a0_add_a1: core::circuit::CircuitElement::<core::circuit::AddModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<6>, core::circuit::CircuitInput::<2>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<7>, core::circuit::CircuitInput::<3>>>> = circuit_add(y2_y1_0, y2_y1_1);
    let b0_add_b1: core::circuit::CircuitElement::<core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::InverseGate::<core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>>>>>,core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<0>, core::circuit::CircuitInput::<0>>, core::circuit::InverseGate::<core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>>>>>>>> = circuit_add(x2_x1_out_0, x2_x1_out_1);
    let t2 = circuit_mul(a0_add_a1, b0_add_b1);
    let t3 = circuit_add(t0, t1);
    let t3: core::circuit::CircuitElement::<core::circuit::SubModGate::<core::circuit::MulModGate::<core::circuit::AddModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<6>, core::circuit::CircuitInput::<2>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<7>, core::circuit::CircuitInput::<3>>>, core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::InverseGate::<core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>>>>>,core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<0>, core::circuit::CircuitInput::<0>>, core::circuit::InverseGate::<core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>>>>>>>>, core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<6>, core::circuit::CircuitInput::<2>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::InverseGate::<core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>>>>>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<7>, core::circuit::CircuitInput::<3>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<0>, core::circuit::CircuitInput::<0>>, core::circuit::InverseGate::<core::circuit::AddModGate::<core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<4>, core::circuit::CircuitInput::<0>>>, core::circuit::MulModGate::<core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>, core::circuit::SubModGate::<core::circuit::CircuitInput::<5>, core::circuit::CircuitInput::<1>>>>>>>>>>> = circuit_sub(t2, t3);
    let t4: CE::<S::<M::<S::<CI::<6>, CI::<2>>, M::<S::<CI::<4>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>, M::<S::<CI::<7>, CI::<3>>, M::<S::<CI::<5>, CI::<1>>, S::<S::<CI::<0>, CI::<0>>, I::<A::<M::<S::<CI::<4>, CI::<0>>, S::<CI::<4>, CI::<0>>>, M::<S::<CI::<5>, CI::<1>>, S::<CI::<5>, CI::<1>>>>>>>>>> = circuit_sub(t0, t1);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    let x1_0 = from_u256(s.x.c0.c0);
    let x1_1 = from_u256(s.x.c1.c0);
    let y1_0 = from_u256(s.y.c0.c0);
    let y1_1 = from_u256(s.y.c1.c0);
    let x2_0 = from_u256(q.x.c0.c0);
    let x2_1 = from_u256(q.x.c1.c0);
    let y2_0 = from_u256(q.y.c0.c0);
    let y2_1 = from_u256(q.y.c1.c0);

    let outputs =
        match (t4,t3,)
            .new_inputs()
            .next(x1_0)
            .next(x1_1)
            .next(y1_0)
            .next(y1_1)
            .next(x2_0)
            .next(x2_1)
            .next(y2_0)
            .next(y2_1) 
            .done()
            .eval(modulus) {
        Result::Ok(outputs) => { outputs },
        Result::Err(_) => { panic!("Expected success") }
    };
    let slope1 = Fq2{c0: fq(outputs.get_output(t4).try_into().unwrap()), c1: fq(outputs.get_output(t3).try_into().unwrap())};
}

use core::circuit::CircuitDefinition;
fn new_inputs<impl CD: CircuitDefinition<CES>, +Drop<CES>, CES>() ->  CD::CircuitType{
    let lambda = CE::<CI<0>> {};
    let x1 = CE::<CI<1>> {};
    let y1 = CE::<CI<2>> {};
    let x2 = CE::<CI<3>> {};        
    
    let lambda_sqr = circuit_mul(lambda, lambda);  // slope.sqr()
    let x_slope_sub_sqr_x1 = circuit_sub(lambda_sqr, x1); // slope.sqr() - *self.x
    let x_slope_sub_x1_x2 = circuit_sub(x_slope_sub_sqr_x1, x2); // slope.sqr() - *self.x - x2

    let y_slope_sub_x1_x = circuit_sub(x1, x_slope_sub_x1_x2); // (*self.x - x)
    let y_slope_mul_lambda_x1_x = circuit_mul(lambda, y_slope_sub_x1_x); // slope * (*self.x - x)
    let y_slope_lambda_sub_lambda_x_y = circuit_sub(y_slope_mul_lambda_x1_x, y1); // slope * (*self.x - x) - *self.y

    (y_slope_lambda_sub_lambda_x_y)
}