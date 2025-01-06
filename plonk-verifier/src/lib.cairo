mod plonk {
    mod verify;
    mod constants;
    mod types;
    mod transcript;
    mod utils;
    // #[cfg(test)]
    // mod plonk_tests;
}
mod traits;
use traits::{FieldOps, FieldUtils, FieldEqs};

mod curve; 
use curve::{groups as g, pairing};

// Todo: Refactor as individual mods. 
mod circuits {
    mod typedefs {
        mod affine;
        mod fq_2_type;
        mod fq_6_type;
        mod fq_12_type; 
        mod add_sub_neg;
    }
    mod affine_circuits;
    mod fq_circuits;
    mod fq_2_circuits;
    mod fq_6_circuits;
    mod fq_12_circuits;
}

// Fix imports with proper libs
mod fields {
    mod fq_generics;
    mod fq_sparse;
    mod fq_1;
    mod fq_2;
    mod fq_6;
    mod fq_12;
    mod fq_12_direct;
    mod fq_12_squaring;
    mod fq_12_exponentiation;
    mod frobenius;
    // mod print;
    // mod utils;
    // #[cfg(test)]
    // mod tests {
        // mod fq12;
        // mod fq6;
        // mod fq2;
        // mod fq;
        // mod fq12_expo;
        // mod fq_sparse;
        // mod u512;
        // mod frobenius;
        // mod utils;
    // }

    use fq_1::{Fq, FqOps, FqUtils, fq, FqIntoU256};
    use fq_2::{Fq2, Fq2Ops, Fq2Utils, fq2, Fq2Frobenius};
    use fq_6::{Fq6, Fq6Ops, Fq6Utils, fq6, Fq6Frobenius};
    use fq_12::{Fq12, Fq12Ops, Fq12Utils, fq12, Fq12Frobenius};
    use fq_12_exponentiation::Fq12Exponentiation;
    use fq_sparse::{
        FqSparse, FqSparseTrait, Fq12Sparse034, Fq12Sparse01234, Fq6Sparse01, sparse_fq6
    };
    pub type FS034 = Fq12Sparse034;
    pub type FS01234 = Fq12Sparse01234;
    pub type FS01 = Fq6Sparse01;
    use fq_12_squaring::{Fq12Squaring, Fq12SquaringCircuit, Krbn2345};
    use plonk_verifier::traits::{FieldUtils, FieldOps};
}

