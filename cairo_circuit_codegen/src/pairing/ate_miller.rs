use crate::fields::{affine::Affine, fq::Fq, fq12::Fq12, fq2::Fq2};

use super::{line::Precompute, MillerPrecompute, MillerSteps};

pub fn ate_miller_loop(p: Affine<Fq>, q: Affine<Fq2>, inp: Option<[usize; 6]>) -> Fq12 {
    let (mut precompute, mut q_acc) = <Precompute as MillerPrecompute>::precompute(p, q, inp);
    let f = ate_miller_loop_steps(&mut precompute, &mut q_acc);
    f
}

pub fn ate_miller_loop_steps(precompute: &mut Precompute, q_acc: &mut Affine<Fq2>) -> Fq12 {
    let mut f = ate_miller_loop_steps_first_half(precompute, q_acc);
    f
}  

pub fn ate_miller_loop_steps_first_half(precompute: &mut Precompute, q_acc: &mut Affine<Fq2>) -> Fq12{
    let mut f = precompute.miller_first_second(64, 63, q_acc);
    precompute.sqr_target(62, q_acc, &mut f);
    precompute.miller_bit_o(62, q_acc, &mut f); // ate_loop[62] = O
    precompute.sqr_target(61, q_acc, &mut f);
    precompute.miller_bit_p(61, q_acc, &mut f); // ate_loop[61] = P
    precompute.sqr_target(60, q_acc, &mut f);
    precompute.miller_bit_o(60, q_acc, &mut f); // ate_loop[60] = O
    precompute.sqr_target(59, q_acc, &mut f);
    precompute.miller_bit_o(59, q_acc, &mut f); // ate_loop[59] = O
    precompute.sqr_target(58, q_acc, &mut f);
    precompute.miller_bit_o(58, q_acc, &mut f); // ate_loop[58] = O
    precompute.sqr_target(57, q_acc, &mut f);
    precompute.miller_bit_n(57, q_acc, &mut f); // ate_loop[57] = N
    precompute.sqr_target(56, q_acc, &mut f);
    precompute.miller_bit_o(56, q_acc, &mut f); // ate_loop[56] = O
    precompute.sqr_target(55, q_acc, &mut f);
    precompute.miller_bit_n(55, q_acc, &mut f); // ate_loop[55] = N
    precompute.sqr_target(54, q_acc, &mut f);
    precompute.miller_bit_o(54, q_acc, &mut f); // ate_loop[54] = O
    precompute.sqr_target(53, q_acc, &mut f);
    precompute.miller_bit_o(53, q_acc, &mut f); // ate_loop[53] = O
    precompute.sqr_target(52, q_acc, &mut f);
    precompute.miller_bit_o(52, q_acc, &mut f); // ate_loop[52] = O
    precompute.sqr_target(51, q_acc, &mut f);
    precompute.miller_bit_n(51, q_acc, &mut f); // ate_loop[51] = N
    precompute.sqr_target(50, q_acc, &mut f);
    precompute.miller_bit_o(50, q_acc, &mut f); // ate_loop[50] = O
    precompute.sqr_target(49, q_acc, &mut f);
    precompute.miller_bit_p(49, q_acc, &mut f); // ate_loop[49] = P
    precompute.sqr_target(48, q_acc, &mut f);
    precompute.miller_bit_o(48, q_acc, &mut f); // ate_loop[48] = O
    precompute.sqr_target(47, q_acc, &mut f);
    precompute.miller_bit_n(47, q_acc, &mut f); // ate_loop[47] = N
    precompute.sqr_target(46, q_acc, &mut f);
    precompute.miller_bit_o(46, q_acc, &mut f); // ate_loop[46] = O
    precompute.sqr_target(45, q_acc, &mut f);
    precompute.miller_bit_o(45, q_acc, &mut f); // ate_loop[45] = O
    precompute.sqr_target(44, q_acc, &mut f);
    precompute.miller_bit_n(44, q_acc, &mut f); // ate_loop[44] = N
    precompute.sqr_target(43, q_acc, &mut f);
    precompute.miller_bit_o(43, q_acc, &mut f); // ate_loop[43] = O
    precompute.sqr_target(42, q_acc, &mut f);
    precompute.miller_bit_o(42, q_acc, &mut f); // ate_loop[42] = O
    precompute.sqr_target(41, q_acc, &mut f);
    precompute.miller_bit_o(41, q_acc, &mut f); // ate_loop[41] = O
    precompute.sqr_target(40, q_acc, &mut f);
    precompute.miller_bit_o(40, q_acc, &mut f); // ate_loop[40] = O
    precompute.sqr_target(39, q_acc, &mut f);
    precompute.miller_bit_o(39, q_acc, &mut f); // ate_loop[39] = O
    precompute.sqr_target(38, q_acc, &mut f);
    precompute.miller_bit_p(38, q_acc, &mut f); // ate_loop[38] = P
    precompute.sqr_target(37, q_acc, &mut f);
    precompute.miller_bit_o(37, q_acc, &mut f); // ate_loop[37] = O
    precompute.sqr_target(36, q_acc, &mut f);
    precompute.miller_bit_o(36, q_acc, &mut f); // ate_loop[36] = O
    precompute.sqr_target(35, q_acc, &mut f);
    precompute.miller_bit_n(35, q_acc, &mut f); // ate_loop[35] = N
    precompute.sqr_target(34, q_acc, &mut f);
    precompute.miller_bit_o(34, q_acc, &mut f); // ate_loop[34] = O
    precompute.sqr_target(33, q_acc, &mut f);
    precompute.miller_bit_p(33, q_acc, &mut f); // ate_loop[33] = P
    precompute.sqr_target(32, q_acc, &mut f);
    precompute.miller_bit_o(32, q_acc, &mut f); // ate_loop[32] = O
    precompute.sqr_target(31, q_acc, &mut f);
    precompute.miller_bit_o(31, q_acc, &mut f); // ate_loop[31] = O

    f
}

#[cfg(test)]
mod miller_test {
    use sysinfo::{System, SystemExt};

    use crate::{
        circuit::builder::CairoCodeBuilder, fields::{affine::Affine, fq::Fq, fq12::Fq12, fq2::Fq2}, pairing::{line::Precompute, MillerPrecompute, MillerSteps}, utils::utils::write_stdout
    };

    use super::ate_miller_loop;    
    #[test]
    fn test_miller_precompute() {
        let g1: Affine<Fq> = Affine::<Fq>::new_input([0, 1]);
        let g2: Affine<Fq2> = Affine::<Fq2>::new_input([2, 3, 4, 5]);
        let miller_idx = [0, 1, 2, 3, 4, 5];

        let (mut precompute, mut q_acc) = <Precompute as MillerPrecompute>::precompute(g1, g2, Some(miller_idx));
        
        let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
        builder.add_circuit(precompute, None);
        builder.add_circuit(q_acc, None);
        
        let code = builder.build();
        write_stdout("out.cairo", code);
    }

    #[test]
    fn test_miller_sqr() {
        
    }

    // Not enough memory
    // #[test]
    // fn test_miller_first_second() {
    //     let mut system = System::new_all();
    //     system.refresh_all();

    //     let g1: Affine<Fq> = Affine::<Fq>::new_input([0, 1]);
    //     let g2: Affine<Fq2> = Affine::<Fq2>::new_input([2, 3, 4, 5]);
    //     let miller_idx = [0, 1, 2, 3, 4, 5];

    //     let (mut precompute, mut q_acc) = <Precompute as MillerPrecompute>::precompute(g1, g2, Some(miller_idx));
    //     let f = precompute.miller_first_second(64, 63, &mut q_acc);

    //     println!("Total memory: {} KB", system.total_memory());
    //     println!("Used memory: {} KB", system.used_memory());
    //     println!("Free memory: {} KB", system.free_memory());

    //     let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
    //     builder.add_circuit(precompute);
    //     builder.add_circuit(q_acc);
    //     builder.add_circuit(f);

        
    //     let code = builder.build();
    //     write_stdout("out.cairo", code);
    // }

    #[test]
    fn test_miller_bit_o() {
        let g1: Affine<Fq> = Affine::<Fq>::new_input([0, 1]);
        let g2: Affine<Fq2> = Affine::<Fq2>::new_input([2, 3, 4, 5]);
        let mut f: Fq12 = Fq12::new_input([6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]);
        let miller_idx = [0, 1, 2, 3, 4, 5];

        let (mut precompute, mut q_acc) = <Precompute as MillerPrecompute>::precompute(g1, g2, Some(miller_idx));
        precompute.miller_bit_o(0, &mut q_acc, &mut f);

        let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
        //builder.add_circuit(precompute);
        builder.add_circuit(q_acc, None);
        builder.add_circuit(f, None);

        let code = builder.build();
        write_stdout("out.cairo", code);
    }
    
    #[test]
    fn test_miller_bit_p() {

    }

    #[test]
    fn test_miller_bit_n() {

    }
    
    #[test]
    fn test_miller_last() {

    }

    // #[test]
    // fn test_precompuate_first_half() {
    //     let g1: Affine<Fq> = Affine::<Fq>::new_input([0, 1]);
    //     let g2: Affine<Fq2> = Affine::<Fq2>::new_input([2, 3, 4, 5]);
    //     let miller_idx = [0, 1, 2, 3, 4, 5];

    //     let f = ate_miller_loop(g1, g2, Some(miller_idx));
        
    //     let mut builder: CairoCodeBuilder = CairoCodeBuilder::new();
    //     builder.add_circuit(f);

    //     let code = builder.build();
    //     write_stdout("out.cairo", code);
    // }
}