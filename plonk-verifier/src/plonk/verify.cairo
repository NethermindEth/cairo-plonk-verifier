use core::{
    array::ArrayTrait, clone::Clone, cmp::max, debug::{PrintTrait, print_byte_array_as_string},
    fmt::Display, option::OptionTrait, traits::{Destruct, Into, TryInto},
};

use core::circuit::{
    AddInputResultTrait, AddMod, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
    CircuitOutputsTrait, EvalCircuitResult, EvalCircuitTrait, RangeCheck96, U384Zero, u96, u384,
    circuit_add, circuit_inverse, circuit_mul, circuit_sub,
};
use core::circuit::conversions::from_u256;

use plonk_verifier::{
    curve::{
        groups::{g1, g2, AffineG1, AffineG2, AffineG2Impl, ECOperations, ECOperationsCircuitFq},
        constants::{FIELD_U384, ORDER, ORDER_384, ORDER_NZ, ORDER_U384, get_field_nz},
    },
        //neg_o, sqr_nz, mul, mul_u, mul_nz, div_nz, add_nz, sub_u, sub, u512,
    fields::{fq, Fq, Fq12, Fq12Exponentiation, Fq12Utils, FqUtils},
    math::circuit_mod::{
        mul_c, sqr_c, sqr_co, sub_c, sub_co, add_c, add_co, div_c, div_co, neg_co, mul_co
    },
    pairing::{
        optimal_ate::{single_ate_pairing, ate_miller_loop},
        tate_bkls::{tate_pairing, tate_miller_loop},
    },
    plonk::{
        transcript::{Keccak256Transcript, Transcript, TranscriptElement},
        types::{PlonkChallenge, PlonkProof, PlonkVerificationKey},
    },
    traits::{FieldMulShortcuts, FieldOps, FieldShortcuts, FieldUtils},
};


#[generate_trait]
impl PlonkVerifier of PVerifier {
    fn verify(
        verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: Array<u384>
    ) -> bool {
        let mut result = true;
        result = result
            && Self::is_on_curve(proof.A)
            && Self::is_on_curve(proof.B)
            && Self::is_on_curve(proof.C)
            && Self::is_on_curve(proof.Z)
            && Self::is_on_curve(proof.T1)
            && Self::is_on_curve(proof.T2)
            && Self::is_on_curve(proof.T3)
            && Self::is_on_curve(proof.Wxi)
            && Self::is_on_curve(proof.Wxiw);

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
            verification_key, proof, publicSignals.clone()
        );

        let (L, challenges) = Self::compute_lagrange_evaluations(verification_key, challenges);

        let PI = Self::compute_PI(publicSignals.clone(), L.clone());

        let R0 = Self::compute_R0(proof, challenges, PI, L[1].clone());

        let D = Self::compute_D(proof, challenges, verification_key, L[1].clone());

        let F = Self::compute_F(proof, challenges, verification_key, D);

        let E = Self::compute_E(proof, challenges, R0);

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
        let in1 = pt.x.c0;
        let in2 = pt.y.c0;

        let outputs = match (out,).new_inputs().next(in1).next(in2).done().eval(modulus) {
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
        (num.c0).try_into().unwrap() < ORDER
    }

    //step 3: check proof public inputs match the verification key
    fn check_public_inputs_length(len_a: u256, len_b: u256) -> bool {
        len_a == len_b
    }

    // step 4: compute challenge
    fn compute_challenges(
        verification_key: PlonkVerificationKey, proof: PlonkProof, publicSignals: Array<u384>
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
        beta_transcript.add_poly_commitment(verification_key.Qm);
        beta_transcript.add_poly_commitment(verification_key.Ql);
        beta_transcript.add_poly_commitment(verification_key.Qr);
        beta_transcript.add_poly_commitment(verification_key.Qo);
        beta_transcript.add_poly_commitment(verification_key.Qc);
        beta_transcript.add_poly_commitment(verification_key.S1);
        beta_transcript.add_poly_commitment(verification_key.S2);
        beta_transcript.add_poly_commitment(verification_key.S3);

        for i in 0
            ..publicSignals.len() {
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
        challenges.v2 = fq(mul_co(challenges.v1.c0, challenges.v1.c0));
        challenges.v3 = fq(mul_co(challenges.v2.c0, challenges.v1.c0));
        challenges.v4 = fq(mul_co(challenges.v3.c0, challenges.v1.c0));
        challenges.v5 = fq(mul_co(challenges.v4.c0, challenges.v1.c0));

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
        let mut domain_size = FqUtils::one();

        let mut i = 0;
        while i < verification_key.power {
            let sqr_mod = sqr_co(xin.c0);
            xin = fq(sqr_mod);
            domain_size = domain_size.scale(2);
            i += 1;
        };

        challenges.xin = fq(xin.c0);
        challenges.zh = xin.sub(FqUtils::one());

        let mut lagrange_evaluations: Array<Fq> = array![];
        lagrange_evaluations.append(FqUtils::zero());

        let n: Fq = domain_size;
        let mut w: Fq = FqUtils::one();

        let n_public: u32 = verification_key.nPublic.try_into().unwrap();

        let mut j = 1;
        while j <= max(1, n_public) {
            let xi_sub_w = challenges.xi.sub(w);
            let xi_mul_n = mul_co(n.c0, xi_sub_w.c0);
            let w_mul_zh = mul_co(w.c0, challenges.zh.c0);
            let l_i = div_co(w_mul_zh, xi_mul_n);
            lagrange_evaluations.append(fq(l_i));

            w = fq(mul_co(w.c0, verification_key.w));

            j += 1;
        };

        (lagrange_evaluations, challenges)
    }

    // step 7: compute public input polynomial evaluation
    fn compute_PI(publicSignals: Array<u384>, L: Array<Fq>) -> Fq {
        let mut PI: Fq = FqUtils::zero();
        let mut i = 0;

        while i < publicSignals.len() {
            let w: u384 = publicSignals[i].clone();
            let w_mul_L: u384 = mul_co(w, L[i + 1].c0.clone());
            let pi = sub_co(PI.c0, w_mul_L);

            PI = fq(pi);
            i += 1;
        };

        PI
    }

    // step 8: compute r constant
    fn compute_R0(proof: PlonkProof, challenges: PlonkChallenge, PI: Fq, L1: Fq) -> Fq {
        let e1: u384 = PI.c0;
        let e2: u384 = mul_co(L1.c0, sqr_co(challenges.alpha.c0));

        let mut e3a = add_co(proof.eval_a.c0, mul_co(challenges.beta.c0, proof.eval_s1.c0));
        e3a = add_co(e3a, challenges.gamma.c0);

        let mut e3b = add_co(proof.eval_b.c0, mul_co(challenges.beta.c0, proof.eval_s2.c0));
        e3b = add_co(e3b, challenges.gamma.c0);

        let mut e3c = add_co(proof.eval_c.c0, challenges.gamma.c0);

        let mut e3 = mul_co(mul_co(e3a, e3b), e3c);
        e3 = mul_co(e3, proof.eval_zw.c0);
        e3 = mul_co(e3, challenges.alpha.c0);

        let r0 = sub_co(sub_co(e1, e2), e3);

        fq(r0)
    }

    // step 9: Compute first part of batched polynomial commitment D
    fn compute_D(
        proof: PlonkProof, challenges: PlonkChallenge, vk: PlonkVerificationKey, l1: Fq
    ) -> AffineG1 {
        let mut d1 = vk.Qm.multiply_as_circuit((mul_co(proof.eval_a.c0, proof.eval_b.c0)));
        d1 = d1.add(vk.Ql.multiply_as_circuit(proof.eval_a.c0));
        d1 = d1.add(vk.Qr.multiply_as_circuit(proof.eval_b.c0));
        d1 = d1.add(vk.Qo.multiply_as_circuit(proof.eval_c.c0));
        d1 = d1.add(vk.Qc);

        let betaxi = mul_co(challenges.beta.c0, challenges.xi.c0);
        let mut d2a1 = add_co(proof.eval_a.c0, betaxi);
        d2a1 = add_co(d2a1, challenges.gamma.c0);

        let mut d2a2 = mul_co(betaxi, vk.k1);
        d2a2 = add_co(proof.eval_b.c0, d2a2);
        d2a2 = add_co(d2a2, challenges.gamma.c0);

        let mut d2a3 = mul_co(betaxi, vk.k2);
        d2a3 = add_co(proof.eval_c.c0, d2a3);
        d2a3 = add_co(d2a3, challenges.gamma.c0);

        let d2a = mul_co(mul_co(mul_co(d2a1, d2a2), d2a3), challenges.alpha.c0);

        let d2b = mul_co(l1.c0, sqr_co(challenges.alpha.c0));

        let d2 = proof.Z.multiply_as_circuit(add_co(add_co(d2a, d2b), challenges.u.c0));

        let d3a = add_co(
            add_co(proof.eval_a.c0, mul_co(challenges.beta.c0, proof.eval_s1.c0)),
            challenges.gamma.c0,
        );

        let d3b = add_co(
            add_co(proof.eval_b.c0, mul_co(challenges.beta.c0, proof.eval_s2.c0)),
            challenges.gamma.c0
        );

        let d3c = mul_co(mul_co(challenges.alpha.c0, challenges.beta.c0), proof.eval_zw.c0);

        let d3 = vk.S3.multiply_as_circuit(mul_co(mul_co(d3a, d3b), d3c));

        let d4low = proof.T1;
        let d4mid = proof.T2.multiply_as_circuit(challenges.xin.c0);
        let d4high = proof.T3.multiply_as_circuit(sqr_co(challenges.xin.c0));
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
        let neg_r0 = neg_co(r0.c0);

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
            match (e5,)
                .new_inputs()
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
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };
        let e: u384 = outputs.get_output(e5).try_into().unwrap();

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
        let s = mul_co(mul_co(challenges.u.c0, challenges.xi.c0), vk.w);

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
