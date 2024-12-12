use core::option::OptionTrait;
use core::traits::TryInto;
use core::fmt::Display;
use core::traits::Destruct;
use core::clone::Clone;
use core::traits::Into;
use core::debug::{PrintTrait, print_byte_array_as_string};
use core::array::ArrayTrait;
use core::cmp::max;
use core::circuit::{
    RangeCheck96, AddMod, u96, CircuitElement, CircuitInput, circuit_add, circuit_sub,
    circuit_mul, circuit_inverse, EvalCircuitTrait, u384, CircuitOutputsTrait, CircuitModulus,
    AddInputResultTrait, CircuitInputs,EvalCircuitResult,
};
use core::circuit::conversions::from_u256;

use plonk_verifier::traits::FieldShortcuts;
use plonk_verifier::traits::FieldOps;
use plonk_verifier::traits::FieldUtils;
use plonk_verifier::traits::FieldMulShortcuts;
use plonk_verifier::plonk::transcript::Keccak256Transcript;
use plonk_verifier::curve::groups::{g1, g2, AffineG1, AffineG2, AffineG2Impl};
use plonk_verifier::curve::groups::{ECOperations, ECOperationsCircuitFq};
use plonk_verifier::fields::{fq, Fq, Fq12, Fq12Exponentiation, Fq12Utils};
use plonk_verifier::curve::constants::{ORDER, ORDER_NZ, get_field_nz, FIELD_U384, ORDER_U384};
use plonk_verifier::plonk::types::{PlonkProof, PlonkVerificationKey, PlonkChallenge};
use plonk_verifier::plonk::transcript::{Transcript, TranscriptElement};
use plonk_verifier::curve::{u512, neg_o, sqr_nz, mul, mul_u, div_nz, sub_u, sub};
use plonk_verifier::pairing::tate_bkls::{tate_pairing, tate_miller_loop};
use plonk_verifier::pairing::optimal_ate::{single_ate_pairing, ate_miller_loop};

use plonk_verifier::curve::{mul_o, mul_f, add_o};

#[generate_trait]
impl PlonkVerifier of PVerifier {
    fn verify(
        verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: Array<u256>
    ) -> bool {
        let mut result = true;
        // result = result
        //     && Self::is_on_curve(proof.A)
        //     && Self::is_on_curve(proof.B)
        //     && Self::is_on_curve(proof.C)
        //     && Self::is_on_curve(proof.Z)
        //     && Self::is_on_curve(proof.T1)
        //     && Self::is_on_curve(proof.T2)
        //     && Self::is_on_curve(proof.T3)
        //     && Self::is_on_curve(proof.Wxi)
        //     && Self::is_on_curve(proof.Wxiw);

        // result = result
        //     && Self::is_in_field(proof.eval_a)
        //     && Self::is_in_field(proof.eval_b)
        //     && Self::is_in_field(proof.eval_c)
        //     && Self::is_in_field(proof.eval_s1)
        //     && Self::is_in_field(proof.eval_s2)
        //     && Self::is_in_field(proof.eval_zw);

        // result = result
        //     && Self::check_public_inputs_length(
        //         verification_key.nPublic, publicSignals.len().into()
        //     );
        // let mut challenges: PlonkChallenge = Self::compute_challenges(
        //     verification_key, proof, publicSignals.clone()
        // );

        // let (L, challenges) = Self::compute_lagrange_evaluations(verification_key, challenges);

        // let PI = Self::compute_PI(publicSignals.clone(), L.clone());

        // let R0 = Self::compute_R0(proof, challenges, PI, L[1].clone());

        // let D = Self::compute_D(proof, challenges, verification_key, L[1].clone());

        // let F = Self::compute_F(proof, challenges, verification_key, D);

        // let E = Self::compute_E(proof, challenges, R0);

        let mut challenges = PlonkChallenge {
            beta: fq(1),
            gamma: fq(1),
            alpha: fq(1),
            xi: fq(1),
            xin: fq(1),
            zh: fq(1),
            v1: fq(1),
            v2: fq(1),
            v3: fq(1),
            v4: fq(1),
            v5: fq(1),
            u: fq(1)
        };
        let F: AffineG1 = g1(1, 2);
        let E: AffineG1 = g1(1, 2);

        let valid_pairing = Self::valid_pairing(proof, challenges, verification_key, E, F);
        result = result && valid_pairing;

        result
    }

    // step 1: check if the points are on the bn254 curve
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

    // step 2: check if the field element is in the field
    fn is_in_field(num: Fq) -> bool {
        // bn254 curve field:
        // 21888242871839275222246405745257275088548364400416034343698204186575808495617
        num.c0 < ORDER
    }

    //step 3: check proof public inputs match the verification key
    fn check_public_inputs_length(len_a: u256, len_b: u256) -> bool {
        len_a == len_b
    }

    // step 4: compute challenge
    fn compute_challenges(
        verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: Array<u256>
    ) -> PlonkChallenge {
        let mut challenges = PlonkChallenge {
            beta: fq(0),
            gamma: fq(0),
            alpha: fq(0),
            xi: fq(0),
            xin: fq(0),
            zh: fq(0),
            v1: fq(0),
            v2: fq(0),
            v3: fq(0),
            v4: fq(0),
            v5: fq(0),
            u: fq(0)
        };

        // Challenge round 2: beta and gamma
        let mut beta_transcript = Transcript::new();
        beta_transcript.add_poly_commitment(verification_key.Qm);
        beta_transcript.add_poly_commitment(verification_key.Ql);
        beta_transcript.add_poly_commitment(verification_key.Qr);
        beta_transcript.add_poly_commitment(verification_key.Qo);
        beta_transcript.add_poly_commitment(verification_key.Qc);
        beta_transcript.add_poly_commitment(verification_key.S1);
        beta_transcript.add_poly_commitment(verification_key.S2);
        beta_transcript.add_poly_commitment(verification_key.S3);

        for i in 0..publicSignals.len() {
            beta_transcript.add_scalar(fq(publicSignals.at(i).clone()));
        };

        beta_transcript.add_poly_commitment(proof.A);
        beta_transcript.add_poly_commitment(proof.B);
        beta_transcript.add_poly_commitment(proof.C);

        challenges.beta = beta_transcript.get_challenge();

        let mut gamma_transcript = Transcript::new();
        gamma_transcript.add_scalar(challenges.beta);
        challenges.gamma = gamma_transcript.get_challenge();

        // Challenge round 3: alpha
        let mut alpha_transcript = Transcript::new();
        alpha_transcript.add_scalar(challenges.beta);
        alpha_transcript.add_scalar(challenges.gamma);
        alpha_transcript.add_poly_commitment(proof.Z);
        challenges.alpha = alpha_transcript.get_challenge();

        // Challenge round 4: xi
        let mut xi_transcript = Transcript::new();
        xi_transcript.add_scalar(challenges.alpha);
        xi_transcript.add_poly_commitment(proof.T1);
        xi_transcript.add_poly_commitment(proof.T2);
        xi_transcript.add_poly_commitment(proof.T3);
        challenges.xi = xi_transcript.get_challenge();

        // // Challenge round 5: v
        let mut v_transcript = Transcript::new();
        v_transcript.add_scalar(challenges.xi);
        v_transcript.add_scalar(proof.eval_a);
        v_transcript.add_scalar(proof.eval_b);
        v_transcript.add_scalar(proof.eval_c);
        v_transcript.add_scalar(proof.eval_s1);
        v_transcript.add_scalar(proof.eval_s2);
        v_transcript.add_scalar(proof.eval_zw);

        challenges.v1 = v_transcript.get_challenge();
        challenges.v2 = fq(mul_o(challenges.v1.c0, challenges.v1.c0));
        challenges.v3 = fq(mul_o(challenges.v2.c0, challenges.v1.c0));
        challenges.v4 = fq(mul_o(challenges.v3.c0, challenges.v1.c0));
        challenges.v5 = fq(mul_o(challenges.v4.c0, challenges.v1.c0));

        // Challenge: u
        let mut u_transcript = Transcript::new();
        u_transcript.add_poly_commitment(proof.Wxi);
        u_transcript.add_poly_commitment(proof.Wxiw);
        challenges.u = u_transcript.get_challenge();

        challenges
    }

    // step 5,6: compute zero polynomial and calculate the lagrange evaluations
    fn compute_lagrange_evaluations(
        verification_key: PlonkVerificationKey, mut challenges: PlonkChallenge
    ) -> (Array<Fq>, PlonkChallenge) {
        let mut xin = challenges.xi;
        let mut domain_size = 1;

        let mut i = 0;
        while i < verification_key.power {
            let sqr_mod: u256 = sqr_nz(xin.c0, ORDER_NZ);
            xin = fq(sqr_mod);
            domain_size *= 2;
            i += 1;
        };

        challenges.xin = fq(xin.c0);
        challenges.zh = xin.sub(fq(1));

        let mut lagrange_evaluations: Array<Fq> = array![];
        lagrange_evaluations.append(fq(0));

        let n: Fq = fq(domain_size);
        let mut w: Fq = fq(1);

        let n_public: u32 = verification_key.nPublic.try_into().unwrap();

        let mut j = 1;
        while j <= max(1, n_public) {
            let xi_sub_w: u256 = sub_u(challenges.xi.c0, w.c0);
            let xi_mul_n: u256 = mul_o(n.c0, xi_sub_w);
            let w_mul_zh: u256 = mul_o(w.c0, challenges.zh.c0);
            let l_i = div_nz(w_mul_zh, xi_mul_n, ORDER_NZ);
            lagrange_evaluations.append(fq(l_i));

            w = fq(mul_o(w.c0, verification_key.w));

            j += 1;
        };

        (lagrange_evaluations, challenges)
    }

    // step 7: compute public input polynomial evaluation
    fn compute_PI(publicSignals: Array<u256>, L: Array<Fq>) -> Fq {
        let mut PI: Fq = fq(0);
        let mut i = 0;

        while i < publicSignals.len() {
            let w: u256 = publicSignals[i].clone();
            let w_mul_L: u256 = mul_o(w, L[i + 1].c0.clone());
            let pi = sub(PI.c0, w_mul_L, ORDER);

            PI = fq(pi);
            i += 1;
        };

        PI
    }

    // step 8: compute r constant
    fn compute_R0(proof: PlonkProof, challenges: PlonkChallenge, PI: Fq, L1: Fq) -> Fq {
        let e1: u256 = PI.c0;
        let e2: u256 = mul_o(L1.c0, sqr_nz(challenges.alpha.c0, ORDER_NZ));

        let mut e3a = add_o(
            proof.eval_a.c0, mul_o(challenges.beta.c0, proof.eval_s1.c0)
        );
        e3a = add_o(e3a, challenges.gamma.c0);

        let mut e3b = add_o(
            proof.eval_b.c0, mul_o(challenges.beta.c0, proof.eval_s2.c0)
        );
        e3b = add_o(e3b, challenges.gamma.c0);

        let mut e3c = add_o(proof.eval_c.c0, challenges.gamma.c0);

        let mut e3 = mul_o(mul_o(e3a, e3b), e3c);
        e3 = mul_o(e3, proof.eval_zw.c0);
        e3 = mul_o(e3, challenges.alpha.c0);

        let r0 = sub(sub(e1, e2, ORDER), e3, ORDER);

        fq(r0)
    }

    // step 9: Compute first part of batched polynomial commitment D
    fn compute_D(
        proof: PlonkProof, challenges: PlonkChallenge, vk: PlonkVerificationKey, l1: Fq
    ) -> AffineG1 {
        let mut d1 = vk.Qm.multiply_as_circuit((mul_o(proof.eval_a.c0, proof.eval_b.c0)));
        d1 = d1.add(vk.Ql.multiply_as_circuit(proof.eval_a.c0));
        d1 = d1.add(vk.Qr.multiply_as_circuit(proof.eval_b.c0));
        d1 = d1.add(vk.Qo.multiply_as_circuit(proof.eval_c.c0));
        d1 = d1.add(vk.Qc);

        let betaxi = mul_o(challenges.beta.c0, challenges.xi.c0);
        let mut d2a1 = add_o(proof.eval_a.c0, betaxi);
        d2a1 = add_o(d2a1, challenges.gamma.c0);

        let mut d2a2 = mul_o(betaxi, vk.k1);
        d2a2 = add_o(proof.eval_b.c0, d2a2);
        d2a2 = add_o(d2a2, challenges.gamma.c0);

        let mut d2a3 = mul_o(betaxi, vk.k2);
        d2a3 = add_o(proof.eval_c.c0, d2a3);
        d2a3 = add_o(d2a3, challenges.gamma.c0);

        let d2a = mul_o(
            mul_o(mul_o(d2a1, d2a2), d2a3), challenges.alpha.c0
        );

        let d2b = mul_o(l1.c0, sqr_nz(challenges.alpha.c0, ORDER_NZ));

        let d2 = proof.Z.multiply_as_circuit(add_o(add_o(d2a, d2b), challenges.u.c0));

        let d3a = add_o(
            add_o(
                proof.eval_a.c0, mul_o(challenges.beta.c0, proof.eval_s1.c0)
            ),
            challenges.gamma.c0
        );

        let d3b = add_o(
            add_o(
                proof.eval_b.c0, mul_o(challenges.beta.c0, proof.eval_s2.c0)
            ),
            challenges.gamma.c0
        );

        let d3c = mul_o(
            mul_o(challenges.alpha.c0, challenges.beta.c0), proof.eval_zw.c0
        );

        let d3 = vk.S3.multiply_as_circuit(mul_o(mul_o(d3a, d3b), d3c));

        let d4low = proof.T1;
        let d4mid = proof.T2.multiply_as_circuit(challenges.xin.c0);
        let d4high = proof.T3.multiply_as_circuit(sqr_nz(challenges.xin.c0, ORDER_NZ));
        let mut d4 = d4mid.add_as_circuit(d4high);
        d4 = d4.add_as_circuit(d4low);
        d4 = d4.multiply_as_circuit(challenges.zh.c0);

        let mut d = d1.add_as_circuit(d2);
        d = d.add_as_circuit(d3.neg());
        d = d.add(d4.neg());

        d
    }

    // step 10: Compute full batched polynomial commitment F
    fn compute_F(
        proof: PlonkProof, challenges: PlonkChallenge, vk: PlonkVerificationKey, D: AffineG1
    ) -> AffineG1 {
        let mut v1a = proof.A.multiply_as_circuit(challenges.v1.c0);
        let res_add_d = v1a.add_as_circuit(D);

        let v2b = proof.B.multiply_as_circuit(challenges.v2.c0);
        let res_add_v2b = res_add_d.add_as_circuit(v2b);

        let v3c = proof.C.multiply_as_circuit(challenges.v3.c0);
        let res_add_v3c = res_add_v2b.add_as_circuit(v3c);

        let v4s1 = vk.S1.multiply_as_circuit(challenges.v4.c0);
        let res_add_v4s1 = res_add_v3c.add_as_circuit(v4s1);

        let v5s2 = vk.S2.multiply_as_circuit(challenges.v5.c0);
        let res = res_add_v4s1.add_as_circuit(v5s2);

        res
    }

    // step 11: Compute group-encoded batch evaluation E
    fn compute_E(proof: PlonkProof, challenges: PlonkChallenge, r0: Fq) -> AffineG1 {
        let mut res: AffineG1 = g1(1, 2);
        let neg_r0 = neg_o(r0.c0);
        
        let n_r0 = CircuitElement::<CircuitInput<0>> {};
        let v1 = CircuitElement::<CircuitInput<1>> {};
        let v2 = CircuitElement::<CircuitInput<2>> {};
        let v3 = CircuitElement::<CircuitInput<3>> {};
        let v4 = CircuitElement::<CircuitInput<4>> {};
        let v5 = CircuitElement::<CircuitInput<5>> {};
        let u = CircuitElement::<CircuitInput<6>> {};
        let a = CircuitElement::<CircuitInput<7>> {};
        let b = CircuitElement::<CircuitInput<8>> {};
        let c = CircuitElement::<CircuitInput<9>> {};
        let s1 = CircuitElement::<CircuitInput<10>> {};
        let s2 = CircuitElement::<CircuitInput<11>> {};
        let zw = CircuitElement::<CircuitInput<12>> {};

        let e0_inner = circuit_mul(v1, a);
        let e0 = circuit_add(n_r0, e0_inner); 
        let e1_inner = circuit_mul(v2, b);
        let e1 = circuit_add(e0, e1_inner); 
        let e2_inner = circuit_mul(v3, c);
        let e2 = circuit_add(e1, e2_inner); 
        let e3_inner = circuit_mul(v4, s1);
        let e3 = circuit_add(e2, e3_inner); 
        let e4_inner = circuit_mul(v5, s2);
        let e4 = circuit_add(e3, e4_inner); 
        let e5_inner = circuit_mul(u, zw);
        let e5 = circuit_add(e4, e5_inner); 

        let modulus = TryInto::<_, CircuitModulus>::try_into(ORDER_U384).unwrap();

        let outputs =
            match (e5, )
                .new_inputs()
                .next(from_u256(neg_r0))
                .next(from_u256(challenges.v1.c0))
                .next(from_u256(challenges.v2.c0))
                .next(from_u256(challenges.v3.c0))
                .next(from_u256(challenges.v4.c0))
                .next(from_u256(challenges.v5.c0))
                .next(from_u256(challenges.u.c0))
                .next(from_u256(proof.eval_a.c0))
                .next(from_u256(proof.eval_b.c0))
                .next(from_u256(proof.eval_c.c0))
                .next(from_u256(proof.eval_s1.c0))
                .next(from_u256(proof.eval_s2.c0))
                .next(from_u256(proof.eval_zw.c0))
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let e: u256 = outputs.get_output(e5).try_into().unwrap(); 

        res = res.multiply_as_circuit(e);

        res
    }

    //step 12: Elliptic Curve Pairing: Batch validate all evaluations
    fn valid_pairing(
        proof: PlonkProof,
        challenges: PlonkChallenge,
        vk: PlonkVerificationKey,
        E: AffineG1,
        F: AffineG1
    ) -> bool {
        let mut A1 = proof.Wxi;

        let Wxiw_mul_u = proof.Wxiw.multiply_as_circuit(challenges.u.c0);
        A1 = A1.add_as_circuit(Wxiw_mul_u);

        let mut B1 = proof.Wxi.multiply_as_circuit(challenges.xi.c0);
        let s = mul_o(mul_o(challenges.u.c0, challenges.xi.c0), vk.w);

        let Wxiw_mul_s = proof.Wxiw.multiply_as_circuit(s);
        B1 = B1.add_as_circuit(Wxiw_mul_s);

        B1 = B1.add_as_circuit(F);

        B1 = B1.add_as_circuit(E.neg());

        let g2_one = AffineG2Impl::one();

        let e_A1_vk_x2 = single_ate_pairing(A1, vk.X_2);
        let e_B1_g2_1 = single_ate_pairing(B1, g2_one);

        let res: bool = e_A1_vk_x2.c0 == e_B1_g2_1.c0;

        res
    }
}
