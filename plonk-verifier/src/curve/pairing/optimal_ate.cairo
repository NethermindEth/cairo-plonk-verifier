use core::circuit::CircuitModulus;
use core::debug::PrintTrait;

use plonk_verifier::curve::constants::FIELD_U384;
use plonk_verifier::curve::{groups, pairing::optimal_ate_impls};
use plonk_verifier::fields::{
    fq, Fq, Fq2, Fq6, Fq12, Fq12Exponentiation, Fq12Utils, FieldOps, FieldUtils,
};
use plonk_verifier::traits::{MillerPrecompute, MillerSteps};

use groups::{Affine, AffineG1, AffineG2, ECGroup, g1, g2};
use optimal_ate_impls::{SingleMillerPrecompute, SingleMillerSteps};
use plonk_verifier::curve::pairing::optimal_ate_impls::PreCompute;

#[derive(Copy, Drop)]
enum BitType {
    O,
    N,
    P,
}

fn ate_miller_loop<
    TG1,
    TG2,
    TPreC,
    M,
    +MillerPrecompute<TG1, TG2, TPreC, M>,
    +MillerSteps<TPreC, TG2, Fq12>,
    +Copy<M>,
    +Drop<TG1>,
    +Drop<TG2>,
    +Drop<TPreC>,
    +Drop<M>
>( 
    p: TG1, q: TG2, m: M 
) -> Fq12 {
    //gas::withdraw_gas().unwrap();
    //core::internal::revoke_ap_tracking();

    // Prepare precompute and q accumulator
    let (precompute, mut q_acc) = (p, q).precompute(m);
    
    ate_miller_loop_steps(precompute, ref q_acc)
}

// Pairing Implementation Revisited - Michael Scott
//
// The implementation below is the algorithm described below in a single loop.
//
//
// Algorithm 2: Calculate and store line functions for BLS12 curve Input: Q ∈ G2, P ∈ G1, curve parameter u
// Output: An array g of ⌊log2(u)⌋ line functions ∈ Fp12
// 1: T←Q
// 2: for i ← ⌊log2(u)⌋−1 to 0 do
// 3:     g[i] ← lT,T(P), T ← 2T
// 4:     if ui =1then
// 5:         g[i] ← g[i].lT,Q(P), T ← T + Q return g
//
// Algorithm 3: Miller loop for BLS12 curve
// Input: An array g of ⌊log2(u)⌋ line functions ∈ Fp12 Output: f ∈ Fp12
// 1: f ← 1
// 2: for i ← ⌊log2(u)⌋−1 to 0 do
// 3:     f ← f^2 . g[i]
// 4: return f
//
// -------------------------------------------------------------------------
//
// The algo below is effectively this:
// 1: f ← 1
// 2: for i ← ⌊log2(u)⌋−1 to 0 do
// 3:     f ← f^2
// 4:     Compute g[i] and mul with f based on the bit value
// 5: return f

fn miller_step<
    TG2, TPreC, +MillerSteps<TPreC, TG2, Fq12>, +Drop<TG2>, +Drop<TPreC>
>(
    precompute: @TPreC, bit_type: @BitType, ref q_acc: TG2, ref f: Fq12
) {
    precompute.sqr_target(ref q_acc, ref f);
    match bit_type {
        BitType::O => precompute.miller_bit_o(ref q_acc, ref f),
        BitType::N => precompute.miller_bit_n(ref q_acc, ref f),
        BitType::P => precompute.miller_bit_p(ref q_acc, ref f),
    }
}

fn ate_miller_loop_steps<
    TG2, TPreC, +MillerSteps<TPreC, TG2, Fq12>, +Drop<TG2>, +Drop<TPreC>,
>(
    precompute: TPreC, ref q_acc: TG2
) -> Fq12 {
    // ate_loop[64] = O and ate_loop[63] = N
    let mut f = precompute.miller_first_second(ref q_acc);

    let steps = [
        BitType::O, // i=62
        BitType::P, // i=61
        BitType::O, // i=60
        BitType::O, // i=59
        BitType::O, // i=58
        BitType::N, // i=57
        BitType::O, // i=56
        BitType::N, // i=55
        BitType::O, // i=54
        BitType::O, // i=53
        BitType::O, // i=52
        BitType::N, // i=51
        BitType::O, // i=50
        BitType::P, // i=49
        BitType::O, // i=48
        BitType::N, // i=47
        BitType::O, // i=46
        BitType::O, // i=45
        BitType::N, // i=44
        BitType::O, // i=43
        BitType::O, // i=42
        BitType::O, // i=41
        BitType::O, // i=40
        BitType::O, // i=39
        BitType::P, // i=38
        BitType::O, // i=37
        BitType::O, // i=36
        BitType::N, // i=35
        BitType::O, // i=34
        BitType::P, // i=33
        BitType::O, // i=32
        BitType::O, // i=31
        BitType::N, // i=30
        BitType::O, // i=29
        BitType::O, // i=28
        BitType::O, // i=27
        BitType::O, // i=26
        BitType::N, // i=25
        BitType::O, // i=24
        BitType::P, // i=23
        BitType::O, // i=22
        BitType::O, // i=21
        BitType::O, // i=20
        BitType::N, // i=19
        BitType::O, // i=18
        BitType::N, // i=17
        BitType::O, // i=16
        BitType::O, // i=15
        BitType::P, // i=14
        BitType::O, // i=13
        BitType::O, // i=12
        BitType::O, // i=11
        BitType::N, // i=10
        BitType::O, // i=9
        BitType::O, // i=8
        BitType::N, // i=7
        BitType::O, // i=6
        BitType::P, // i=5
        BitType::O, // i=4
        BitType::P, // i=3
        BitType::O, // i=2
        BitType::O, // i=1
        BitType::O, // i=0
    ].span();

    for step in steps {
        miller_step(@precompute, step, ref q_acc, ref f);
    };

    precompute.miller_last(ref q_acc, ref f);
   
    f
}

fn single_ate_pairing(p: AffineG1, q: AffineG2, m: CircuitModulus) -> Fq12 {
    ate_miller_loop(p, q, m).final_exponentiation(m)
}
