use core::num::traits::Zero;
use core::{
    array::ArrayTrait,
    circuit::{
        AddInputResultTrait, AddModGate as A, CircuitElement, CircuitElement as CE, CircuitInput,
        CircuitInput as CI, CircuitInputs, CircuitModulus, CircuitOutputsTrait, EvalCircuitResult,
        EvalCircuitTrait, InverseGate as I, MulModGate as M, SubModGate as S, circuit_add,
        circuit_inverse, circuit_mul, circuit_sub, u96, u384,
    },
    cmp::max,
    traits::{Destruct, Into, TryInto},
};

use plonk_verifier::circuits::fq_circuits::{add_c, div_c, mul_c, neg_c, sqr_c, sub_c};
use plonk_verifier::{
    curve::{
        constants::{FIELD_U384, ORDER, ORDER_384, ORDER_U384},
        groups::{AffineG1, AffineG2, AffineG1Impl, AffineG2Impl, ECOperationsCircuitFq, g2},
    },
    fields::{
        fq, Fq, Fq12, Fq12Exponentiation, Fq12Utils, FqUtils,
        fq_generics::TFqPartialEq,
    },
    pairing::optimal_ate::{ate_miller_loop, single_ate_pairing},
    plonk::{
        constants::THREE,
        transcript::{Keccak256Transcript, Transcript, TranscriptElement},
        types::{PlonkChallenge, PlonkProof, PlonkVerificationKey},
        utils:: {field_modulus, order_modulus},
    },
    traits::{FieldOps, FieldUtils},
};

#[generate_trait]
impl PlonkVerifier of PVerifier {
    fn verify(
        verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: Array<u384>
    ) -> bool {
        let mut result = true;
        let m = field_modulus();
        let m_o = order_modulus();

        result = result
            && Self::is_on_curve(proof.A, m)
            && Self::is_on_curve(proof.B, m)
            && Self::is_on_curve(proof.C, m)
            && Self::is_on_curve(proof.Z, m)
            && Self::is_on_curve(proof.T1, m)
            && Self::is_on_curve(proof.T2, m)
            && Self::is_on_curve(proof.T3, m)
            && Self::is_on_curve(proof.Wxi, m)
            && Self::is_on_curve(proof.Wxiw, m);

        result = result
            && Self::is_in_field(proof.eval_a)
            && Self::is_in_field(proof.eval_b)
            && Self::is_in_field(proof.eval_c)
            && Self::is_in_field(proof.eval_s1)
            && Self::is_in_field(proof.eval_s2)
            && Self::is_in_field(proof.eval_zw);

        result = result
            && Self::check_public_inputs_length(
                verification_key.nPublic, publicSignals.len().into()
            );

        let mut challenges: PlonkChallenge = Self::compute_challenges(
            verification_key, proof, @publicSignals, m_o
        );

        let (L, challenges) = Self::compute_lagrange_evaluations(verification_key, challenges, m, m_o);

        let PI = Self::compute_PI(@publicSignals, @L, m_o);

        let R0 = Self::compute_R0(proof, challenges, @PI, L[1], m_o);

        let D = Self::compute_D(proof, challenges, verification_key, L[1], m, m_o);

        let F = Self::compute_F(proof, challenges, verification_key, D, m);

        let E = Self::compute_E(proof, challenges, R0, m, m_o);

        let valid_pairing = Self::valid_pairing(proof, challenges, verification_key, E, F, m, m_o);
        result = result && valid_pairing;

        result
    }

    // step 1: check if the points are on the bn254 curve
    fn is_on_curve(pt: AffineG1, m: CircuitModulus) -> bool {
        // Circuit for bn254 curve equation: y^2 = x^3 + 3
        // As y^2 - x^3 = 3
        let out = core::circuit::CircuitElement::<core::circuit::SubModGate::<core::circuit::MulModGate::<core::circuit::CircuitInput::<1>, core::circuit::CircuitInput::<1>>, core::circuit::MulModGate::<core::circuit::MulModGate::<core::circuit::CircuitInput::<0>, core::circuit::CircuitInput::<0>>, core::circuit::CircuitInput::<0>>>> {};

        let outputs = match (out,).new_inputs()
            .next(pt.x.c0)
            .next(pt.y.c0)
            .done()
            .eval(m) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };
    
        outputs.get_output(out) == THREE
    }

    // step 2: check if the field element is in the field
    fn is_in_field(num: Fq) -> bool {
        // bn254 curve field:
        // 21888242871839275222246405745257275088548364400416034343698204186575808495617

        (num.c0).try_into().unwrap() < ORDER
    }

    //step 3: check proof public inputs match the verification key
    fn check_public_inputs_length(len_a: u256, len_b: u256) -> bool {
        len_a == len_b
    }

    // step 4: compute challenge
    fn compute_challenges(
        verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: @Array<u384>, m_o: CircuitModulus
    ) -> PlonkChallenge {
        let mut challenges = PlonkChallenge {
            beta: FqUtils::zero(),
            gamma: FqUtils::zero(),
            alpha: FqUtils::zero(),
            xi: FqUtils::zero(),
            xin: FqUtils::zero(),
            zh: FqUtils::zero(),
            v1: FqUtils::zero(),
            v2: FqUtils::zero(),
            v3: FqUtils::zero(),
            v4: FqUtils::zero(),
            v5: FqUtils::zero(),
            u: FqUtils::zero()
        };

        // Challenge round 2: beta and gamma
        let mut beta_transcript = Transcript::new();
        beta_transcript.add(TranscriptElement::Polynomial(verification_key.Qm));
        beta_transcript.add(TranscriptElement::Polynomial(verification_key.Ql));
        beta_transcript.add(TranscriptElement::Polynomial(verification_key.Qr));
        beta_transcript.add(TranscriptElement::Polynomial(verification_key.Qo));
        beta_transcript.add(TranscriptElement::Polynomial(verification_key.Qc));
        beta_transcript.add(TranscriptElement::Polynomial(verification_key.S1));
        beta_transcript.add(TranscriptElement::Polynomial(verification_key.S2));
        beta_transcript.add(TranscriptElement::Polynomial(verification_key.S3));

        let mut i = 0;
        while i < publicSignals.len() {
            beta_transcript.add(TranscriptElement::Scalar(fq(*publicSignals.at(i))));

            i = i + 1;
        };

        beta_transcript.add(TranscriptElement::Polynomial(proof.A));
        beta_transcript.add(TranscriptElement::Polynomial(proof.B));
        beta_transcript.add(TranscriptElement::Polynomial(proof.C));

        challenges.beta = beta_transcript.get_challenge(m_o);

        let mut gamma_transcript = Transcript::new();
        gamma_transcript.add(TranscriptElement::Scalar(challenges.beta));
        challenges.gamma = gamma_transcript.get_challenge(m_o);

        // Challenge round 3: alpha
        let mut alpha_transcript = Transcript::new();
        alpha_transcript.add(TranscriptElement::Scalar(challenges.beta));
        alpha_transcript.add(TranscriptElement::Scalar(challenges.gamma));
        alpha_transcript.add(TranscriptElement::Polynomial(proof.Z));
        challenges.alpha = alpha_transcript.get_challenge(m_o);

        // Challenge round 4: xi
        let mut xi_transcript = Transcript::new();
        xi_transcript.add(TranscriptElement::Scalar(challenges.alpha));
        xi_transcript.add(TranscriptElement::Polynomial(proof.T1));
        xi_transcript.add(TranscriptElement::Polynomial(proof.T2));
        xi_transcript.add(TranscriptElement::Polynomial(proof.T3));
        challenges.xi = xi_transcript.get_challenge(m_o);

        // // Challenge round 5: v
        let mut v_transcript = Transcript::new();
        v_transcript.add(TranscriptElement::Scalar(challenges.xi));
        v_transcript.add(TranscriptElement::Scalar(proof.eval_a));
        v_transcript.add(TranscriptElement::Scalar(proof.eval_b));
        v_transcript.add(TranscriptElement::Scalar(proof.eval_c));
        v_transcript.add(TranscriptElement::Scalar(proof.eval_s1));
        v_transcript.add(TranscriptElement::Scalar(proof.eval_s2));
        v_transcript.add(TranscriptElement::Scalar(proof.eval_zw));

        challenges.v1 = v_transcript.get_challenge(m_o);
        challenges.v2 = fq(mul_c(challenges.v1.c0, challenges.v1.c0, m_o));
        challenges.v3 = fq(mul_c(challenges.v2.c0, challenges.v1.c0, m_o));
        challenges.v4 = fq(mul_c(challenges.v3.c0, challenges.v1.c0, m_o));
        challenges.v5 = fq(mul_c(challenges.v4.c0, challenges.v1.c0, m_o));

        // Challenge: u
        let mut u_transcript = Transcript::new();
        u_transcript.add(TranscriptElement::Polynomial(proof.Wxi));
        u_transcript.add(TranscriptElement::Polynomial(proof.Wxiw));
        challenges.u = u_transcript.get_challenge(m_o);

        challenges
    }

    // step 5,6: compute zero polynomial and calculate the lagrange evaluations
    fn compute_lagrange_evaluations(
        verification_key: PlonkVerificationKey, mut challenges: PlonkChallenge, m: CircuitModulus, m_o: CircuitModulus
    ) -> (Array<Fq>, PlonkChallenge) {
        let mut xin = challenges.xi;
        let mut domain_size = FqUtils::one();

        let mut i = 0;
        while i < verification_key.power {
            let sqr_mod = mul_c(xin.c0, xin.c0, m_o);
            xin = fq(sqr_mod);
            domain_size = domain_size.add(domain_size,m); // scale(2, m);
            i += 1;
        };

        challenges.xin = fq(xin.c0);
        challenges.zh = xin.sub(FqUtils::one(), m);

        let mut lagrange_evaluations: Array<Fq> = array![];
        lagrange_evaluations.append(FqUtils::zero());

        let n: Fq = domain_size;
        let mut w: Fq = FqUtils::one();

        let mut n_public: u32 = verification_key.nPublic.try_into().unwrap();
        if n_public == 0 {
            n_public = 1; 
        }

        let mut j = 1;
        while j <= n_public {
            let xi_sub_w = challenges.xi.sub(w, m);
            let xi_mul_n = mul_c(n.c0, xi_sub_w.c0, m_o);
            let w_mul_zh = mul_c(w.c0, challenges.zh.c0, m_o);
            let l_i = div_c(w_mul_zh, xi_mul_n, m_o);
            lagrange_evaluations.append(fq(l_i));

            w = fq(mul_c(w.c0, verification_key.w, m_o));

            j += 1;
        };

        (lagrange_evaluations, challenges)
    }

    // step 7: compute public input polynomial evaluation
    fn compute_PI(publicSignals: @Array<u384>, L: @Array<Fq>, m_o: CircuitModulus) -> Fq {
        let mut PI: Fq = FqUtils::zero();

        let mut i = 0;
        while i < publicSignals.len() {
            let w: u384 = *publicSignals[i];
            let w_mul_L: u384 = mul_c(w, *L[i + 1].c0, m_o);
            let pi = sub_c(PI.c0, w_mul_L, m_o);

            PI = fq(pi);
            i = i + 1;
        };

        PI
    }

    // step 8: compute r constant
    fn compute_R0(proof: PlonkProof, challenges: PlonkChallenge, PI: @Fq, L1: @Fq, m_o: CircuitModulus) -> Fq {

        let e1: u384 = *PI.c0;
        let e2: u384 = mul_c(*L1.c0, mul_c(challenges.alpha.c0, challenges.alpha.c0, m_o), m_o);

        let mut e3a = add_c(proof.eval_a.c0, mul_c(challenges.beta.c0, proof.eval_s1.c0, m_o), m_o);
        e3a = add_c(e3a, challenges.gamma.c0, m_o);

        let mut e3b = add_c(proof.eval_b.c0, mul_c(challenges.beta.c0, proof.eval_s2.c0, m_o), m_o);
        e3b = add_c(e3b, challenges.gamma.c0, m_o);

        let mut e3c = add_c(proof.eval_c.c0, challenges.gamma.c0, m_o);

        let mut e3 = mul_c(mul_c(e3a, e3b, m_o), e3c, m_o);
        e3 = mul_c(e3, proof.eval_zw.c0, m_o);
        e3 = mul_c(e3, challenges.alpha.c0, m_o);

        let r0 = sub_c(sub_c(e1, e2, m_o), e3, m_o);

        fq(r0)
    }

    // step 9: Compute first part of batched polynomial commitment D
    fn compute_D(
        proof: PlonkProof, challenges: PlonkChallenge, vk: PlonkVerificationKey, l1: @Fq, m: CircuitModulus, m_o: CircuitModulus
    ) -> AffineG1 {
        let mut d1 = vk.Qm.multiply_as_circuit((mul_c(proof.eval_a.c0, proof.eval_b.c0, m_o)), m);
        d1 = d1.add_as_circuit(vk.Ql.multiply_as_circuit(proof.eval_a.c0, m), m);
        d1 = d1.add_as_circuit(vk.Qr.multiply_as_circuit(proof.eval_b.c0, m), m);
        d1 = d1.add_as_circuit(vk.Qo.multiply_as_circuit(proof.eval_c.c0, m), m);
        d1 = d1.add_as_circuit(vk.Qc, m);

        let d2ab = CE::<A::<A::<M::<M::<M::<A::<A::<CI::<2>, M::<CI::<0>, CI::<1>>>, CI::<3>>, A::<A::<CI::<5>, M::<M::<CI::<0>, CI::<1>>, CI::<4>>>, CI::<3>>>, A::<A::<CI::<7>, M::<M::<CI::<0>, CI::<1>>, CI::<6>>>, CI::<3>>>, CI::<8>>, M::<CI::<9>, M::<CI::<8>, CI::<8>>>>, CI::<10>>> {};
        let d3ab = CE::<M::<M::<A::<A::<CI::<2>, M::<CI::<0>, CI::<11>>>, CI::<3>>, A::<A::<CI::<5>, M::<CI::<0>, CI::<12>>>, CI::<3>>>, M::<M::<CI::<8>, CI::<0>>, CI::<13>>>> {};

        let o = match (d2ab, d3ab).new_inputs()
            .next(challenges.beta.c0)
            .next(challenges.xi.c0)
            .next(proof.eval_a.c0)
            .next(challenges.gamma.c0)
            .next(vk.k1)
            .next(proof.eval_b.c0)
            .next(vk.k2)
            .next(proof.eval_c.c0)
            .next(challenges.alpha.c0)
            .next(*l1.c0)
            .next(challenges.u.c0)
            .next(proof.eval_s1.c0)
            .next(proof.eval_s2.c0)
            .next(proof.eval_zw.c0)
            .done()
            .eval(m_o) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };

        let d2ab = o.get_output(d2ab);
        let d3ab = o.get_output(d3ab);

        // let betaxi = mul_c(challenges.beta.c0, challenges.xi.c0, m_o);
        // let mut d2a1 = add_c(proof.eval_a.c0, betaxi, m_o);
        // d2a1 = add_c(d2a1, challenges.gamma.c0, m_o);

        // let mut d2a2 = mul_c(betaxi, vk.k1, m_o);
        // d2a2 = add_c(proof.eval_b.c0, d2a2, m_o);
        // d2a2 = add_c(d2a2, challenges.gamma.c0, m_o);

        // let mut d2a3 = mul_c(betaxi, vk.k2, m_o);
        // d2a3 = add_c(proof.eval_c.c0, d2a3, m_o);
        // d2a3 = add_c(d2a3, challenges.gamma.c0, m_o);

        // let d2a = mul_c(mul_c(mul_c(d2a1, d2a2, m_o), d2a3, m_o), challenges.alpha.c0, m_o);

        // let d2b = mul_c(l1.c0, sqr_c(challenges.alpha.c0, m_o), m_o);
        // let d2ab = add_c(add_c(d2a, d2b, m_o), challenges.u.c0, m_o);
        
        // let d3a = add_c(
        //     add_c(proof.eval_a.c0, mul_c(challenges.beta.c0, proof.eval_s1.c0, m_o), m_o),
        //     challenges.gamma.c0, m_o,
        // );

        // let d3b = add_c(
        //     add_c(proof.eval_b.c0, mul_c(challenges.beta.c0, proof.eval_s2.c0, m_o), m_o),
        //     challenges.gamma.c0, m_o
        // );

        // let d3c = mul_c(mul_c(challenges.alpha.c0, challenges.beta.c0, m_o), proof.eval_zw.c0, m_o);
        // let d3ab = mul_c(mul_c(d3a, d3b, m_o), d3c, m_o);

        let d4low = proof.T1;
        let d4mid = proof.T2.multiply_as_circuit(challenges.xin.c0, m);
        let d4high = proof.T3.multiply_as_circuit(mul_c(challenges.xin.c0, challenges.xin.c0, m_o), m);
        let mut d4 = d4mid.add_as_circuit(d4high, m);
        d4 = d4.add_as_circuit(d4low, m);
        d4 = d4.multiply_as_circuit(challenges.zh.c0, m);

        let d2 = proof.Z.multiply_as_circuit(d2ab, m);
        let d3 = vk.S3.multiply_as_circuit(d3ab, m);

        let mut d = d1.add_as_circuit(d2, m);
        d = d.add_as_circuit(d3.neg(m), m);
        d = d.add_as_circuit(d4.neg(m), m);

        d
    }

    // step 10: Compute full batched polynomial commitment F
    fn compute_F(
        proof: PlonkProof, challenges: PlonkChallenge, vk: PlonkVerificationKey, D: AffineG1, m: CircuitModulus
    ) -> AffineG1 {
        let mut v1a = proof.A.multiply_as_circuit(challenges.v1.c0, m);
        let res_add_d = v1a.add_as_circuit(D, m);

        let v2b = proof.B.multiply_as_circuit(challenges.v2.c0, m);
        let res_add_v2b = res_add_d.add_as_circuit(v2b, m);

        let v3c = proof.C.multiply_as_circuit(challenges.v3.c0, m);
        let res_add_v3c = res_add_v2b.add_as_circuit(v3c, m);

        let v4s1 = vk.S1.multiply_as_circuit(challenges.v4.c0, m);
        let res_add_v4s1 = res_add_v3c.add_as_circuit(v4s1, m);

        let v5s2 = vk.S2.multiply_as_circuit(challenges.v5.c0, m);
        let res = res_add_v4s1.add_as_circuit(v5s2, m);

        res
    }

    // step 11: Compute group-encoded batch evaluation E
    fn compute_E(proof: PlonkProof, challenges: PlonkChallenge, r0: Fq, m: CircuitModulus, m_o: CircuitModulus) -> AffineG1 {
        let mut res: AffineG1 = AffineG1Impl::one();
        let neg_r0 = neg_c(r0.c0, m_o);

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

        let outputs = match (e5,).new_inputs()
            .next(neg_r0)
            .next(challenges.v1.c0)
            .next(challenges.v2.c0)
            .next(challenges.v3.c0)
            .next(challenges.v4.c0)
            .next(challenges.v5.c0)
            .next(challenges.u.c0)
            .next(proof.eval_a.c0)
            .next(proof.eval_b.c0)
            .next(proof.eval_c.c0)
            .next(proof.eval_s1.c0)
            .next(proof.eval_s2.c0)
            .next(proof.eval_zw.c0)
            .done()
            .eval(m_o) {
                Result::Ok(outputs) => { outputs },
                Result::Err(_) => { panic!("Expected success") }
        };
        let e: u384 = outputs.get_output(e5);

        res = res.multiply_as_circuit(e, m);

        res
    }

    //step 12: Elliptic Curve Pairing: Batch validate all evaluations
    fn valid_pairing(
        proof: PlonkProof,
        challenges: PlonkChallenge,
        vk: PlonkVerificationKey,
        E: AffineG1,
        F: AffineG1, 
        m: CircuitModulus,
        m_o: CircuitModulus
    ) -> bool {
        let mut A1 = proof.Wxi;

        let Wxiw_mul_u = proof.Wxiw.multiply_as_circuit(challenges.u.c0, m);
        A1 = A1.add_as_circuit(Wxiw_mul_u, m);

        let mut B1 = proof.Wxi.multiply_as_circuit(challenges.xi.c0, m);
        let s = mul_c(mul_c(challenges.u.c0, challenges.xi.c0, m_o), vk.w, m_o);

        let Wxiw_mul_s = proof.Wxiw.multiply_as_circuit(s, m);
        B1 = B1.add_as_circuit(Wxiw_mul_s, m);

        B1 = B1.add_as_circuit(F, m);

        B1 = B1.add_as_circuit(E.neg(m), m);

        let g2_one = AffineG2Impl::one();

        let e_A1_vk_x2 = single_ate_pairing(A1, vk.X_2, m);
        let e_B1_g2_1 = single_ate_pairing(B1, g2_one, m);

        let res: bool = e_A1_vk_x2.c0 == e_B1_g2_1.c0;

        res
    }
}
