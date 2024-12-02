use core::option::OptionTrait;
use core::result::ResultTrait;
use core::traits::TryInto;
use core::traits::Into;
use core::debug::PrintTrait;
use core::array::ArrayTrait;
use core::result::Result::{Ok, Err};

use plonk_verifier::curve::groups::{AffineG1, AffineG2};
use plonk_verifier::fields::{Fq, Fq12};
use plonk_verifier::curve::constants::{ORDER, ORDER_NZ};
use plonk_verifier::plonk::types::{PlonkProof, PlonkVerificationKey, PlonkChallenge};
use plonk_verifier::plonk::transcript::{TranscriptTrait, Keccak256Transcript};
use plonk_verifier::errors::{PlonkError, Result, PlonkError::InvalidCurvePoint, validate_curve_point, validate_field_element, validate_public_input, validate_verification};

#[generate_trait]
impl PolynomialCommitmentVerifier of PCommitmentVerifier {
    fn verify_commitment(
        commitment: AffineG1, 
        evaluation: Fq, 
        proof: AffineG1, 
        evaluation_point: Fq,
        verification_key: PlonkVerificationKey
    ) -> Result<bool> {
        // Validate curve points
        validate_curve_point(Self::is_on_curve(commitment), 'Commitment point is not on curve')?;
        validate_curve_point(Self::is_on_curve(proof), 'Proof point is not on curve')?;

        // Validate field elements
        validate_field_element(Self::is_in_field(evaluation), 'Evaluation not in field')?;
        validate_field_element(Self::is_in_field(evaluation_point), 'Evaluation point not in field')?;

        // Compute the pairing check
        let valid_pairing = Self::valid_pairing(commitment, evaluation, proof, evaluation_point, verification_key)?;
        
        Ok(valid_pairing)
    }

    // Check if point is on the bn254 curve
    fn is_on_curve(pt: AffineG1) -> bool {
        // Circuit for bn254 curve equation: y^2 = x^3 + 3
        // As y^2 - x^3 = 3
        let x = CircuitElement::<CircuitInput<0>> {};
        let y = CircuitElement::<CircuitInput<1>> {};
        let x_sqr = circuit_mul(x, x);
        let x_cube = circuit_mul(x_sqr, x); 
        let y_sqr = circuit_mul(y, y); 
        let out = circuit_sub(y_sqr, x_cube);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
        let in1 = from_u256(pt.x.c0);
        let in2 = from_u256(pt.y.c0);

        let outputs =
            match (out, )
                .new_inputs()
                .next(in1)
                .next(in2)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let out: u256 = outputs.get_output(out).try_into().unwrap(); 

        out == 3
    }

    // Check if field element is in the field
    fn is_in_field(num: Fq) -> bool {
        num.c0 < ORDER
    }

    // Perform pairing check for polynomial commitment verification
    fn valid_pairing(
        commitment: AffineG1,
        evaluation: Fq,
        proof: AffineG1,
        evaluation_point: Fq,
        vk: PlonkVerificationKey
    ) -> Result<bool> {
        // e([C]₁ - [f]₁, [1]₂) = e([π]₁, [x]₂)
        // where:
        // - [C]₁ is the commitment
        // - [f]₁ is the evaluation point in G1
        // - [π]₁ is the proof
        // - [x]₂ is the evaluation point in G2

        // Convert evaluation point to G1
        let eval_g1 = vk.g1.multiply_as_circuit(evaluation.c0);
        
        // Compute left side: [C]₁ - [f]₁
        let left = commitment.subtract(eval_g1)?;

        // Convert evaluation point to G2
        let eval_g2 = vk.g2.multiply_as_circuit(evaluation_point.c0);

        // Compute pairings
        let pair1 = optimal_ate_pairing(left, vk.g2)?;
        let pair2 = optimal_ate_pairing(proof, eval_g2)?;

        // Check if pairings are equal
        Ok(pair1 == pair2)
    }
}
