use plonk_verifier::traits::{FieldOps as FOps, FieldShortcuts as FShort};
use plonk_verifier::fields::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg};
use plonk_verifier::fields::print::{FqPrintImpl, Fq2PrintImpl};
use plonk_verifier::fields::{fq, Fq, fq2, Fq2, fq6, Fq6};
use plonk_verifier::curve::constants::FIELD_U384;
use core::circuit::{
    RangeCheck96, AddMod, MulMod, u96, CircuitElement, CircuitInput, circuit_add, circuit_sub,
    circuit_mul, circuit_inverse, EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus,
    AddInputResultTrait, CircuitInputs,EvalCircuitResult,
};
use core::circuit::conversions::from_u256;
use core::fmt::{Display, Formatter, Error};

use debug::PrintTrait as Print;

type AffineG1 = Affine<Fq>;
type AffineG2 = Affine<Fq2>;
type AffineG6 = Affine<Fq6>;

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

trait ECOperationsCircuitFq2{
    fn x_on_slope(self: @Affine<Fq2>, slope: Fq2, x2: Fq2) -> Fq2;
    fn y_on_slope(self: @Affine<Fq2>, slope: Fq2, x: Fq2) -> Fq2;
    fn pt_on_slope(self: @Affine<Fq2>, slope: Fq2, x2: Fq2) -> Affine<Fq2>;
    fn chord(self: @Affine<Fq2>, rhs: Affine<Fq2>) -> Fq2;
    fn add_as_circuit(self: @Affine<Fq2>, rhs: Affine<Fq2>) -> Affine<Fq2>;
    fn tangent(self: @Affine<Fq2>) -> Fq2;
    fn double_as_circuit(self: @Affine<Fq2>) -> Affine<Fq2>;
    fn multiply_as_circuit(self: @Affine<Fq2>, multiplier: u256) -> Affine<Fq2>;
    // fn neg(self: @Affine<Fq>) -> Affine<Fq>;
}

/// Trait for elliptic curve operations on affine points over Fq6 in a circuit.
trait ECOperationsCircuitFq6 {

    fn x_on_slope(self: @Affine<Fq6>, slope: Fq6, x2: Fq6) -> Fq6;
    fn y_on_slope(self: @Affine<Fq6>, slope: Fq6, x: Fq6) -> Fq6;
    fn pt_on_slope(self: @Affine<Fq6>, slope: Fq6, x2: Fq6) -> Affine<Fq6>;
    fn chord(self: @Affine<Fq6>, rhs: Affine<Fq6>) -> Fq6;
    fn add_as_circuit(self: @Affine<Fq6>, rhs: Affine<Fq6>) -> Affine<Fq6>;
    fn tangent(self: @Affine<Fq6>) -> Fq6;
    fn double_as_circuit(self: @Affine<Fq6>) -> Affine<Fq6>;
    fn multiply_as_circuit(self: @Affine<Fq6>, multiplier: u256) -> Affine<Fq6>;
    // fn neg(self: @Affine<Fq6>) -> Affine<Fq6>;
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
        let x1 = CircuitElement::<CircuitInput<0>> {};
        let y1 = CircuitElement::<CircuitInput<1>> {};

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
        let x1 = CircuitElement::<CircuitInput<0>> {};
        let y1 = CircuitElement::<CircuitInput<1>> {};
        let x2 = CircuitElement::<CircuitInput<2>> {};
        let y2 = CircuitElement::<CircuitInput<3>> {};

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
        //-------------------------------------
        // STEP 1: Compute x3 using x_on_slope
        //-------------------------------------
        let x3 = self.x_on_slope(slope, x2);

        //-------------------------------------
        // STEP 2: Compute y3 using y_on_slope
        //-------------------------------------
        let y3 = self.y_on_slope(slope, x3);

        //-------------------------------------
        // STEP 3: Return the resulting point
        //-------------------------------------
        Affine { x: x3, y: y3 }
    }

    #[inline(always)]
    fn chord(self: @Affine<Fq>, rhs: Affine<Fq>) -> Fq {
        let x1 = CircuitElement::<CircuitInput<0>> {};
        let y1 = CircuitElement::<CircuitInput<1>> {};
        let x2 = CircuitElement::<CircuitInput<2>> {};
        let y2 = CircuitElement::<CircuitInput<3>> {};

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

impl AffineOpsFq2Circuit of ECOperationsCircuitFq2{

    fn double_as_circuit(self: @Affine<Fq2>) -> Affine<Fq2> {
        /// Compute the doubling of a point on an elliptic curve in Fq2.
        /// The steps involve:
        /// 1. Calculating the slope (λ) for doubling.
        /// 2. Using λ to compute the new x-coordinate (x3).
        /// 3. Using λ and x3 to compute the new y-coordinate (y3).
    
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        let fq0_x0 = CircuitElement::<CircuitInput<0>> {}; // x1.a
        let fq0_y0 = CircuitElement::<CircuitInput<1>> {}; // y1.a
        let fq0_x1 = CircuitElement::<CircuitInput<2>> {}; // x1.b
        let fq0_y1 = CircuitElement::<CircuitInput<3>> {}; // y1.b
    
        //-------------------------------------
        // STEP 2: Calculate λ (slope for doubling)
        //-------------------------------------
        /// λ = (3 * x1^2) / (2 * y1)
    
        // Sub-step 2.1: Calculate 3 * x1^2
            // PART A: x1.a^2 - x1.b^2
            let fq0_x0_sqr = circuit_mul(fq0_x0, fq0_x0); // x1.a^2
            let fq0_x1_sqr = circuit_mul(fq0_x1, fq0_x1); // x1.b^2
            let x_square_a = circuit_sub(fq0_x0_sqr, fq0_x1_sqr); // x1.a^2 - x1.b^2
    
            // PART B: 2 * x1.a * x1.b
            let fq0_x0_x1 = circuit_mul(fq0_x0, fq0_x1); // x1.a * x1.b
            let x_square_b = circuit_add(fq0_x0_x1, fq0_x0_x1); // 2 * fq0_x0_x1
    
            // Tripling (3 * x1^2)
            let x_square_a_3 = circuit_add(x_square_a, circuit_add(x_square_a, x_square_a)); // 3 * x1.a^2
            let x_square_b_3 = circuit_add(x_square_b, circuit_add(x_square_b, x_square_b)); // 3 * x1.b^2
    
        // Sub-step 2.2: Calculate 2 * y1
            // PART A: 2 * y1.a
            let fq0_y0_double = circuit_add(fq0_y0, fq0_y0);
    
            // PART B: 2 * y1.b
            let fq0_y1_double = circuit_add(fq0_y1, fq0_y1);
    
        // Sub-step 2.3: Calculate the inverse of 2 * y1
            let denom = circuit_add(
                circuit_mul(fq0_y0_double, fq0_y0_double), // (2 * y1.a)^2
                circuit_mul(fq0_y1_double, fq0_y1_double), // (2 * y1.b)^2
            );
            let inv_denom = circuit_inverse(denom);
    
            // PART A: λ.a = 3 * x1.a^2 / 2 * y1.a
            let lambda_a = circuit_mul(x_square_a_3, inv_denom);
    
            // PART B: λ.b = 3 * x1.b^2 / 2 * y1.b
            let lambda_b = circuit_mul(x_square_b_3, inv_denom);
    
        //-------------------------------------
        // STEP 3: Calculate the new x-coordinate (x3)
        //-------------------------------------
        /// x3 = λ² - 2 * x1
    
        // Sub-step 3.1: λ²
            // PART A: λ.a^2 - λ.b^2
            let lambda_sqr_a = circuit_sub(
                circuit_mul(lambda_a, lambda_a), // λ.a^2
                circuit_mul(lambda_b, lambda_b), // λ.b^2
            );
    
            // PART B: 2 * λ.a * λ.b
            let temp = circuit_mul(lambda_a, lambda_b);
            let lambda_sqr_b = circuit_add(
                temp, 
                temp
            );
    
        // Sub-step 3.2: x3 = λ² - 2 * x1
            // PART A: λ².a - 2 * x1.a
            let x3_a = circuit_sub(lambda_sqr_a, circuit_add(fq0_x0, fq0_x0)); // λ².a - 2 * x1.a
    
            // PART B: λ².b - 2 * x1.b
            let x3_b = circuit_sub(lambda_sqr_b, circuit_add(fq0_x1, fq0_x1)); // λ².b - 2 * x1.b
    
        //-------------------------------------
        // STEP 4: Calculate the new y-coordinate (y3)
        //-------------------------------------
        /// y3 = λ * (x1 - x3) - y1
    
        // Sub-step 4.1: Difference between x1 and x3
            // PART A: x1.a - x3.a
            let diff_x1_x3_a = circuit_sub(fq0_x0, x3_a);
    
            // PART B: x1.b - x3.b
            let diff_x1_x3_b = circuit_sub(fq0_x1, x3_b);
    
        // Sub-step 4.2: λ * (x1 - x3)
            // PART A: λ.a * diff_x1_x3.a - λ.b * diff_x1_x3.b
            let lambda_diff_a = circuit_sub(
                circuit_mul(lambda_a, diff_x1_x3_a),
                circuit_mul(lambda_b, diff_x1_x3_b),
            );
    
            // PART B: λ.a * diff_x1_x3.b + λ.b * diff_x1_x3.a
            let lambda_diff_b = circuit_add(
                circuit_mul(lambda_a, diff_x1_x3_b),
                circuit_mul(lambda_b, diff_x1_x3_a),
            );
    
        // Sub-step 4.3: y3 = λ * (x1 - x3) - y1
            // PART A: λ * diff_x1_x3.a - y1.a
            let y3_a = circuit_sub(lambda_diff_a, fq0_y0);
    
            // PART B: λ * diff_x1_x3.b - y1.b
            let y3_b = circuit_sub(lambda_diff_b, fq0_y1);
    
        //-------------------------------------
        // STEP 5: Circuit output
        //-------------------------------------
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
        let outputs = match (x3_a, x3_b, y3_a, y3_b)
            .new_inputs()
            .next(from_u256(*self.x.c0.c0))
            .next(from_u256(*self.x.c1.c0))
            .next(from_u256(*self.y.c0.c0))
            .next(from_u256(*self.y.c1.c0))
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Expected success"),
        };
    
        //-------------------------------------
        // STEP 6: Retrieve the final coordinates
        //-------------------------------------
        let x = Fq2 {
            c0: Fq {
                c0: outputs.get_output(x3_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(x3_b).try_into().unwrap(),
            },
        };
    
        let y = Fq2 {
            c0: Fq {
                c0: outputs.get_output(y3_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(y3_b).try_into().unwrap(),
            },
        };
    
        // Return the new affine point
        Affine { x, y }
    }
    
    fn add_as_circuit(self: @Affine<Fq2>, rhs: Affine<Fq2>) -> Affine<Fq2> {
        /// Add two points in Fq2 using elliptic curve addition.
        /// This involves:
        /// 1. Calculating the slope (λ) between the two points.
        /// 2. Using λ to compute the new x-coordinate (x3).
        /// 3. Using λ and x3 to compute the new y-coordinate (y3).
    
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        let fq0_x0 = CircuitElement::<CircuitInput<0>> {}; // x1.a
        let fq0_y0 = CircuitElement::<CircuitInput<1>> {}; // y1.a
        let fq0_x1 = CircuitElement::<CircuitInput<2>> {}; // x1.b
        let fq0_y1 = CircuitElement::<CircuitInput<3>> {}; // y1.b
    
        let fq1_x0 = CircuitElement::<CircuitInput<4>> {}; // x2.a
        let fq1_y0 = CircuitElement::<CircuitInput<5>> {}; // y2.a
        let fq1_x1 = CircuitElement::<CircuitInput<6>> {}; // x2.b
        let fq1_y1 = CircuitElement::<CircuitInput<7>> {}; // y2.b
    
        //-------------------------------------
        // STEP 2: Calculate the slope (λ)
        //-------------------------------------
        /// λ = (y2 - y1) / (x2 - x1)
    
        // Numerator of λ: (y2 - y1)

            // PART A: y2.a - y1.a
            let diff_y_a = circuit_sub(fq1_y0, fq0_y0);
        
            // PART B: y2.b - y1.b
            let diff_y_b = circuit_sub(fq1_y1, fq0_y1);
    
        // Denominator of λ: (x2 - x1)

            // PART A: x2.a - x1.a
            let diff_x_a = circuit_sub(fq1_x0, fq0_x0);
        
            // PART B: x2.b - x1.b
            let diff_x_b = circuit_sub(fq1_x1, fq0_x1);
        
        // Calculate denominator squared: (x2.a)^2 + (x2.b)^2
        // After the inverse of it
        let denom = circuit_add(
            circuit_mul(diff_x_a, diff_x_a), // (x2.a)^2
            circuit_mul(diff_x_b, diff_x_b), // (x2.b)^2
        );
        let inv_denom = circuit_inverse(denom);
        
        //MULTIPLICATION NUMERSTOR AND INVERSE DENOMINATOR

            // PART A: λ.a = (diff_y_a * diff_x_a - diff_y_b * diff_x_b) / denom
            let lambda_a = circuit_mul(
                circuit_sub(
                    circuit_mul(diff_y_a, diff_x_a), // diff_y_a * diff_x_a
                    circuit_mul(diff_y_b, diff_x_b), // diff_y_b * diff_x_b
                ),
                inv_denom, // Divide by denom
            );
        
            // PART B: λ.b = (diff_y_a * diff_x_b + diff_y_b * diff_x_a) / denom
            let lambda_b = circuit_mul(
                circuit_add(
                    circuit_mul(diff_y_a, diff_x_b), // diff_y_a * diff_x_b
                    circuit_mul(diff_y_b, diff_x_a), // diff_y_b * diff_x_a
                ),
                inv_denom, // Divide by denom
            );
    
        //-------------------------------------
        // STEP 3: Compute the new x-coordinate (x3)
        //-------------------------------------
        /// x3 = λ² - x1 - x2
    
        // λ²
            // PART A: λ.a² - λ.b²
            let lambda_sqr_a = circuit_sub(
                circuit_mul(lambda_a, lambda_a), // λ.a²
                circuit_mul(lambda_b, lambda_b), // λ.b²
            );
        
            // PART B: 2 * λ.a * λ.b
            let lambda_sqr_b = circuit_add(
                circuit_mul(lambda_a, lambda_b), // λ.a * λ.b
                circuit_mul(lambda_a, lambda_b), // λ.a * λ.b (again)
            );
    
        // Calculate x3
            // PART A: λ².a - x1.a - x2.a
            let new_x_a = circuit_sub(
                circuit_sub(lambda_sqr_a, fq0_x0), // λ².a - x1.a
                fq1_x0,                            // - x2.a
            );
        
            // PART B: λ².b - x1.b - x2.b
            let new_x_b = circuit_sub(
                circuit_sub(lambda_sqr_b, fq0_x1), // λ².b - x1.b
                fq1_x1,                            // - x2.b
            );
    
        //-------------------------------------
        // STEP 4: Compute the new y-coordinate (y3)
        //-------------------------------------
        /// y3 = λ * (x1 - x3) - y1
    
        // Difference between x1 and x3
            // PART A: x1.a - x3.a
            let diff_x1_x3_a = circuit_sub(fq0_x0, new_x_a);
        
            // PART B: x1.b - x3.b
            let diff_x1_x3_b = circuit_sub(fq0_x1, new_x_b);
    
        // λ * (diff_x1_x3_b)
            // PART A: λ.a * diff_x1_x3.a - λ.b * diff_x1_x3.b
            let lambda_diff_a = circuit_sub(
                circuit_mul(lambda_a, diff_x1_x3_a), // λ.a * diff_x1_x3.a
                circuit_mul(lambda_b, diff_x1_x3_b), // λ.b * diff_x1_x3.b
            );
        
            // PART B: λ.a * diff_x1_x3.b + λ.b * diff_x1_x3.a
            let lambda_diff_b = circuit_add(
                circuit_mul(lambda_a, diff_x1_x3_b), // λ.a * diff_x1_x3.b
                circuit_mul(lambda_b, diff_x1_x3_a), // λ.b * diff_x1_x3.a
            );
    
        // Calculate y3
            // PART A: λ * diff_x1_x3.a - y1.a
            let new_y_a = circuit_sub(lambda_diff_a, fq0_y0);
        
            // PART B: λ * diff_x1_x3.b - y1.b
            let new_y_b = circuit_sub(lambda_diff_b, fq0_y1);
    
        //-------------------------------------
        // STEP 5: Circuit output
        //-------------------------------------
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    
        let outputs = match (new_x_a, new_x_b, new_y_a, new_y_b)
            .new_inputs()
            .next(from_u256(*self.x.c0.c0))
            .next(from_u256(*self.x.c1.c0))
            .next(from_u256(*self.y.c0.c0))
            .next(from_u256(*self.y.c1.c0))
            
            .next(from_u256(rhs.x.c0.c0))
            .next(from_u256(rhs.x.c1.c0))
            .next(from_u256(rhs.y.c0.c0))
            .next(from_u256(rhs.y.c1.c0))
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Expected success"),
        };
    
        //-------------------------------------
        // STEP 6: Retrieve the final coordinates
        //-------------------------------------
        let x = Fq2 {
            c0: Fq {
                c0: outputs.get_output(new_x_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(new_x_b).try_into().unwrap(),
            },
        };
    
        let y = Fq2 {
            c0: Fq {
                c0: outputs.get_output(new_y_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(new_y_b).try_into().unwrap(),
            },
        };
    
        // Return the new affine point
        Affine { x, y }
    }
    
    fn multiply_as_circuit(self: @Affine<Fq2>, mut multiplier: u256) -> Affine<Fq2> {
        /// Perform scalar multiplication of a point on an elliptic curve in Fq2.
        /// This involves:
        /// 1. Iterating through the binary representation of the scalar.
        /// 2. Doubling the intermediate point for every bit.
        /// 3. Adding the current intermediate point if the current bit is 1.
    
        //-------------------------------------
        // STEP 1: Initialize variables
        //-------------------------------------
        
        // Represent 2 as a non-zero constant for division
        let nz2: NonZero<u256> = 2_u256.try_into().unwrap();
        
        // `dbl_step` holds the point being doubled in each iteration
        let mut dbl_step = *self;
        
        // `result` starts with the identity element (point at infinity)
        let mut result = g2(1,2,3,4);
        
        // Flag to indicate if the first addition is done
        let mut first_add_done = false;
    
        //-------------------------------------
        // STEP 2: Iterate through the scalar bits
        //-------------------------------------
        loop {
            // Binary decomposition of the scalar multiplier
            let (q, r, _) = integer::u256_safe_divmod(multiplier, nz2);
    
            if r == 1 {
                // Perform addition if the current bit is 1
                result = if !first_add_done {
                    first_add_done = true;
                    // For the first addition, directly set the result to dbl_step
                    dbl_step
                } else {
                    // Add the current `dbl_step` to `result`
                    result.add_as_circuit(dbl_step)
                };
            }
            
            if q == 0 {
                // Terminate the loop when all bits have been processed
                break;
            }
            
            // Double the current point for the next bit
            dbl_step = dbl_step.double_as_circuit();
            
            // Update the multiplier (quotient for the next iteration)
            multiplier = q;
        };
    
        //-------------------------------------
        // STEP 3: Return the result
        //-------------------------------------
        result
    }

    fn x_on_slope(self: @Affine<Fq2>, slope: Fq2, x2: Fq2) -> Fq2 {
        /// Calculate the x-coordinate of a point on the elliptic curve given the slope and another x-coordinate.
        /// 1. Calculating λ²
        /// 2. Subtracting x1 and x2 from λ² to compute x3
    
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        let fq0_x0 = CircuitElement::<CircuitInput<0>> {}; // x1.a
        let fq0_x1 = CircuitElement::<CircuitInput<1>> {}; // x1.b
        let slope_a = CircuitElement::<CircuitInput<2>> {}; // λ.a
        let slope_b = CircuitElement::<CircuitInput<3>> {}; // λ.b
        let fq1_x0 = CircuitElement::<CircuitInput<4>> {}; // x2.a
        let fq1_x1 = CircuitElement::<CircuitInput<5>> {}; // x2.b
    
        //-------------------------------------
        // STEP 2: Calculate λ²
        //-------------------------------------
    
            // PART A: λ.a² - λ.b²
            let lambda_sqr_a = circuit_sub(
                circuit_mul(slope_a, slope_a), // λ.a²
                circuit_mul(slope_b, slope_b), // λ.b²
            );
        
            // PART B: 2 * λ.a * λ.b
            let lambda_sqr_b = circuit_add(
                circuit_mul(slope_a, slope_b), // λ.a * λ.b
                circuit_mul(slope_a, slope_b), // λ.a * λ.b (again)
            );
    
        //-------------------------------------
        // STEP 3: Calculate x3 = λ² - x1 - x2
        //-------------------------------------
    
            // PART A: λ².a - x1.a - x2.a
            let x3_a = circuit_sub(
                circuit_sub(lambda_sqr_a, fq0_x0), // λ².a - x1.a
                fq1_x0,                            // - x2.a
            );
        
            // PART B: λ².b - x1.b - x2.b
            let x3_b = circuit_sub(
                circuit_sub(lambda_sqr_b, fq0_x1), // λ².b - x1.b
                fq1_x1,                            // - x2.b
            );
    
        //-------------------------------------
        // STEP 4: Circuit output
        //-------------------------------------
    
        // Prepare modulus and convert inputs
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    
        let fq0_x0 = from_u256(*self.x.c0.c0);
        let fq0_x1 = from_u256(*self.x.c1.c0);

        let fq1_x0 = from_u256(x2.c0.c0);
        let fq1_x1 = from_u256(x2.c1.c0);

        let slope_a = from_u256(slope.c0.c0);
        let slope_b = from_u256(slope.c1.c0);
    
        // Evaluate circuit
        let outputs =
            match (x3_a, x3_b)
                .new_inputs()
                .next(fq0_x0)
                .next(fq0_x1)
                .next(fq1_x0)
                .next(fq1_x1)
                .next(slope_a)
                .next(slope_b)
                .done()
                .eval(modulus) {
                Result::Ok(outputs) => outputs,
                Result::Err(_) => panic!("Expected success"),
            };
    
        //-------------------------------------
        // STEP 5: Retrieve the final x coordinate in Fq2
        //-------------------------------------
        Fq2 {
            c0: Fq {
                c0: outputs.get_output(x3_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(x3_b).try_into().unwrap(),
            },
        }
    }

    fn y_on_slope(self: @Affine<Fq2>, slope: Fq2, x: Fq2) -> Fq2 {
        /// Calculate the y-coordinate on the elliptic curve given the slope and x-coordinate.
        /// This involves:
        /// 1. Calculating x1 - x3
        /// 2. Calculating λ * (x1 - x3)
        /// 3. Calculating y3 = λ * (x1 - x3) - y1
    
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        let fq0_x0 = CircuitElement::<CircuitInput<0>> {}; // x1.a
        let fq0_x1 = CircuitElement::<CircuitInput<1>> {}; // x1.b
        let fq0_y0 = CircuitElement::<CircuitInput<2>> {}; // y1.a
        let fq0_y1 = CircuitElement::<CircuitInput<3>> {}; // y1.b
    
        let slope_a = CircuitElement::<CircuitInput<4>> {}; // λ.a
        let slope_b = CircuitElement::<CircuitInput<5>> {}; // λ.b
    
        let fq1_x0 = CircuitElement::<CircuitInput<6>> {}; // x3.a
        let fq1_x1 = CircuitElement::<CircuitInput<7>> {}; // x3.b
    
        //-------------------------------------
        // STEP 2: Calculate x1 - x3
        //-------------------------------------
    
        // PART A: x1.a - x3.a
        let diff_x_a = circuit_sub(fq0_x0, fq1_x0);
    
        // PART B: x1.b - x3.b
        let diff_x_b = circuit_sub(fq0_x1, fq1_x1);
    
        //-------------------------------------
        // STEP 3: Calculate λ * (x1 - x3)
        //-------------------------------------
    
        // PART A: λ.a * (x1.a - x3.a) - λ.b * (x1.b - x3.b)
        let lambda_diff_a = circuit_sub(
            circuit_mul(slope_a, diff_x_a),  // λ.a * (x1.a - x3.a)
            circuit_mul(slope_b, diff_x_b), // λ.b * (x1.b - x3.b)
        );
    
        // PART B: λ.a * (x1.b - x3.b) + λ.b * (x1.a - x3.a)
        let lambda_diff_b = circuit_add(
            circuit_mul(slope_a, diff_x_b),  // λ.a * (x1.b - x3.b)
            circuit_mul(slope_b, diff_x_a), // λ.b * (x1.a - x3.a)
        );
    
        //-------------------------------------
        // STEP 4: Calculate y3 = λ * (x1 - x3) - y1
        //-------------------------------------
    
        // PART A: λ * (x1 - x3).a - y1.a
        let y3_a = circuit_sub(lambda_diff_a, fq0_y0);
    
        // PART B: λ * (x1 - x3).b - y1.b
        let y3_b = circuit_sub(lambda_diff_b, fq0_y1);
    
        //-------------------------------------
        // STEP 5: Circuit output
        //-------------------------------------
    
        // Prepare modulus and convert inputs
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    
        let fq0_x0 = from_u256(*self.x.c0.c0);
        let fq0_x1 = from_u256(*self.x.c1.c0);
        let fq0_y0 = from_u256(*self.y.c0.c0);
        let fq0_y1 = from_u256(*self.y.c1.c0);
    
        let fq1_x0 = from_u256(x.c0.c0);
        let fq1_x1 = from_u256(x.c1.c0);
    
        let slope_a = from_u256(slope.c0.c0);
        let slope_b = from_u256(slope.c1.c0);
    
        // Evaluate circuit
        let outputs =
            match (y3_a, y3_b)
                .new_inputs()
                .next(fq0_x0)
                .next(fq0_x1)
                .next(fq0_y0)
                .next(fq0_y1)
                .next(fq1_x0)
                .next(fq1_x1)
                .next(slope_a)
                .next(slope_b)
                .done()
                .eval(modulus) {
                Result::Ok(outputs) => outputs,
                Result::Err(_) => panic!("Expected success"),
            };
    
        // Retrieve the final y coordinate in Fq2
        let y = Fq2 {
            c0: Fq {
                c0: outputs.get_output(y3_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(y3_b).try_into().unwrap(),
            },
        };
    
        //-------------------------------------
        // STEP 6: Return the y coordinate
        //-------------------------------------
        y
    }

    fn pt_on_slope(self: @Affine<Fq2>, slope: Fq2, x2: Fq2) -> Affine<Fq2> {
        /// Calculate the new point on the elliptic curve using the slope and second point
        /// This involves:
        /// 1. Calculating x3 = λ² - x1 - x2
        /// 2. Calculating y3 = λ(x1 - x3) - y1
    
        // Input elements for Fq2 parts
        let fq0_x0 = CircuitElement::<CircuitInput<0>> {}; // x1.a
        let fq0_x1 = CircuitElement::<CircuitInput<1>> {}; // x1.b
        let fq0_y0 = CircuitElement::<CircuitInput<2>> {}; // y1.a
        let fq0_y1 = CircuitElement::<CircuitInput<3>> {}; // y1.b
    
        let slope_a = CircuitElement::<CircuitInput<4>> {}; // λ.a
        let slope_b = CircuitElement::<CircuitInput<5>> {}; // λ.b
    
        let fq1_x0 = CircuitElement::<CircuitInput<6>> {}; // x2.a
        let fq1_x1 = CircuitElement::<CircuitInput<7>> {}; // x2.b
    
        //-------------------------------------
        // STEP 1: Calculate λ² (lambda squared)
        //-------------------------------------
    
            // PART A: λ.a² - λ.b²
            let lambda_sqr_a = circuit_sub(
                circuit_mul(slope_a, slope_a),  // λ.a * λ.a
                circuit_mul(slope_b, slope_b), // λ.b * λ.b
            );
        
            // PART B: 2 * λ.a * λ.b
            let lambda_sqr_b = circuit_add(
                circuit_mul(slope_a, slope_b), // λ.a * λ.b
                circuit_mul(slope_a, slope_b), // λ.a * λ.b
            );
    
        //-------------------------------------
        // STEP 2: Calculate x3 = λ² - x1 - x2
        //-------------------------------------
    
            // PART A: λ².a - x1.a - x2.a
            let x3_a = circuit_sub(
                circuit_sub(lambda_sqr_a, fq0_x0), // λ².a - x1.a
                fq1_x0,                            // - x2.a
            );
        
            // PART B: λ².b - x1.b - x2.b
            let x3_b = circuit_sub(
                circuit_sub(lambda_sqr_b, fq0_x1), // λ².b - x1.b
                fq1_x1,                            // - x2.b
            );
    
        //-------------------------------------
        // STEP 3: Calculate y3 = λ(x1 - x3) - y1
        //-------------------------------------
    
            // Calculate x1 - x3 (x difference)
                // PART A: x1.a - x3.a
                let diff_x_a = circuit_sub(fq0_x0, x3_a);
            
                // PART B: x1.b - x3.b
                let diff_x_b = circuit_sub(fq0_x1, x3_b);
            
            // λ * (x1 - x3)
                // PART A: λ.a * diff_x.a - λ.b * diff_x.b
                let lambda_diff_a = circuit_sub(
                    circuit_mul(slope_a, diff_x_a),  // λ.a * (x1.a - x3.a)
                    circuit_mul(slope_b, diff_x_b), // λ.b * (x1.b - x3.b)
                );
            
                // PART B: λ.a * diff_x.b + λ.b * diff_x.a
                let lambda_diff_b = circuit_add(
                    circuit_mul(slope_a, diff_x_b),  // λ.a * (x1.b - x3.b)
                    circuit_mul(slope_b, diff_x_a), // λ.b * (x1.a - x3.a)
                );
        
            // Calculate y3: λ * (x1 - x3) - y1
                // PART A: λ * (x1 - x3).a - y1.a
                let y3_a = circuit_sub(lambda_diff_a, fq0_y0);
            
                // PART B: λ * (x1 - x3).b - y1.b
                let y3_b = circuit_sub(lambda_diff_b, fq0_y1);
    
        //-------------------------------------
        // STEP 4: Circuit Output
        //-------------------------------------
            let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    
        // Convert inputs for evaluation
        let fq0_x0 = from_u256(*self.x.c0.c0);
        let fq0_x1 = from_u256(*self.x.c1.c0);
        let fq0_y0 = from_u256(*self.y.c0.c0);
        let fq0_y1 = from_u256(*self.y.c1.c0);
    
        let fq1_x0 = from_u256(x2.c0.c0);
        let fq1_x1 = from_u256(x2.c1.c0);
    
        let slope_a = from_u256(slope.c0.c0);
        let slope_b = from_u256(slope.c1.c0);
    
        let outputs =
            match (x3_a, x3_b, y3_a, y3_b)
                .new_inputs()
                .next(fq0_x0)
                .next(fq0_x1)
                .next(fq0_y0)
                .next(fq0_y1)
                .next(fq1_x0)
                .next(fq1_x1)
                .next(slope_a)
                .next(slope_b)
                .done()
                .eval(modulus) {
                Result::Ok(outputs) => outputs,
                Result::Err(_) => panic!("Expected success"),
            };
    
        // Retrieve the final point in Affine coordinates
        let x = Fq2 {
            c0: Fq {
                c0: outputs.get_output(x3_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(x3_b).try_into().unwrap(),
            },
        };
    
        let y = Fq2 {
            c0: Fq {
                c0: outputs.get_output(y3_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(y3_b).try_into().unwrap(),
            },
        };
    
        // Return the resulting point
        Affine { x, y }
    }
    
    fn chord(self: @Affine<Fq2>, rhs: Affine<Fq2>) -> Fq2 {
        /// Calculate the slope (λ) of the line passing through two points (chord) in Fq2.
        /// This involves:
        /// 1. Calculating the numerator: y2 - y1
        /// 2. Calculating the denominator: x2 - x1
        /// 3. Computing the slope as the division of the numerator by the denominator in Fq2.
    
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        let fq0_x0 = CircuitElement::<CircuitInput<0>> {}; // x1.a
        let fq0_x1 = CircuitElement::<CircuitInput<1>> {}; // x1.b
        let fq0_y0 = CircuitElement::<CircuitInput<2>> {}; // y1.a
        let fq0_y1 = CircuitElement::<CircuitInput<3>> {}; // y1.b
    
        let fq1_x0 = CircuitElement::<CircuitInput<4>> {}; // x2.a
        let fq1_x1 = CircuitElement::<CircuitInput<5>> {}; // x2.b
        let fq1_y0 = CircuitElement::<CircuitInput<6>> {}; // y2.a
        let fq1_y1 = CircuitElement::<CircuitInput<7>> {}; // y2.b
    
        //-------------------------------------
        // STEP 2: Calculate the numerator (y2 - y1)
        //-------------------------------------
        
            // PART A: y2.a - y1.a
            let diff_y_a = circuit_sub(fq1_y0, fq0_y0); 
            
            // PART B: y2.b - y1.b
            let diff_y_b = circuit_sub(fq1_y1, fq0_y1); 
    
        //-------------------------------------
        // STEP 3: Calculate the denominator (x2 - x1)
        //-------------------------------------
        
            // PART A: x2.a - x1.a
            let diff_x_a = circuit_sub(fq1_x0, fq0_x0); 
            
            // PART B: x2.b - x1.b
            let diff_x_b = circuit_sub(fq1_x1, fq0_x1); 
    
        //-------------------------------------
        // STEP 4: Compute the slope λ = (y2 - y1) / (x2 - x1)
        //-------------------------------------
        
        // Compute the squared denominator: (x2.a)^2 + (x2.b)^2
        let denom_sqr = circuit_add(
            circuit_mul(diff_x_a, diff_x_a), // (x2.a)^2
            circuit_mul(diff_x_b, diff_x_b), // (x2.b)^2
        );
        
            // Compute the inverse of the denominator
            let inv_denom = circuit_inverse(denom_sqr);
        
            // PART A: λ.a = (diff_y_a * diff_x_a - diff_y_b * diff_x_b) / denom
            let lambda_a = circuit_sub(
                circuit_mul(diff_y_a, diff_x_a), // diff_y_a * diff_x_a
                circuit_mul(diff_y_b, diff_x_b), // diff_y_b * diff_x_b
            );
            let lambda_a = circuit_mul(lambda_a, inv_denom); // Divide by denom
        
            // PART B: λ.b = (diff_y_a * diff_x_b + diff_y_b * diff_x_a) / denom
            let lambda_b = circuit_add(
                circuit_mul(diff_y_a, diff_x_b), // diff_y_a * diff_x_b
                circuit_mul(diff_y_b, diff_x_a), // diff_y_b * diff_x_a
            );
            let lambda_b = circuit_mul(lambda_b, inv_denom); // Divide by denom
    
        //-------------------------------------
        // STEP 5: Circuit output
        //-------------------------------------
    
        // Prepare modulus and convert inputs
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    
        let fq0_x0 = from_u256(*self.x.c0.c0);
        let fq0_x1 = from_u256(*self.x.c1.c0);
        let fq0_y0 = from_u256(*self.y.c0.c0);
        let fq0_y1 = from_u256(*self.y.c1.c0);
    
        let fq1_x0 = from_u256(rhs.x.c0.c0);
        let fq1_x1 = from_u256(rhs.x.c1.c0);
        let fq1_y0 = from_u256(rhs.y.c0.c0);
        let fq1_y1 = from_u256(rhs.y.c1.c0);

    
        let outputs =
            match (lambda_a, lambda_b)
                .new_inputs()
                .next(fq0_x0)
                .next(fq0_x1)
                .next(fq0_y0)
                .next(fq0_y1)
                .next(fq1_x0)
                .next(fq1_x1)
                .next(fq1_y0)
                .next(fq1_y1)
                .done()
                .eval(modulus) {
                Result::Ok(outputs) => outputs,
                Result::Err(_) => panic!("Expected success"),
            };
    
        //-------------------------------------
        // STEP 6: Retrieve the final slope in Fq2
        //-------------------------------------
        Fq2 {
            c0: Fq {
                c0: outputs.get_output(lambda_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(lambda_b).try_into().unwrap(),
            },
        }
    }
    
    fn tangent(self: @Affine<Fq2>) -> Fq2 {
        /// Calculate the tangent (slope) at a point on the elliptic curve in Fq2.
        /// The tangent is defined as:
        /// λ = (3 * x^2 + a) / (2 * y), where `a` is the curve parameter.
        /// For simplicity, assume `a = 0` (e.g., BN curves).
    
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        let fq0_x0 = CircuitElement::<CircuitInput<0>> {}; // x.a
        let fq0_x1 = CircuitElement::<CircuitInput<1>> {}; // x.b

        let fq0_y0 = CircuitElement::<CircuitInput<2>> {}; // y.a
        let fq0_y1 = CircuitElement::<CircuitInput<3>> {}; // y.b
    
        //-------------------------------------
        // STEP 2: Calculate 3 * x^2
        //-------------------------------------
    
        // PART A: 3 * x.a^2 - x.b^2
        let x_sqr_a = circuit_sub(
            circuit_mul(fq0_x0, fq0_x0), // x.a^2
            circuit_mul(fq0_x1, fq0_x1), // x.b^2
        );
        let three_x_sqr_a = circuit_add(
            circuit_add(x_sqr_a, x_sqr_a), // 2 * x.a^2
            x_sqr_a,                       // + x.a^2
        );
    
        // PART B: 3 * 2 * x.a * x.b
        let x_sqr_b = circuit_add(
            circuit_mul(fq0_x0, fq0_x1), // x.a * x.b
            circuit_mul(fq0_x0, fq0_x1), // x.a * x.b (again)
        );
        let three_x_sqr_b = circuit_add(x_sqr_b, x_sqr_b);
    
        //-------------------------------------
        // STEP 3: Calculate 2 * y
        //-------------------------------------
    
        // PART A: 2 * y.a
        let two_y_a = circuit_add(fq0_y0, fq0_y0);
    
        // PART B: 2 * y.b
        let two_y_b = circuit_add(fq0_y1, fq0_y1);
    
        //-------------------------------------
        // STEP 4: Invert (2 * y)
        //-------------------------------------
    
        // Denominator = (2 * y.a)^2 + (2 * y.b)^2
        let denom = circuit_add(
            circuit_mul(two_y_a, two_y_a), // (2 * y.a)^2
            circuit_mul(two_y_b, two_y_b), // (2 * y.b)^2
        );
    
        let inv_denom_a = circuit_mul(two_y_a, circuit_inverse(denom));
        let inv_denom_b = circuit_mul(two_y_b, circuit_inverse(denom));
    
        //-------------------------------------
        // STEP 5: Calculate λ (tangent slope)
        //-------------------------------------
    
        // PART A: λ.a = (3 * x.a^2 - x.b^2) / (2 * y)
        let lambda_a = circuit_sub(
            circuit_mul(three_x_sqr_a, inv_denom_a),
            circuit_mul(three_x_sqr_b, inv_denom_b),
        );
    
        // PART B: λ.b = (3 * x.a * x.b) / (2 * y)
        let lambda_b = circuit_add(
            circuit_mul(three_x_sqr_a, inv_denom_b),
            circuit_mul(three_x_sqr_b, inv_denom_a),
        );
    
        //-------------------------------------
        // STEP 6: Circuit output
        //-------------------------------------
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    
        let fq0_x0 = from_u256(*self.x.c0.c0);
        let fq0_x1 = from_u256(*self.x.c1.c0);
        let fq0_y0 = from_u256(*self.y.c0.c0);
        let fq0_y1 = from_u256(*self.y.c1.c0);
    
        let outputs = match (lambda_a, lambda_b)
            .new_inputs()
            .next(fq0_x0)
            .next(fq0_x1)
            .next(fq0_y0)
            .next(fq0_y1)
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Expected success"),
        };
    
        //-------------------------------------
        // STEP 7: Retrieve the final slope (λ)
        //-------------------------------------
        Fq2 {
            c0: Fq {
                c0: outputs.get_output(lambda_a).try_into().unwrap(),
            },
            c1: Fq {
                c0: outputs.get_output(lambda_b).try_into().unwrap(),
            },
        }
    }

}


impl AffineOpsFq6Circuit of ECOperationsCircuitFq6 {

    // GOOD
    fn x_on_slope(self: @Affine<Fq6>, slope: Fq6, x2: Fq6) -> Fq6 {

        /// This function calculates the new x-coordinate (\(x_3\)) on the elliptic curve when given:
        /// - The slope of the line (\(\lambda\)) connecting two points or at the tangent of a single point.
        /// - The x-coordinate of the first point (\(x_1\)).
        /// - The x-coordinate of the second point (\(x_2\)).
        /// 
        /// The computation follows these steps:
        /// 1. Compute \(\lambda^2\) in the finite field \(Fq6\), which involves squaring each component of \(\lambda\).
        /// 2. Subtract \(x_1\) from \(\lambda^2\) to compute an intermediate result.
        /// 3. Subtract \(x_2\) from the intermediate result to calculate the final \(x_3\).
        /// 
        /// The result is represented in \(Fq6\), which is a finite field extension consisting of six components
        /// organized as three \(Fq2\) elements, each containing two \(Fq\) elements.


        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        let lambda_c0_0 = CircuitElement::<CircuitInput<0>> {}; // slope.c0.c0
        let lambda_c0_1 = CircuitElement::<CircuitInput<1>> {}; // slope.c0.c1
        let lambda_c1_0 = CircuitElement::<CircuitInput<2>> {}; // slope.c1.c0
        let lambda_c1_1 = CircuitElement::<CircuitInput<3>> {}; // slope.c1.c1
        let lambda_c2_0 = CircuitElement::<CircuitInput<4>> {}; // slope.c2.c0
        let lambda_c2_1 = CircuitElement::<CircuitInput<5>> {}; // slope.c2.c1
    
        let x1_c0_0 = CircuitElement::<CircuitInput<6>> {}; // x1.c0.c0
        let x1_c0_1 = CircuitElement::<CircuitInput<7>> {}; // x1.c0.c1
        let x1_c1_0 = CircuitElement::<CircuitInput<8>> {}; // x1.c1.c0
        let x1_c1_1 = CircuitElement::<CircuitInput<9>> {}; // x1.c1.c1
        let x1_c2_0 = CircuitElement::<CircuitInput<10>> {}; // x1.c2.c0
        let x1_c2_1 = CircuitElement::<CircuitInput<11>> {}; // x1.c2.c1
    
        let x2_c0_0 = CircuitElement::<CircuitInput<12>> {}; // x2.c0.c0
        let x2_c0_1 = CircuitElement::<CircuitInput<13>> {}; // x2.c0.c1
        let x2_c1_0 = CircuitElement::<CircuitInput<14>> {}; // x2.c1.c0
        let x2_c1_1 = CircuitElement::<CircuitInput<15>> {}; // x2.c1.c1
        let x2_c2_0 = CircuitElement::<CircuitInput<16>> {}; // x2.c2.c0
        let x2_c2_1 = CircuitElement::<CircuitInput<17>> {}; // x2.c2.c1
    
        //-------------------------------------
        // STEP 2: Square the slope λ in Fq6
        //-------------------------------------
        let lambda2_c0_0 = circuit_mul(lambda_c0_0, lambda_c0_0); // λ.c0.c0^2
        let lambda2_c0_1 = circuit_mul(lambda_c0_1, lambda_c0_1); // λ.c0.c1^2
        let lambda2_c1_0 = circuit_mul(lambda_c1_0, lambda_c1_0); // λ.c1.c0^2
        let lambda2_c1_1 = circuit_mul(lambda_c1_1, lambda_c1_1); // λ.c1.c1^2
        let lambda2_c2_0 = circuit_mul(lambda_c2_0, lambda_c2_0); // λ.c2.c0^2
        let lambda2_c2_1 = circuit_mul(lambda_c2_1, lambda_c2_1); // λ.c2.c1^2
    
        //-------------------------------------
        // STEP 3: Subtract x1 from λ²
        //-------------------------------------
        let intermediate_c0_0 = circuit_sub(lambda2_c0_0, x1_c0_0); // λ².c0.c0 - x1.c0.c0
        let intermediate_c0_1 = circuit_sub(lambda2_c0_1, x1_c0_1); // λ².c0.c1 - x1.c0.c1
        let intermediate_c1_0 = circuit_sub(lambda2_c1_0, x1_c1_0); // λ².c1.c0 - x1.c1.c0
        let intermediate_c1_1 = circuit_sub(lambda2_c1_1, x1_c1_1); // λ².c1.c1 - x1.c1.c1
        let intermediate_c2_0 = circuit_sub(lambda2_c2_0, x1_c2_0); // λ².c2.c0 - x1.c2.c0
        let intermediate_c2_1 = circuit_sub(lambda2_c2_1, x1_c2_1); // λ².c2.c1 - x1.c2.c1
    
        //-------------------------------------
        // STEP 4: Subtract x2 from the result
        //-------------------------------------
        let result_c0_0 = circuit_sub(intermediate_c0_0, x2_c0_0); // intermediate.c0.c0 - x2.c0.c0
        let result_c0_1 = circuit_sub(intermediate_c0_1, x2_c0_1); // intermediate.c0.c1 - x2.c0.c1
        let result_c1_0 = circuit_sub(intermediate_c1_0, x2_c1_0); // intermediate.c1.c0 - x2.c1.c0
        let result_c1_1 = circuit_sub(intermediate_c1_1, x2_c1_1); // intermediate.c1.c1 - x2.c1.c1
        let result_c2_0 = circuit_sub(intermediate_c2_0, x2_c2_0); // intermediate.c2.c0 - x2.c2.c0
        let result_c2_1 = circuit_sub(intermediate_c2_1, x2_c2_1); // intermediate.c2.c1 - x2.c2.c1
    
        //-------------------------------------
        // STEP 5: Circuit output
        //-------------------------------------
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        // Convert inputs to circuit elements
        let fq_self_x_c0_0 = from_u256(*self.x.c0.c0.c0);
        let fq_self_x_c0_1 = from_u256(*self.x.c0.c1.c0);
        let fq_self_x_c1_0 = from_u256(*self.x.c1.c0.c0);
        let fq_self_x_c1_1 = from_u256(*self.x.c1.c1.c0);
        let fq_self_x_c2_0 = from_u256(*self.x.c2.c0.c0);
        let fq_self_x_c2_1 = from_u256(*self.x.c2.c1.c0);

        let fq_slope_c0_0 = from_u256(slope.c0.c0.c0);
        let fq_slope_c0_1 = from_u256(slope.c0.c1.c0);
        let fq_slope_c1_0 = from_u256(slope.c1.c0.c0);
        let fq_slope_c1_1 = from_u256(slope.c1.c1.c0);
        let fq_slope_c2_0 = from_u256(slope.c2.c0.c0);
        let fq_slope_c2_1 = from_u256(slope.c2.c1.c0);

        let fq_x2_c0_0 = from_u256(x2.c0.c0.c0);
        let fq_x2_c0_1 = from_u256(x2.c0.c1.c0);
        let fq_x2_c1_0 = from_u256(x2.c1.c0.c0);
        let fq_x2_c1_1 = from_u256(x2.c1.c1.c0);
        let fq_x2_c2_0 = from_u256(x2.c2.c0.c0);
        let fq_x2_c2_1 = from_u256(x2.c2.c1.c0);

        // Evaluate circuit
        let outputs = match (
            result_c0_0, result_c0_1, 
            result_c1_0, result_c1_1, 
            result_c2_0, result_c2_1,
        )
            .new_inputs()
            .next(fq_self_x_c0_0)
            .next(fq_self_x_c0_1)
            .next(fq_self_x_c1_0)
            .next(fq_self_x_c1_1)
            .next(fq_self_x_c2_0)
            .next(fq_self_x_c2_1)
            .next(fq_slope_c0_0)
            .next(fq_slope_c0_1)
            .next(fq_slope_c1_0)
            .next(fq_slope_c1_1)
            .next(fq_slope_c2_0)
            .next(fq_slope_c2_1)
            .next(fq_x2_c0_0)
            .next(fq_x2_c0_1)
            .next(fq_x2_c1_0)
            .next(fq_x2_c1_1)
            .next(fq_x2_c2_0)
            .next(fq_x2_c2_1)
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Expected success"),
        };
    
        //-------------------------------------
        // STEP 6: Retrieve the final coordinates
        //-------------------------------------
        Fq6 {
            c0: Fq2 {
                c0: Fq {
                    c0: outputs.get_output(result_c0_0).try_into().unwrap(),
                },
                c1: Fq {
                    c0: outputs.get_output(result_c0_1).try_into().unwrap(),
                },
            },
            c1: Fq2 {
                c0: Fq {
                    c0: outputs.get_output(result_c1_0).try_into().unwrap(),
                },
                c1: Fq {
                    c0: outputs.get_output(result_c1_1).try_into().unwrap(),
                },
            },
            c2: Fq2 {
                c0: Fq {
                    c0: outputs.get_output(result_c2_0).try_into().unwrap(),
                },
                c1: Fq {
                    c0: outputs.get_output(result_c2_1).try_into().unwrap(),
                },
            },
        }
    }
    
    // GOOD
    fn y_on_slope(self: @Affine<Fq6>, slope: Fq6, x: Fq6) -> Fq6 {

        /// This function calculates the new y-coordinate (\(y_3\)) on the elliptic curve given:
        /// - The slope (\(\lambda\)) of the line connecting two points or tangent at a single point.
        /// - The x-coordinates (\(x_1\) and \(x_3\)) and the y-coordinate (\(y_1\)) of the initial point.
        ///
        /// The computation follows these steps:
        /// 1. Compute the difference \(x_1 - x_3\) in \(Fq6\), component-wise.
        /// 2. Compute \(\lambda \cdot (x_1 - x_3)\), involving multiplication and addition of components in \(Fq6\).
        /// 3. Subtract \(y_1\) from the result of step 2 to compute \(y_3\).
        /// 4. Output the result as an \(Fq6\) coordinate.

         //-------------------------------------
        // STEP 1: Extract components
        //-------------------------------------
        // Extract components of self (x1, y1)
        let x1_c0_0 = CircuitElement::<CircuitInput<0>> {}; // self.x.c0.c0
        let x1_c0_1 = CircuitElement::<CircuitInput<1>> {}; // self.x.c0.c1
        let x1_c1_0 = CircuitElement::<CircuitInput<2>> {}; // self.x.c1.c0
        let x1_c1_1 = CircuitElement::<CircuitInput<3>> {}; // self.x.c1.c1
        let x1_c2_0 = CircuitElement::<CircuitInput<4>> {}; // self.x.c2.c0
        let x1_c2_1 = CircuitElement::<CircuitInput<5>> {}; // self.x.c2.c1

        let y1_c0_0 = CircuitElement::<CircuitInput<6>> {}; // self.y.c0.c0
        let y1_c0_1 = CircuitElement::<CircuitInput<7>> {}; // self.y.c0.c1
        let y1_c1_0 = CircuitElement::<CircuitInput<8>> {}; // self.y.c1.c0
        let y1_c1_1 = CircuitElement::<CircuitInput<9>> {}; // self.y.c1.c1
        let y1_c2_0 = CircuitElement::<CircuitInput<10>> {}; // self.y.c2.c0
        let y1_c2_1 = CircuitElement::<CircuitInput<11>> {}; // self.y.c2.c1

        // Extract components of slope (λ)
        let lambda_c0_0 = CircuitElement::<CircuitInput<12>> {}; // slope.c0.c0
        let lambda_c0_1 = CircuitElement::<CircuitInput<13>> {}; // slope.c0.c1
        let lambda_c1_0 = CircuitElement::<CircuitInput<14>> {}; // slope.c1.c0
        let lambda_c1_1 = CircuitElement::<CircuitInput<15>> {}; // slope.c1.c1
        let lambda_c2_0 = CircuitElement::<CircuitInput<16>> {}; // slope.c2.c0
        let lambda_c2_1 = CircuitElement::<CircuitInput<17>> {}; // slope.c2.c1

        // Extract components of x3
        let x3_c0_0 = CircuitElement::<CircuitInput<18>> {}; // x.c0.c0
        let x3_c0_1 = CircuitElement::<CircuitInput<19>> {}; // x.c0.c1
        let x3_c1_0 = CircuitElement::<CircuitInput<20>> {}; // x.c1.c0
        let x3_c1_1 = CircuitElement::<CircuitInput<21>> {}; // x.c1.c1
        let x3_c2_0 = CircuitElement::<CircuitInput<22>> {}; // x.c2.c0
        let x3_c2_1 = CircuitElement::<CircuitInput<23>> {}; // x.c2.c1

        //-------------------------------------
        // STEP 2: Calculate x1 - x3
        //-------------------------------------
        let diff_x_c0_0 = circuit_sub(x1_c0_0, x3_c0_0);
        let diff_x_c0_1 = circuit_sub(x1_c0_1, x3_c0_1);
        let diff_x_c1_0 = circuit_sub(x1_c1_0, x3_c1_0);
        let diff_x_c1_1 = circuit_sub(x1_c1_1, x3_c1_1);
        let diff_x_c2_0 = circuit_sub(x1_c2_0, x3_c2_0);
        let diff_x_c2_1 = circuit_sub(x1_c2_1, x3_c2_1);

        //-------------------------------------
        // STEP 3: Calculate λ * (x1 - x3)
        //-------------------------------------
        let lambda_diff_c0_0 = circuit_sub(
            circuit_mul(lambda_c0_0, diff_x_c0_0),
            circuit_mul(lambda_c0_1, diff_x_c0_1),
        );
        let lambda_diff_c0_1 = circuit_add(
            circuit_mul(lambda_c0_0, diff_x_c0_1),
            circuit_mul(lambda_c0_1, diff_x_c0_0),
        );
        let lambda_diff_c1_0 = circuit_sub(
            circuit_mul(lambda_c1_0, diff_x_c1_0),
            circuit_mul(lambda_c1_1, diff_x_c1_1),
        );
        let lambda_diff_c1_1 = circuit_add(
            circuit_mul(lambda_c1_0, diff_x_c1_1),
            circuit_mul(lambda_c1_1, diff_x_c1_0),
        );
        let lambda_diff_c2_0 = circuit_sub(
            circuit_mul(lambda_c2_0, diff_x_c2_0),
            circuit_mul(lambda_c2_1, diff_x_c2_1),
        );
        let lambda_diff_c2_1 = circuit_add(
            circuit_mul(lambda_c2_0, diff_x_c2_1),
            circuit_mul(lambda_c2_1, diff_x_c2_0),
        );

        //-------------------------------------
        // STEP 4: Calculate y3 = λ * (x1 - x3) - y1
        //-------------------------------------
        let y3_c0_0 = circuit_sub(lambda_diff_c0_0, y1_c0_0);
        let y3_c0_1 = circuit_sub(lambda_diff_c0_1, y1_c0_1);
        let y3_c1_0 = circuit_sub(lambda_diff_c1_0, y1_c1_0);
        let y3_c1_1 = circuit_sub(lambda_diff_c1_1, y1_c1_1);
        let y3_c2_0 = circuit_sub(lambda_diff_c2_0, y1_c2_0);
        let y3_c2_1 = circuit_sub(lambda_diff_c2_1, y1_c2_1);

        //-------------------------------------
        // STEP 5: Circuit output and evaluation
        //-------------------------------------
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let outputs = match (y3_c0_0, y3_c0_1, y3_c1_0, y3_c1_1, y3_c2_0, y3_c2_1)
            .new_inputs()
            .next(from_u256(*self.x.c0.c0.c0))
            .next(from_u256(*self.x.c0.c1.c0))
            .next(from_u256(*self.x.c1.c0.c0))
            .next(from_u256(*self.x.c1.c1.c0))
            .next(from_u256(*self.x.c2.c0.c0))
            .next(from_u256(*self.x.c2.c1.c0))
            .next(from_u256(*self.y.c0.c0.c0))
            .next(from_u256(*self.y.c0.c1.c0))
            .next(from_u256(*self.y.c1.c0.c0))
            .next(from_u256(*self.y.c1.c1.c0))
            .next(from_u256(*self.y.c2.c0.c0))
            .next(from_u256(*self.y.c2.c1.c0))
            .next(from_u256(slope.c0.c0.c0))
            .next(from_u256(slope.c0.c1.c0))
            .next(from_u256(slope.c1.c0.c0))
            .next(from_u256(slope.c1.c1.c0))
            .next(from_u256(slope.c2.c0.c0))
            .next(from_u256(slope.c2.c1.c0))
            .next(from_u256(x.c0.c0.c0))
            .next(from_u256(x.c0.c1.c0))
            .next(from_u256(x.c1.c0.c0))
            .next(from_u256(x.c1.c1.c0))
            .next(from_u256(x.c2.c0.c0))
            .next(from_u256(x.c2.c1.c0))
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Expected success"),
        };

        //-------------------------------------
        // STEP 6: Retrieve the final y-coordinate
        //-------------------------------------
        Fq6 {
            c0: Fq2 {
                c0: Fq {
                    c0: outputs.get_output(y3_c0_0).try_into().unwrap(),
                },
                c1: Fq {
                    c0: outputs.get_output(y3_c0_1).try_into().unwrap(),
                },
            },
            c1: Fq2 {
                c0: Fq {
                    c0: outputs.get_output(y3_c1_0).try_into().unwrap(),
                },
                c1: Fq {
                    c0: outputs.get_output(y3_c1_1).try_into().unwrap(),
                },
            },
            c2: Fq2 {
                c0: Fq {
                    c0: outputs.get_output(y3_c2_0).try_into().unwrap(),
                },
                c1: Fq {
                    c0: outputs.get_output(y3_c2_1).try_into().unwrap(),
                },
            },
        }
    }

    // GOOD 
    fn pt_on_slope(self: @Affine<Fq6>, slope: Fq6, x2: Fq6) -> Affine<Fq6> {
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        // Extract components of `self` (x1, y1)
        let x1_c0_0 = CircuitElement::<CircuitInput<0>> {}; // self.x.c0.c0
        let x1_c0_1 = CircuitElement::<CircuitInput<1>> {}; // self.x.c0.c1
        let x1_c1_0 = CircuitElement::<CircuitInput<2>> {}; // self.x.c1.c0
        let x1_c1_1 = CircuitElement::<CircuitInput<3>> {}; // self.x.c1.c1
        let x1_c2_0 = CircuitElement::<CircuitInput<4>> {}; // self.x.c2.c0
        let x1_c2_1 = CircuitElement::<CircuitInput<5>> {}; // self.x.c2.c1

        let y1_c0_0 = CircuitElement::<CircuitInput<6>> {}; // self.y.c0.c0
        let y1_c0_1 = CircuitElement::<CircuitInput<7>> {}; // self.y.c0.c1
        let y1_c1_0 = CircuitElement::<CircuitInput<8>> {}; // self.y.c1.c0
        let y1_c1_1 = CircuitElement::<CircuitInput<9>> {}; // self.y.c1.c1
        let y1_c2_0 = CircuitElement::<CircuitInput<10>> {}; // self.y.c2.c0
        let y1_c2_1 = CircuitElement::<CircuitInput<11>> {}; // self.y.c2.c1

        // Extract components of `slope` (λ)
        let lambda_c0_0 = CircuitElement::<CircuitInput<12>> {}; // slope.c0.c0
        let lambda_c0_1 = CircuitElement::<CircuitInput<13>> {}; // slope.c0.c1
        let lambda_c1_0 = CircuitElement::<CircuitInput<14>> {}; // slope.c1.c0
        let lambda_c1_1 = CircuitElement::<CircuitInput<15>> {}; // slope.c1.c1
        let lambda_c2_0 = CircuitElement::<CircuitInput<16>> {}; // slope.c2.c0
        let lambda_c2_1 = CircuitElement::<CircuitInput<17>> {}; // slope.c2.c1

        // Extract components of `x2`
        let x2_c0_0 = CircuitElement::<CircuitInput<18>> {}; // x2.c0.c0
        let x2_c0_1 = CircuitElement::<CircuitInput<19>> {}; // x2.c0.c1
        let x2_c1_0 = CircuitElement::<CircuitInput<20>> {}; // x2.c1.c0
        let x2_c1_1 = CircuitElement::<CircuitInput<21>> {}; // x2.c1.c1
        let x2_c2_0 = CircuitElement::<CircuitInput<22>> {}; // x2.c2.c0
        let x2_c2_1 = CircuitElement::<CircuitInput<23>> {}; // x2.c2.c1

        //-------------------------------------
        // STEP 2: Calculate x3 = λ² - x1 - x2
        //-------------------------------------
        // Square the slope components
        let lambda_sqr_c0_0 = circuit_sub(
            circuit_mul(lambda_c0_0, lambda_c0_0), 
            circuit_mul(lambda_c0_1, lambda_c0_1),
        );
        let lambda_sqr_c0_1 = circuit_add(
            circuit_mul(lambda_c0_0, lambda_c0_1), 
            circuit_mul(lambda_c0_0, lambda_c0_1),
        );

        let lambda_sqr_c1_0 = circuit_sub(
            circuit_mul(lambda_c1_0, lambda_c1_0), 
            circuit_mul(lambda_c1_1, lambda_c1_1),
        );
        let lambda_sqr_c1_1 = circuit_add(
            circuit_mul(lambda_c1_0, lambda_c1_1), 
            circuit_mul(lambda_c1_0, lambda_c1_1),
        );

        let lambda_sqr_c2_0 = circuit_sub(
            circuit_mul(lambda_c2_0, lambda_c2_0), 
            circuit_mul(lambda_c2_1, lambda_c2_1),
        );
        let lambda_sqr_c2_1 = circuit_add(
            circuit_mul(lambda_c2_0, lambda_c2_1), 
            circuit_mul(lambda_c2_0, lambda_c2_1),
        );

        // Subtract \(x1\) and \(x2\) from \(\lambda^2\)
        let x3_c0_0 = circuit_sub(circuit_sub(lambda_sqr_c0_0, x1_c0_0), x2_c0_0);
        let x3_c0_1 = circuit_sub(circuit_sub(lambda_sqr_c0_1, x1_c0_1), x2_c0_1);
        let x3_c1_0 = circuit_sub(circuit_sub(lambda_sqr_c1_0, x1_c1_0), x2_c1_0);
        let x3_c1_1 = circuit_sub(circuit_sub(lambda_sqr_c1_1, x1_c1_1), x2_c1_1);
        let x3_c2_0 = circuit_sub(circuit_sub(lambda_sqr_c2_0, x1_c2_0), x2_c2_0);
        let x3_c2_1 = circuit_sub(circuit_sub(lambda_sqr_c2_1, x1_c2_1), x2_c2_1);

        //-------------------------------------
        // STEP 3: Calculate y3 = λ * (x1 - x3) - y1
        //-------------------------------------
        // Compute \(x1 - x3\)
        let diff_x_c0_0 = circuit_sub(x1_c0_0, x3_c0_0);
        let diff_x_c0_1 = circuit_sub(x1_c0_1, x3_c0_1);
        let diff_x_c1_0 = circuit_sub(x1_c1_0, x3_c1_0);
        let diff_x_c1_1 = circuit_sub(x1_c1_1, x3_c1_1);
        let diff_x_c2_0 = circuit_sub(x1_c2_0, x3_c2_0);
        let diff_x_c2_1 = circuit_sub(x1_c2_1, x3_c2_1);

        // Multiply λ by \(x1 - x3\) and subtract \(y1\)
        let y3_c0_0 = circuit_sub(
            circuit_mul(lambda_c0_0, diff_x_c0_0),
            y1_c0_0,
        );
        let y3_c0_1 = circuit_sub(
            circuit_mul(lambda_c0_1, diff_x_c0_1),
            y1_c0_1,
        );
        let y3_c1_0 = circuit_sub(
            circuit_mul(lambda_c1_0, diff_x_c1_0),
            y1_c1_0,
        );
        let y3_c1_1 = circuit_sub(
            circuit_mul(lambda_c1_1, diff_x_c1_1),
            y1_c1_1,
        );
        let y3_c2_0 = circuit_sub(
            circuit_mul(lambda_c2_0, diff_x_c2_0),
            y1_c2_0,
        );
        let y3_c2_1 = circuit_sub(
            circuit_mul(lambda_c2_1, diff_x_c2_1),
            y1_c2_1,
        );

        //-------------------------------------
        // STEP 4: Circuit output and retrieval
        //-------------------------------------
        // Prepare modulus and convert inputs
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        // Convert `self.x` components to circuit inputs
        let fq0_x0_c0 = from_u256(*self.x.c0.c0.c0);
        let fq0_x1_c0 = from_u256(*self.x.c0.c1.c0);
        let fq0_x0_c1 = from_u256(*self.x.c1.c0.c0);
        let fq0_x1_c1 = from_u256(*self.x.c1.c1.c0);
        let fq0_x0_c2 = from_u256(*self.x.c2.c0.c0);
        let fq0_x1_c2 = from_u256(*self.x.c2.c1.c0);

        // Convert `self.y` components to circuit inputs
        let fq0_y0_c0 = from_u256(*self.y.c0.c0.c0);
        let fq0_y1_c0 = from_u256(*self.y.c0.c1.c0);
        let fq0_y0_c1 = from_u256(*self.y.c1.c0.c0);
        let fq0_y1_c1 = from_u256(*self.y.c1.c1.c0);
        let fq0_y0_c2 = from_u256(*self.y.c2.c0.c0);
        let fq0_y1_c2 = from_u256(*self.y.c2.c1.c0);

        // Convert `x2` components to circuit inputs
        let fq1_x0_c0 = from_u256(x2.c0.c0.c0);
        let fq1_x1_c0 = from_u256(x2.c0.c1.c0);
        let fq1_x0_c1 = from_u256(x2.c1.c0.c0);
        let fq1_x1_c1 = from_u256(x2.c1.c1.c0);
        let fq1_x0_c2 = from_u256(x2.c2.c0.c0);
        let fq1_x1_c2 = from_u256(x2.c2.c1.c0);

        // Convert `slope` (λ) components to circuit inputs
        let slope_a_c0 = from_u256(slope.c0.c0.c0);
        let slope_b_c0 = from_u256(slope.c0.c1.c0);
        let slope_a_c1 = from_u256(slope.c1.c0.c0);
        let slope_b_c1 = from_u256(slope.c1.c1.c0);
        let slope_a_c2 = from_u256(slope.c2.c0.c0);
        let slope_b_c2 = from_u256(slope.c2.c1.c0);

        // Evaluate circuit
        let outputs = match (x3_c0_0, x3_c0_1, x3_c1_0, x3_c1_1, x3_c2_0, x3_c2_1,
                            y3_c0_0, y3_c0_1, y3_c1_0, y3_c1_1, y3_c2_0, y3_c2_1)
            .new_inputs()
            .next(fq0_x0_c0).next(fq0_x1_c0).next(fq0_x0_c1).next(fq0_x1_c1).next(fq0_x0_c2).next(fq0_x1_c2) // Inputs for `self.x`
            .next(fq0_y0_c0).next(fq0_y1_c0).next(fq0_y0_c1).next(fq0_y1_c1).next(fq0_y0_c2).next(fq0_y1_c2) // Inputs for `self.y`
            .next(fq1_x0_c0).next(fq1_x1_c0).next(fq1_x0_c1).next(fq1_x1_c1).next(fq1_x0_c2).next(fq1_x1_c2) // Inputs for `x2`
            .next(slope_a_c0).next(slope_b_c0).next(slope_a_c1).next(slope_b_c1).next(slope_a_c2).next(slope_b_c2) // Inputs for slope (λ)
            .done()
            .eval(modulus) {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Evaluation failed"),
        };

        // Match outputs to corresponding variables
        Affine {
            x: Fq6 {
                c0: Fq2 {
                    c0: Fq { c0: outputs.get_output(x3_c0_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(x3_c0_1).try_into().unwrap() },
                },
                c1: Fq2 {
                    c0: Fq { c0: outputs.get_output(x3_c1_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(x3_c1_1).try_into().unwrap() },
                },
                c2: Fq2 {
                    c0: Fq { c0: outputs.get_output(x3_c2_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(x3_c2_1).try_into().unwrap() },
                },
            },
            y: Fq6 {
                c0: Fq2 {
                    c0: Fq { c0: outputs.get_output(y3_c0_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(y3_c0_1).try_into().unwrap() },
                },
                c1: Fq2 {
                    c0: Fq { c0: outputs.get_output(y3_c1_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(y3_c1_1).try_into().unwrap() },
                },
                c2: Fq2 {
                    c0: Fq { c0: outputs.get_output(y3_c2_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(y3_c2_1).try_into().unwrap() },
                },
            },
        }
    }

    // MAAY PROBLEEEEEEEEM IN CHOR 
    fn chord(self: @Affine<Fq6>, rhs: Affine<Fq6>) -> Fq6 {
        /// Compute the slope (λ) of the line passing through two points in Fq6.
        ///
        /// Formula:
        /// λ = (y2 - y1) / (x2 - x1)
        ///
        /// This function calculates the slope by:
        /// 1. Computing the numerator (difference in y-coordinates: y2 - y1).
        /// 2. Computing the denominator (difference in x-coordinates: x2 - x1).
        /// 3. Calculating λ as the quotient of the numerator and denominator in Fq6.
    
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        // Components of the y-coordinates
        let y1_c0_0 = CircuitElement::<CircuitInput<0>> {}; // self.y.c0.c0
        let y1_c0_1 = CircuitElement::<CircuitInput<1>> {}; // self.y.c0.c1
        let y1_c1_0 = CircuitElement::<CircuitInput<2>> {}; // self.y.c1.c0
        let y1_c1_1 = CircuitElement::<CircuitInput<3>> {}; // self.y.c1.c1
        let y1_c2_0 = CircuitElement::<CircuitInput<4>> {}; // self.y.c2.c0
        let y1_c2_1 = CircuitElement::<CircuitInput<5>> {}; // self.y.c2.c1
    
        let y2_c0_0 = CircuitElement::<CircuitInput<6>> {}; // rhs.y.c0.c0
        let y2_c0_1 = CircuitElement::<CircuitInput<7>> {}; // rhs.y.c0.c1
        let y2_c1_0 = CircuitElement::<CircuitInput<8>> {}; // rhs.y.c1.c0
        let y2_c1_1 = CircuitElement::<CircuitInput<9>> {}; // rhs.y.c1.c1
        let y2_c2_0 = CircuitElement::<CircuitInput<10>> {}; // rhs.y.c2.c0
        let y2_c2_1 = CircuitElement::<CircuitInput<11>> {}; // rhs.y.c2.c1
    
        // Components of the x-coordinates
        let x1_c0_0 = CircuitElement::<CircuitInput<12>> {}; // self.x.c0.c0
        let x1_c0_1 = CircuitElement::<CircuitInput<13>> {}; // self.x.c0.c1
        let x1_c1_0 = CircuitElement::<CircuitInput<14>> {}; // self.x.c1.c0
        let x1_c1_1 = CircuitElement::<CircuitInput<15>> {}; // self.x.c1.c1
        let x1_c2_0 = CircuitElement::<CircuitInput<16>> {}; // self.x.c2.c0
        let x1_c2_1 = CircuitElement::<CircuitInput<17>> {}; // self.x.c2.c1
    
        let x2_c0_0 = CircuitElement::<CircuitInput<18>> {}; // rhs.x.c0.c0
        let x2_c0_1 = CircuitElement::<CircuitInput<19>> {}; // rhs.x.c0.c1
        let x2_c1_0 = CircuitElement::<CircuitInput<20>> {}; // rhs.x.c1.c0
        let x2_c1_1 = CircuitElement::<CircuitInput<21>> {}; // rhs.x.c1.c1
        let x2_c2_0 = CircuitElement::<CircuitInput<22>> {}; // rhs.x.c2.c0
        let x2_c2_1 = CircuitElement::<CircuitInput<23>> {}; // rhs.x.c2.c1
    
        //-------------------------------------
        // STEP 2: Compute the numerator (y2 - y1)
        //-------------------------------------
        let num_c0_0 = circuit_sub(y2_c0_0, y1_c0_0);
        let num_c0_1 = circuit_sub(y2_c0_1, y1_c0_1);
        let num_c1_0 = circuit_sub(y2_c1_0, y1_c1_0);
        let num_c1_1 = circuit_sub(y2_c1_1, y1_c1_1);
        let num_c2_0 = circuit_sub(y2_c2_0, y1_c2_0);
        let num_c2_1 = circuit_sub(y2_c2_1, y1_c2_1);
    
        //-------------------------------------
        // STEP 3: Compute the denominator (x2 - x1)
        //-------------------------------------
        let den_c0_0 = circuit_sub(x2_c0_0, x1_c0_0);
        let den_c1_0 = circuit_sub(x2_c1_0, x1_c1_0);
        let den_c2_0 = circuit_sub(x2_c2_0, x1_c2_0);

    
        //-------------------------------------
        // STEP 4: Compute the inverse of the denominator
        //-------------------------------------
        // Only the c0 components of the denominator are actually used
        let denom_inv_c0 = circuit_inverse(den_c0_0);
        let denom_inv_c1 = circuit_inverse(den_c1_0);
        let denom_inv_c2 = circuit_inverse(den_c2_0);
    
        //-------------------------------------
        // STEP 5: Calculate λ = numerator / denominator
        //-------------------------------------
        let lambda_c0_0 = circuit_mul(num_c0_0, denom_inv_c0);
        let lambda_c0_1 = circuit_mul(num_c0_1, denom_inv_c0); // Use denom_inv_c0 to match prior logic
        let lambda_c1_0 = circuit_mul(num_c1_0, denom_inv_c1);
        let lambda_c1_1 = circuit_mul(num_c1_1, denom_inv_c1);
        let lambda_c2_0 = circuit_mul(num_c2_0, denom_inv_c2);
        let lambda_c2_1 = circuit_mul(num_c2_1, denom_inv_c2);
    
        //-------------------------------------
        // STEP 6: Circuit output
        //-------------------------------------
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    
        let outputs = match (
            lambda_c0_0, lambda_c0_1, 
            lambda_c1_0, lambda_c1_1, 
            lambda_c2_0, lambda_c2_1,
        )
            .new_inputs()
            .next(from_u256(*self.y.c0.c0.c0)).next(from_u256(*self.y.c0.c1.c0))
            .next(from_u256(*self.y.c1.c0.c0)).next(from_u256(*self.y.c1.c1.c0))
            .next(from_u256(*self.y.c2.c0.c0)).next(from_u256(*self.y.c2.c1.c0))
            .next(from_u256(rhs.y.c0.c0.c0)).next(from_u256(rhs.y.c0.c1.c0))
            .next(from_u256(rhs.y.c1.c0.c0)).next(from_u256(rhs.y.c1.c1.c0))
            .next(from_u256(rhs.y.c2.c0.c0)).next(from_u256(rhs.y.c2.c1.c0))
            .next(from_u256(*self.x.c0.c0.c0)).next(from_u256(*self.x.c0.c1.c0))
            .next(from_u256(*self.x.c1.c0.c0)).next(from_u256(*self.x.c1.c1.c0))
            .next(from_u256(*self.x.c2.c0.c0)).next(from_u256(*self.x.c2.c1.c0))
            .next(from_u256(rhs.x.c0.c0.c0)).next(from_u256(rhs.x.c0.c1.c0))
            .next(from_u256(rhs.x.c1.c0.c0)).next(from_u256(rhs.x.c1.c1.c0))
            .next(from_u256(rhs.x.c2.c0.c0)).next(from_u256(rhs.x.c2.c1.c0))
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Evaluation failed"),
        };
    
        //-------------------------------------
        // STEP 7: Retrieve the final slope (λ) in Fq6
        //-------------------------------------
        Fq6 {
            c0: Fq2 {
                c0: Fq { c0: outputs.get_output(lambda_c0_0).try_into().unwrap() },
                c1: Fq { c0: outputs.get_output(lambda_c0_1).try_into().unwrap() },
            },
            c1: Fq2 {
                c0: Fq { c0: outputs.get_output(lambda_c1_0).try_into().unwrap() },
                c1: Fq { c0: outputs.get_output(lambda_c1_1).try_into().unwrap() },
            },
            c2: Fq2 {
                c0: Fq { c0: outputs.get_output(lambda_c2_0).try_into().unwrap() },
                c1: Fq { c0: outputs.get_output(lambda_c2_1).try_into().unwrap() },
            },
        }
    }
    
    // REVIEW THE DENOMINATOR
    fn add_as_circuit(self: @Affine<Fq6>, rhs: Affine<Fq6>) -> Affine<Fq6> {
        /// Adds two points on an elliptic curve in Fq6 using a circuit.
        /// This operation involves the following steps:
        /// 1. Compute the slope (\( \lambda \)) of the line connecting the two points:
        ///    - The numerator is the difference in y-coordinates (\( y2 - y1 \)).
        ///    - The denominator is the difference in x-coordinates (\( x2 - x1 \)).
        ///    - The slope is obtained by dividing the numerator by the denominator using circuit operations.
        /// 2. Compute the new x-coordinate (\( x3 \)):
        ///    - Square the slope (\( \lambda^2 \)) and subtract the x-coordinates of the two points.
        /// 3. Compute the new y-coordinate (\( y3 \)):
        ///    - Multiply the slope (\( \lambda \)) by the difference between the first x-coordinate and \( x3 \),
        ///      and subtract the first y-coordinate.
        /// 4. Return the resulting point (\( x3, y3 \)) as the sum of the two input points.
        /// All operations are implemented in the context of Fq6, considering real and imaginary components.

            
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        let x1_c0_0 = CircuitElement::<CircuitInput<0>> {}; // x1.c0.c0
        let x1_c0_1 = CircuitElement::<CircuitInput<1>> {}; // x1.c0.c1
        let x1_c1_0 = CircuitElement::<CircuitInput<2>> {}; // x1.c1.c0
        let x1_c1_1 = CircuitElement::<CircuitInput<3>> {}; // x1.c1.c1
        let x1_c2_0 = CircuitElement::<CircuitInput<4>> {}; // x1.c2.c0
        let x1_c2_1 = CircuitElement::<CircuitInput<5>> {}; // x1.c2.c1

        let y1_c0_0 = CircuitElement::<CircuitInput<6>> {}; // y1.c0.c0
        let y1_c0_1 = CircuitElement::<CircuitInput<7>> {}; // y1.c0.c1
        let y1_c1_0 = CircuitElement::<CircuitInput<8>> {}; // y1.c1.c0
        let y1_c1_1 = CircuitElement::<CircuitInput<9>> {}; // y1.c1.c1
        let y1_c2_0 = CircuitElement::<CircuitInput<10>> {}; // y1.c2.c0
        let y1_c2_1 = CircuitElement::<CircuitInput<11>> {}; // y1.c2.c1

        // Input wires for components of `rhs` (x2, y2)
        let x2_c0_0 = CircuitElement::<CircuitInput<12>> {}; // x2.c0.c0
        let x2_c0_1 = CircuitElement::<CircuitInput<13>> {}; // x2.c0.c1
        let x2_c1_0 = CircuitElement::<CircuitInput<14>> {}; // x2.c1.c0
        let x2_c1_1 = CircuitElement::<CircuitInput<15>> {}; // x2.c1.c1
        let x2_c2_0 = CircuitElement::<CircuitInput<16>> {}; // x2.c2.c0
        let x2_c2_1 = CircuitElement::<CircuitInput<17>> {}; // x2.c2.c1

        let y2_c0_0 = CircuitElement::<CircuitInput<18>> {}; // y2.c0.c0
        let y2_c0_1 = CircuitElement::<CircuitInput<19>> {}; // y2.c0.c1
        let y2_c1_0 = CircuitElement::<CircuitInput<20>> {}; // y2.c1.c0
        let y2_c1_1 = CircuitElement::<CircuitInput<21>> {}; // y2.c1.c1
        let y2_c2_0 = CircuitElement::<CircuitInput<22>> {}; // y2.c2.c0
        let y2_c2_1 = CircuitElement::<CircuitInput<23>> {}; // y2.c2.c1

        //-------------------------------------
        // STEP 2: Compute the slope (λ)
        //-------------------------------------
        // λ = (y2 - y1) / (x2 - x1)

        // Compute y2 - y1 (numerator) component-wise
        let lambda_num_c0_0 = circuit_sub(y2_c0_0, y1_c0_0);
        let lambda_num_c0_1 = circuit_sub(y2_c0_1, y1_c0_1);
        let lambda_num_c1_0 = circuit_sub(y2_c1_0, y1_c1_0);
        let lambda_num_c1_1 = circuit_sub(y2_c1_1, y1_c1_1);
        let lambda_num_c2_0 = circuit_sub(y2_c2_0, y1_c2_0);
        let lambda_num_c2_1 = circuit_sub(y2_c2_1, y1_c2_1);

        // Compute x2 - x1 (denominator) component-wise
        let lambda_den_c0_0 = circuit_sub(x2_c0_0, x1_c0_0);
        let lambda_den_c1_0 = circuit_sub(x2_c1_0, x1_c1_0);
        let lambda_den_c2_0 = circuit_sub(x2_c2_0, x1_c2_0);

        // Compute the inverse of x2 - x1 (denominator)
        let inv_lambda_den_c0 = circuit_inverse(lambda_den_c0_0);
        let inv_lambda_den_c1 = circuit_inverse(lambda_den_c1_0);
        let inv_lambda_den_c2 = circuit_inverse(lambda_den_c2_0);

        // Multiply (y2 - y1) by the inverse of x2 - x1 to calculate λ
        let lambda_c0_0 = circuit_mul(lambda_num_c0_0, inv_lambda_den_c0);
        let lambda_c0_1 = circuit_mul(lambda_num_c0_1, inv_lambda_den_c0);
        let lambda_c1_0 = circuit_mul(lambda_num_c1_0, inv_lambda_den_c1);
        let lambda_c1_1 = circuit_mul(lambda_num_c1_1, inv_lambda_den_c1);
        let lambda_c2_0 = circuit_mul(lambda_num_c2_0, inv_lambda_den_c2);
        let lambda_c2_1 = circuit_mul(lambda_num_c2_1, inv_lambda_den_c2);

        //-------------------------------------
        // STEP 3: Compute x3
        //-------------------------------------
        // x3 = λ^2 - x1 - x2

        // Compute λ^2 component-wise in Fq6
        let lambda_squared_c0_0 = circuit_mul(lambda_c0_0, lambda_c0_0);
        let lambda_squared_c0_1 = circuit_mul(lambda_c0_1, lambda_c0_1);
        let lambda_squared_c1_0 = circuit_mul(lambda_c1_0, lambda_c1_0);
        let lambda_squared_c1_1 = circuit_mul(lambda_c1_1, lambda_c1_1);
        let lambda_squared_c2_0 = circuit_mul(lambda_c2_0, lambda_c2_0);
        let lambda_squared_c2_1 = circuit_mul(lambda_c2_1, lambda_c2_1);

        // Subtract x1 and x2 component-wise from λ^2 to compute x3
        let x3_c0_0 = circuit_sub(circuit_sub(lambda_squared_c0_0, x1_c0_0), x2_c0_0);
        let x3_c0_1 = circuit_sub(circuit_sub(lambda_squared_c0_1, x1_c0_1), x2_c0_1);
        let x3_c1_0 = circuit_sub(circuit_sub(lambda_squared_c1_0, x1_c1_0), x2_c1_0);
        let x3_c1_1 = circuit_sub(circuit_sub(lambda_squared_c1_1, x1_c1_1), x2_c1_1);
        let x3_c2_0 = circuit_sub(circuit_sub(lambda_squared_c2_0, x1_c2_0), x2_c2_0);
        let x3_c2_1 = circuit_sub(circuit_sub(lambda_squared_c2_1, x1_c2_1), x2_c2_1);

        //-------------------------------------
        // STEP 4: Compute y3
        //-------------------------------------
        // y3 = λ * (x1 - x3) - y1

        // Compute x1 - x3 component-wise
        let x1_minus_x3_c0_0 = circuit_sub(x1_c0_0, x3_c0_0);
        let x1_minus_x3_c0_1 = circuit_sub(x1_c0_1, x3_c0_1);
        let x1_minus_x3_c1_0 = circuit_sub(x1_c1_0, x3_c1_0);
        let x1_minus_x3_c1_1 = circuit_sub(x1_c1_1, x3_c1_1);
        let x1_minus_x3_c2_0 = circuit_sub(x1_c2_0, x3_c2_0);
        let x1_minus_x3_c2_1 = circuit_sub(x1_c2_1, x3_c2_1);

        // Multiply λ by (x1 - x3) component-wise
        let lambda_times_x1_minus_x3_c0_0 = circuit_mul(lambda_c0_0, x1_minus_x3_c0_0);
        let lambda_times_x1_minus_x3_c0_1 = circuit_mul(lambda_c0_1, x1_minus_x3_c0_1);
        let lambda_times_x1_minus_x3_c1_0 = circuit_mul(lambda_c1_0, x1_minus_x3_c1_0);
        let lambda_times_x1_minus_x3_c1_1 = circuit_mul(lambda_c1_1, x1_minus_x3_c1_1);
        let lambda_times_x1_minus_x3_c2_0 = circuit_mul(lambda_c2_0, x1_minus_x3_c2_0);
        let lambda_times_x1_minus_x3_c2_1 = circuit_mul(lambda_c2_1, x1_minus_x3_c2_1);

        // Subtract y1 component-wise to compute y3
        let y3_c0_0 = circuit_sub(lambda_times_x1_minus_x3_c0_0, y1_c0_0);
        let y3_c0_1 = circuit_sub(lambda_times_x1_minus_x3_c0_1, y1_c0_1);
        let y3_c1_0 = circuit_sub(lambda_times_x1_minus_x3_c1_0, y1_c1_0);
        let y3_c1_1 = circuit_sub(lambda_times_x1_minus_x3_c1_1, y1_c1_1);
        let y3_c2_0 = circuit_sub(lambda_times_x1_minus_x3_c2_0, y1_c2_0);
        let y3_c2_1 = circuit_sub(lambda_times_x1_minus_x3_c2_1, y1_c2_1);


        //-------------------------------------
        // STEP 5: Circuit output
        //-------------------------------------
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let outputs = match (
            x3_c0_0, x3_c0_1, x3_c1_0, x3_c1_1, x3_c2_0, x3_c2_1, 
            y3_c0_0, y3_c0_1, y3_c1_0, y3_c1_1, y3_c2_0, y3_c2_1
        )
            .new_inputs()
            .next(from_u256(*self.x.c0.c0.c0))
            .next(from_u256(*self.x.c0.c1.c0))
            .next(from_u256(*self.x.c1.c0.c0))
            .next(from_u256(*self.x.c1.c1.c0))
            .next(from_u256(*self.x.c2.c0.c0))
            .next(from_u256(*self.x.c2.c1.c0))
            .next(from_u256(*self.y.c0.c0.c0))
            .next(from_u256(*self.y.c0.c1.c0))
            .next(from_u256(*self.y.c1.c0.c0))
            .next(from_u256(*self.y.c1.c1.c0))
            .next(from_u256(*self.y.c2.c0.c0))
            .next(from_u256(*self.y.c2.c1.c0))
            .next(from_u256(rhs.x.c0.c0.c0))
            .next(from_u256(rhs.x.c0.c1.c0))
            .next(from_u256(rhs.x.c1.c0.c0))
            .next(from_u256(rhs.x.c1.c1.c0))
            .next(from_u256(rhs.x.c2.c0.c0))
            .next(from_u256(rhs.x.c2.c1.c0))
            .next(from_u256(rhs.y.c0.c0.c0))
            .next(from_u256(rhs.y.c0.c1.c0))
            .next(from_u256(rhs.y.c1.c0.c0))
            .next(from_u256(rhs.y.c1.c1.c0))
            .next(from_u256(rhs.y.c2.c0.c0))
            .next(from_u256(rhs.y.c2.c1.c0))
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Evaluation failed"),
        };


        //-------------------------------------
        // STEP 6: Retrieve the final coordinates
        //-------------------------------------
        Affine {
            x: Fq6 {
                c0: Fq2 {
                    c0: Fq { c0: outputs.get_output(x3_c0_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(x3_c0_1).try_into().unwrap() },
                },
                c1: Fq2 {
                    c0: Fq { c0: outputs.get_output(x3_c1_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(x3_c1_1).try_into().unwrap() },
                },
                c2: Fq2 {
                    c0: Fq { c0: outputs.get_output(x3_c2_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(x3_c2_1).try_into().unwrap() },
                },
            },
            y: Fq6 {
                c0: Fq2 {
                    c0: Fq { c0: outputs.get_output(y3_c0_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(y3_c0_1).try_into().unwrap() },
                },
                c1: Fq2 {
                    c0: Fq { c0: outputs.get_output(y3_c1_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(y3_c1_1).try_into().unwrap() },
                },
                c2: Fq2 {
                    c0: Fq { c0: outputs.get_output(y3_c2_0).try_into().unwrap() },
                    c1: Fq { c0: outputs.get_output(y3_c2_1).try_into().unwrap() },
                },
            },
        }
    
    }


    //GOOD  
    fn tangent(self: @Affine<Fq6>) -> Fq6 {
        /// Calculate the tangent (slope) of the curve at the given point in Fq6.
        ///
        /// Formula:
        /// \[
        /// \lambda = \frac{3 \cdot x^2}{2 \cdot y}
        /// \]
        /// where:
        /// - \( x \) and \( y \) are components of the point in \( Fq6 \).
        ///
        /// Steps:
        /// 1. Compute \( 3 \cdot x^2 \) as the numerator.
        /// 2. Compute \( 2 \cdot y \) as the denominator.
        /// 3. Compute the inverse of the denominator and multiply it by the numerator.
        /// 4. Return the result \( \lambda \) as an \( Fq6 \) element.
    
        //-------------------------------------
        // STEP 1: Input elements
        //-------------------------------------
        // x components (self.x)
        let x_c0_0 = CircuitElement::<CircuitInput<0>> {}; // x.c0.c0
        let x_c0_1 = CircuitElement::<CircuitInput<1>> {}; // x.c0.c1
        let x_c1_0 = CircuitElement::<CircuitInput<2>> {}; // x.c1.c0
        let x_c1_1 = CircuitElement::<CircuitInput<3>> {}; // x.c1.c1
        let x_c2_0 = CircuitElement::<CircuitInput<4>> {}; // x.c2.c0
        let x_c2_1 = CircuitElement::<CircuitInput<5>> {}; // x.c2.c1
    
        // y components (self.y)
        let y_c0_0 = CircuitElement::<CircuitInput<6>> {}; // y.c0.c0
        let y_c0_1 = CircuitElement::<CircuitInput<7>> {}; // y.c0.c1
        let y_c1_0 = CircuitElement::<CircuitInput<8>> {}; // y.c1.c0
        let y_c1_1 = CircuitElement::<CircuitInput<9>> {}; // y.c1.c1
        let y_c2_0 = CircuitElement::<CircuitInput<10>> {}; // y.c2.c0
        let y_c2_1 = CircuitElement::<CircuitInput<11>> {}; // y.c2.c1
    
        //-------------------------------------
        // STEP 2: Compute \( 3 \cdot x^2 \) (numerator)
        //-------------------------------------
        // Compute \( x^2 \) component-wise
        let x_squared_c0_0 = circuit_mul(x_c0_0, x_c0_0);
        let x_squared_c0_1 = circuit_mul(x_c0_1, x_c0_1);
        let x_squared_c1_0 = circuit_mul(x_c1_0, x_c1_0);
        let x_squared_c1_1 = circuit_mul(x_c1_1, x_c1_1);
        let x_squared_c2_0 = circuit_mul(x_c2_0, x_c2_0);
        let x_squared_c2_1 = circuit_mul(x_c2_1, x_c2_1);
    
        // Multiply by 3 (using addition: \( 3 \cdot a = a + a + a \))
        let num_c0_0 = circuit_add(circuit_add(x_squared_c0_0, x_squared_c0_0), x_squared_c0_0);
        let num_c0_1 = circuit_add(circuit_add(x_squared_c0_1, x_squared_c0_1), x_squared_c0_1);
        let num_c1_0 = circuit_add(circuit_add(x_squared_c1_0, x_squared_c1_0), x_squared_c1_0);
        let num_c1_1 = circuit_add(circuit_add(x_squared_c1_1, x_squared_c1_1), x_squared_c1_1);
        let num_c2_0 = circuit_add(circuit_add(x_squared_c2_0, x_squared_c2_0), x_squared_c2_0);
        let num_c2_1 = circuit_add(circuit_add(x_squared_c2_1, x_squared_c2_1), x_squared_c2_1);
    
        //-------------------------------------
        // STEP 3: Compute \( 2 \cdot y \) (denominator)
        //-------------------------------------
        // Multiply \( y \) by 2 (using addition: \( 2 \cdot a = a + a \))
        let den_c0_0 = circuit_add(y_c0_0, y_c0_0);
        let den_c0_1 = circuit_add(y_c0_1, y_c0_1);
        let den_c1_0 = circuit_add(y_c1_0, y_c1_0);
        let den_c1_1 = circuit_add(y_c1_1, y_c1_1);
        let den_c2_0 = circuit_add(y_c2_0, y_c2_0);
        let den_c2_1 = circuit_add(y_c2_1, y_c2_1);
    
        //-------------------------------------
        // STEP 4: Compute the inverse of the denominator
        //-------------------------------------
        let inv_den_c0_0 = circuit_inverse(den_c0_0);
        let inv_den_c0_1 = circuit_inverse(den_c0_1);
        let inv_den_c1_0 = circuit_inverse(den_c1_0);
        let inv_den_c1_1 = circuit_inverse(den_c1_1);
        let inv_den_c2_0 = circuit_inverse(den_c2_0);
        let inv_den_c2_1 = circuit_inverse(den_c2_1);
    
        //-------------------------------------
        // STEP 5: Compute \( \lambda = numerator / denominator \)
        //-------------------------------------
        let lambda_c0_0 = circuit_mul(num_c0_0, inv_den_c0_0);
        let lambda_c0_1 = circuit_mul(num_c0_1, inv_den_c0_1);
        let lambda_c1_0 = circuit_mul(num_c1_0, inv_den_c1_0);
        let lambda_c1_1 = circuit_mul(num_c1_1, inv_den_c1_1);
        let lambda_c2_0 = circuit_mul(num_c2_0, inv_den_c2_0);
        let lambda_c2_1 = circuit_mul(num_c2_1, inv_den_c2_1);
    
        //-------------------------------------
        // STEP 6: Circuit output
        //-------------------------------------
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    
        let outputs = match (
            lambda_c0_0,
            lambda_c0_1,
            lambda_c1_0,
            lambda_c1_1,
            lambda_c2_0,
            lambda_c2_1,
        )
        .new_inputs()
        .next(from_u256(*self.x.c0.c0.c0)) // Input wire for self.x.c0.c0
        .next(from_u256(*self.x.c1.c0.c0)) // Input wire for self.x.c1.c0
        .next(from_u256(*self.y.c0.c0.c0)) // Input wire for self.y.c0.c0
        .next(from_u256(*self.y.c1.c0.c0)) // Input wire for self.y.c1.c0
        
        .next(from_u256(*self.x.c0.c0.c0)) // Input wire for rhs.x.c0.c0
        .next(from_u256(*self.x.c1.c0.c0)) // Input wire for rhs.x.c1.c0
        .next(from_u256(*self.y.c0.c0.c0)) // Input wire for rhs.y.c0.c0
        .next(from_u256(*self.y.c1.c0.c0)) // Input wire for rhs.y.c1.c0
        .done()
        .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Evaluation failed"),
        };

    
        //-------------------------------------
        // STEP 7: Retrieve the final slope
        //-------------------------------------
        Fq6 {
            c0: Fq2 {
                c0: Fq {
                    c0: outputs.get_output(lambda_c0_0).try_into().unwrap(),
                },
                c1: Fq {
                    c0: outputs.get_output(lambda_c0_1).try_into().unwrap(),
                },
            },
            c1: Fq2 {
                c0: Fq {
                    c0: outputs.get_output(lambda_c1_0).try_into().unwrap(),
                },
                c1: Fq {
                    c0: outputs.get_output(lambda_c1_1).try_into().unwrap(),
                },
            },
            c2: Fq2 {
                c0: Fq {
                    c0: outputs.get_output(lambda_c2_0).try_into().unwrap(),
                },
                c1: Fq {
                    c0: outputs.get_output(lambda_c2_1).try_into().unwrap(),
                },
            },
        }
    }
    
    // GOOD (MAY NEED REVIEW ? )
    fn double_as_circuit(self: @Affine<Fq6>) -> Affine<Fq6> {
        /// Compute the doubling of a point on the elliptic curve in Fq6 using a circuit.
        ///
        /// Formula:
        /// x3 = λ² - 2 * x1
        /// y3 = λ * (x1 - x3) - y1
        /// 
        //-------------------------------------
    
        let x1_c0_0 = CircuitElement::<CircuitInput<0>> {}; // self.x.c0.c0
        let x1_c0_1 = CircuitElement::<CircuitInput<1>> {}; // self.x.c0.c1
        let x1_c1_0 = CircuitElement::<CircuitInput<2>> {}; // self.x.c1.c0
        let x1_c1_1 = CircuitElement::<CircuitInput<3>> {}; // self.x.c1.c1
        let x1_c2_0 = CircuitElement::<CircuitInput<4>> {}; // self.x.c2.c0
        let x1_c2_1 = CircuitElement::<CircuitInput<5>> {}; // self.x.c2.c1
    
        let y1_c0_0 = CircuitElement::<CircuitInput<6>> {}; // self.y.c0.c0
        let y1_c0_1 = CircuitElement::<CircuitInput<7>> {}; // self.y.c0.c1
        let y1_c1_0 = CircuitElement::<CircuitInput<8>> {}; // self.y.c1.c0
        let y1_c1_1 = CircuitElement::<CircuitInput<9>> {}; // self.y.c1.c1
        let y1_c2_0 = CircuitElement::<CircuitInput<10>> {}; // self.y.c2.c0
        let y1_c2_1 = CircuitElement::<CircuitInput<11>> {}; // self.y.c2.c1
    
        //-------------------------------------
        // STEP 1: Compute the tangent slope (λ)
        //-------------------------------------
    
        // Compute \( x^2 \) component-wise
        let x_squared_c0_0 = circuit_mul(x1_c0_0, x1_c0_0); // x1.c0.c0^2
        let x_squared_c0_1 = circuit_mul(x1_c0_1, x1_c0_1); // x1.c0.c1^2
        let x_squared_c1_0 = circuit_mul(x1_c1_0, x1_c1_0); // x1.c1.c0^2
        let x_squared_c1_1 = circuit_mul(x1_c1_1, x1_c1_1); // x1.c1.c1^2
        let x_squared_c2_0 = circuit_mul(x1_c2_0, x1_c2_0); // x1.c2.c0^2
        let x_squared_c2_1 = circuit_mul(x1_c2_1, x1_c2_1); // x1.c2.c1^2
    
        // Multiply by 3 (using addition: \( 3 \cdot a = a + a + a \))
        let num_c0_0 = circuit_add(circuit_add(x_squared_c0_0, x_squared_c0_0), x_squared_c0_0);
        let num_c0_1 = circuit_add(circuit_add(x_squared_c0_1, x_squared_c0_1), x_squared_c0_1);
        let num_c1_0 = circuit_add(circuit_add(x_squared_c1_0, x_squared_c1_0), x_squared_c1_0);
        let num_c1_1 = circuit_add(circuit_add(x_squared_c1_1, x_squared_c1_1), x_squared_c1_1);
        let num_c2_0 = circuit_add(circuit_add(x_squared_c2_0, x_squared_c2_0), x_squared_c2_0);
        let num_c2_1 = circuit_add(circuit_add(x_squared_c2_1, x_squared_c2_1), x_squared_c2_1);
    
        //-------------------------------------
        // Compute the denominator \( 2y \)
        //-------------------------------------
        let den_c0_0 = circuit_add(y1_c0_0, y1_c0_0); // 2 * y1.c0.c0
        let den_c1_0 = circuit_add(y1_c1_0, y1_c1_0); // 2 * y1.c1.c0
        let den_c2_0 = circuit_add(y1_c2_0, y1_c2_0); // 2 * y1.c2.c0

    
        //-------------------------------------
        // Compute the inverse of the denominator
        //-------------------------------------
        let inv_den_c0 = circuit_inverse(den_c0_0); // Inverse of 2y.c0.c0
        let inv_den_c1 = circuit_inverse(den_c1_0); // Inverse of 2y.c1.c0
        let inv_den_c2 = circuit_inverse(den_c2_0); // Inverse of 2y.c2.c0
    
        //-------------------------------------
        // Compute the tangent slope \( \lambda = num / den \)
        //-------------------------------------
        let lambda_c0_0 = circuit_mul(num_c0_0, inv_den_c0);
        let lambda_c0_1 = circuit_mul(num_c0_1, inv_den_c0);
        let lambda_c1_0 = circuit_mul(num_c1_0, inv_den_c1);
        let lambda_c1_1 = circuit_mul(num_c1_1, inv_den_c1);
        let lambda_c2_0 = circuit_mul(num_c2_0, inv_den_c2);
        let lambda_c2_1 = circuit_mul(num_c2_1, inv_den_c2);
    
        //-------------------------------------
        // STEP 2: Compute \( x3 = \lambda^2 - 2 \cdot x1 \)
        //-------------------------------------
        // Compute \( \lambda^2 \)
        let lambda_squared_c0_0 = circuit_mul(lambda_c0_0, lambda_c0_0);
        let lambda_squared_c0_1 = circuit_mul(lambda_c0_1, lambda_c0_1);
        let lambda_squared_c1_0 = circuit_mul(lambda_c1_0, lambda_c1_0);
        let lambda_squared_c1_1 = circuit_mul(lambda_c1_1, lambda_c1_1);
        let lambda_squared_c2_0 = circuit_mul(lambda_c2_0, lambda_c2_0);
        let lambda_squared_c2_1 = circuit_mul(lambda_c2_1, lambda_c2_1);
    
        // Compute \( 2 \cdot x1 \)
        let two_x1_c0_0 = circuit_add(x1_c0_0, x1_c0_0);
        let two_x1_c0_1 = circuit_add(x1_c0_1, x1_c0_1);
        let two_x1_c1_0 = circuit_add(x1_c1_0, x1_c1_0);
        let two_x1_c1_1 = circuit_add(x1_c1_1, x1_c1_1);
        let two_x1_c2_0 = circuit_add(x1_c2_0, x1_c2_0);
        let two_x1_c2_1 = circuit_add(x1_c2_1, x1_c2_1);
    
        // Compute \( x3 = \lambda^2 - 2 \cdot x1 \)
        let x3_c0_0 = circuit_sub(lambda_squared_c0_0, two_x1_c0_0);
        let x3_c0_1 = circuit_sub(lambda_squared_c0_1, two_x1_c0_1);
        let x3_c1_0 = circuit_sub(lambda_squared_c1_0, two_x1_c1_0);
        let x3_c1_1 = circuit_sub(lambda_squared_c1_1, two_x1_c1_1);
        let x3_c2_0 = circuit_sub(lambda_squared_c2_0, two_x1_c2_0);
        let x3_c2_1 = circuit_sub(lambda_squared_c2_1, two_x1_c2_1);
    
        //-------------------------------------
        // STEP 3: Compute \( y3 = \lambda \cdot (x1 - x3) - y1 \)
        //-------------------------------------
        // Compute \( x1 - x3 \)
        let diff_x_c0_0 = circuit_sub(x1_c0_0, x3_c0_0);
        let diff_x_c0_1 = circuit_sub(x1_c0_1, x3_c0_1);
        let diff_x_c1_0 = circuit_sub(x1_c1_0, x3_c1_0);
        let diff_x_c1_1 = circuit_sub(x1_c1_1, x3_c1_1);
        let diff_x_c2_0 = circuit_sub(x1_c2_0, x3_c2_0);
        let diff_x_c2_1 = circuit_sub(x1_c2_1, x3_c2_1);
    
        // Compute \( \lambda \cdot (x1 - x3) \)
        let lambda_diff_c0_0 = circuit_mul(lambda_c0_0, diff_x_c0_0);
        let lambda_diff_c0_1 = circuit_mul(lambda_c0_1, diff_x_c0_1);
        let lambda_diff_c1_0 = circuit_mul(lambda_c1_0, diff_x_c1_0);
        let lambda_diff_c1_1 = circuit_mul(lambda_c1_1, diff_x_c1_1);
        let lambda_diff_c2_0 = circuit_mul(lambda_c2_0, diff_x_c2_0);
        let lambda_diff_c2_1 = circuit_mul(lambda_c2_1, diff_x_c2_1);
    
        // Compute \( y3 = \lambda \cdot (x1 - x3) - y1 \)
        let y3_c0_0 = circuit_sub(lambda_diff_c0_0, y1_c0_0);
        let y3_c0_1 = circuit_sub(lambda_diff_c0_1, y1_c0_1);
        let y3_c1_0 = circuit_sub(lambda_diff_c1_0, y1_c1_0);
        let y3_c1_1 = circuit_sub(lambda_diff_c1_1, y1_c1_1);
        let y3_c2_0 = circuit_sub(lambda_diff_c2_0, y1_c2_0);
        let y3_c2_1 = circuit_sub(lambda_diff_c2_1, y1_c2_1);
    
        //-------------------------------------
        // STEP 5: Circuit output and evaluation
        //-------------------------------------
    

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let outputs = match (x3_c0_0, x3_c0_1, x3_c1_0, x3_c1_1, x3_c2_0, x3_c2_1, 
                            y3_c0_0, y3_c0_1, y3_c1_0, y3_c1_1, y3_c2_0, y3_c2_1)
            .new_inputs()
            .next(from_u256(*self.x.c0.c0.c0))
            .next(from_u256(*self.x.c0.c1.c0))
            .next(from_u256(*self.x.c1.c0.c0))
            .next(from_u256(*self.x.c1.c1.c0))
            .next(from_u256(*self.x.c2.c0.c0))
            .next(from_u256(*self.x.c2.c1.c0))
            .next(from_u256(*self.y.c0.c0.c0))
            .next(from_u256(*self.y.c0.c1.c0))
            .next(from_u256(*self.y.c1.c0.c0))
            .next(from_u256(*self.y.c1.c1.c0))
            .next(from_u256(*self.y.c2.c0.c0))
            .next(from_u256(*self.y.c2.c1.c0))
            .done()
            .eval(modulus)
        {
            Result::Ok(outputs) => outputs,
            Result::Err(_) => panic!("Expected success"),
        };

        //-------------------------------------
        // STEP 6: Retrieve the final coordinates
        //-------------------------------------
        Affine {
            x: Fq6 {
                c0: Fq2 {
                    c0: Fq {
                        c0: outputs.get_output(x3_c0_0).try_into().unwrap(),
                    },
                    c1: Fq {
                        c0: outputs.get_output(x3_c0_1).try_into().unwrap(),
                    },
                },
                c1: Fq2 {
                    c0: Fq {
                        c0: outputs.get_output(x3_c1_0).try_into().unwrap(),
                    },
                    c1: Fq {
                        c0: outputs.get_output(x3_c1_1).try_into().unwrap(),
                    },
                },
                c2: Fq2 {
                    c0: Fq {
                        c0: outputs.get_output(x3_c2_0).try_into().unwrap(),
                    },
                    c1: Fq {
                        c0: outputs.get_output(x3_c2_1).try_into().unwrap(),
                    },
                },
            },
            y: Fq6 {
                c0: Fq2 {
                    c0: Fq {
                        c0: outputs.get_output(y3_c0_0).try_into().unwrap(),
                    },
                    c1: Fq {
                        c0: outputs.get_output(y3_c0_1).try_into().unwrap(),
                    },
                },
                c1: Fq2 {
                    c0: Fq {
                        c0: outputs.get_output(y3_c1_0).try_into().unwrap(),
                    },
                    c1: Fq {
                        c0: outputs.get_output(y3_c1_1).try_into().unwrap(),
                    },
                },
                c2: Fq2 {
                    c0: Fq {
                        c0: outputs.get_output(y3_c2_0).try_into().unwrap(),
                    },
                    c1: Fq {
                        c0: outputs.get_output(y3_c2_1).try_into().unwrap(),
                    },
                },
            },
        }
    }

    // Done
    fn multiply_as_circuit(self: @Affine<Fq6>, mut multiplier: u256) -> Affine<Fq6> {
        /// Perform scalar multiplication of a point on an elliptic curve in Fq6.
        /// This involves:
        /// 1. Iterating through the binary representation of the scalar.
        /// 2. Doubling the intermediate point for every bit.
        /// 3. Adding the current intermediate point if the current bit is 1.
    
        //-------------------------------------
        // STEP 1: Initialize variables
        //-------------------------------------
    
        // Represent 2 as a non-zero constant for division
        let nz2: NonZero<u256> = 2_u256.try_into().unwrap();
    
        // `dbl_step` holds the point being doubled in each iteration
        let mut dbl_step = *self;
    
        // `result` starts with the identity element (point at infinity for Fq6)
        let mut result = g6(
            1, 2, 3, 4, 5, 6, // x components
            7, 8, 9, 10, 11, 12 // y components
        );
    
        // Flag to indicate if the first addition is done
        let mut first_add_done = false;
    
        //-------------------------------------
        // STEP 2: Iterate through the scalar bits
        //-------------------------------------
        loop {
            // Binary decomposition of the scalar multiplier
            let (q, r, _) = integer::u256_safe_divmod(multiplier, nz2);
    
            if r == 1 {
                // Perform addition if the current bit is 1
                result = if !first_add_done {
                    first_add_done = true;
                    // For the first addition, directly set the result to dbl_step
                    dbl_step
                } else {
                    // Add the current `dbl_step` to `result`
                    result.add_as_circuit(dbl_step)
                };
            }
    
            if q == 0 {
                // Terminate the loop when all bits have been processed
                break;
            }
    
            // Double the current point for the next bit
            dbl_step = dbl_step.double_as_circuit();
    
            // Update the multiplier (quotient for the next iteration)
            multiplier = q;
        };
    
        //-------------------------------------
        // STEP 3: Return the result
        //-------------------------------------
        result
    }
    
    

}



impl AffineOps< T, +FOps<T>, +FShort<T>, +Copy<T>, +Print<T>, +Drop<T>, impl ECGImpl: ECGroup<T>> of ECOperations<T> {
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
fn g2(
    x1: u256, x2: u256,
    y1: u256, y2: u256
) -> Affine<Fq2> {
    Affine { 
        x: fq2(x1, x2),
        y: fq2(y1, y2) }
}

#[inline(always)]
fn g6(
    x1: u256, x2: u256, x3: u256, x4: u256, x5: u256, x6: u256,
    y1: u256, y2: u256, y3: u256, y4: u256, y5: u256, y6: u256
) -> Affine<Fq6> {
    Affine {
        x: fq6(x1, x2, x3, x4, x5, x6), // Construct Fq6 for x
        y: fq6(y1, y2, y3, y4, y5, y6), // Construct Fq6 for y
    }
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

impl AffineG6Impl of ECGroup<Fq6> {
    #[inline(always)]
    fn one() -> Affine<Fq6> {
        g6(
            0, 0, 0, 0, 0, 0, // x = 0 in Fq6 (example)
            1, 0, 0, 0, 0, 0, // y = 1 in Fq6 (example)
        )
    }
}