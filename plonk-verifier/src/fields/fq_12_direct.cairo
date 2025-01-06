use core::circuit::CircuitModulus;

use plonk_verifier::curve::{circuit_scale_9, constants::FIELD_U384};
use plonk_verifier::fields::{
    fq, fq12, Fq, Fq2, Fq6, Fq12, FieldOps, FieldUtils, FS01, FS034, FS01234,
};

// #[inline(always)]
fn fq12_from_fq(
    a0: Fq, a1: Fq, a2: Fq, a3: Fq, a4: Fq, a5: Fq, b0: Fq, b1: Fq, b2: Fq, b3: Fq, b4: Fq, b5: Fq
) -> Fq12 {
    Fq12 {
        c0: Fq6 {
            c0: Fq2 { c0: a0, c1: a1 }, c1: Fq2 { c0: a2, c1: a3 }, c2: Fq2 { c0: a4, c1: a5 }
        },
        c1: Fq6 {
            c0: Fq2 { c0: b0, c1: b1 }, c1: Fq2 { c0: b2, c1: b3 }, c2: Fq2 { c0: b4, c1: b5 }
        },
    }
}

fn direct_to_tower(x: Fq12, m: CircuitModulus) -> Fq12 {
    let Fq12 { c0, c1 } = x;
    let Fq6 { c0: b0, c1: b1, c2: b2 } = c0;
    let Fq6 { c0: b3, c1: b4, c2: b5 } = c1;
    let Fq2 { c0: a0, c1: a1 } = b0;
    let Fq2 { c0: a2, c1: a3 } = b1;
    let Fq2 { c0: a4, c1: a5 } = b2;
    let Fq2 { c0: a6, c1: a7 } = b3;
    let Fq2 { c0: a8, c1: a9 } = b4;
    let Fq2 { c0: a10, c1: a11 } = b5;

    fq12_from_fq(
        a0.add(circuit_scale_9(a6, m), m),
        a6,
        a2.add(circuit_scale_9(a8, m), m),
        a8,
        a4.add(circuit_scale_9(a10, m), m),
        a10,
        a1.add(circuit_scale_9(a7, m), m),
        a7,
        a3.add(circuit_scale_9(a9, m), m),
        a9,
        a5.add(circuit_scale_9(a11, m), m),
        a11,
    )
}
type Fq12Direct = (Fq, Fq, Fq, Fq, Fq, Fq, Fq, Fq, Fq, Fq, Fq, Fq);

impl Fq12IntoFq12Direct of Into<Fq12, Fq12Direct> {
    // #[inline(always)]
    fn into(self: Fq12) -> Fq12Direct {
        let Fq12 { c0, c1 } = self;
        let Fq6 { c0: b0, c1: b1, c2: b2 } = c0;
        let Fq6 { c0: b3, c1: b4, c2: b5 } = c1; 
        let Fq2 { c0: a0, c1: a1 } = b0;
        let Fq2 { c0: a2, c1: a3 } = b1;
        let Fq2 { c0: a4, c1: a5 } = b2;
        let Fq2 { c0: a6, c1: a7 } = b3;
        let Fq2 { c0: a8, c1: a9 } = b4;
        let Fq2 { c0: a10, c1: a11 } = b5;
        (a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11)
    }
}

impl Fq12DirectIntoFq12 of Into<Fq12Direct, Fq12> {
    // #[inline(always)]
    fn into(self: Fq12Direct) -> Fq12 {
        let (a0, a1, a2, a3, a4, a5, b0, b1, b2, b3, b4, b5) = self;
        fq12_from_fq(a0, a1, a2, a3, a4, a5, b0, b1, b2, b3, b4, b5)
    }
}

fn tower_to_direct(x: Fq12, m: CircuitModulus) -> Fq12Direct {
    let Fq12 { c0, c1 } = x;
    let Fq6 { c0: b0, c1: b1, c2: b2 } = c0;
    let Fq6 { c0: b3, c1: b4, c2: b5 } = c1; 
    let Fq2 { c0: a0, c1: a1 } = b0;
    let Fq2 { c0: a2, c1: a3 } = b1;
    let Fq2 { c0: a4, c1: a5 } = b2;
    let Fq2 { c0: a6, c1: a7 } = b3;
    let Fq2 { c0: a8, c1: a9 } = b4;
    let Fq2 { c0: a10, c1: a11 } = b5;

    (
        a0.sub(circuit_scale_9(a1, m), m),
        a6.sub(circuit_scale_9(a7, m), m),
        a2.sub(circuit_scale_9(a3, m), m),
        a8.sub(circuit_scale_9(a9, m), m),
        a4.sub(circuit_scale_9(a5, m), m),
        a10.sub(circuit_scale_9(a11, m), m),
        a1,
        a7,
        a3,
        a9,
        a5,
        a11,
    )
}

fn tower01234_to_direct(x: FS01234, m: CircuitModulus) -> ((Fq, Fq, Fq, Fq, Fq), (Fq, Fq, Fq, Fq, Fq),) {
    let FS01234 { c0, c1 } = x;
    let Fq6 { c0: b0, c1: b1, c2: b2 } = c0;
    let FS01 { c0: b3, c1: b4 } = c1; 
    let Fq2 { c0: a0, c1: a1 } = b0;
    let Fq2 { c0: a2, c1: a3 } = b1;
    let Fq2 { c0: a4, c1: a5 } = b2;
    let Fq2 { c0: a6, c1: a7 } = b3;
    let Fq2 { c0: a8, c1: a9 } = b4;

    let a1x9 = circuit_scale_9(a1, m);
    let a7x9 = circuit_scale_9(a7, m);
    let a3x9 = circuit_scale_9(a3, m);
    let a9x9 = circuit_scale_9(a9, m);
    let a5x9 = circuit_scale_9(a5, m);
    ((a0.sub(a1x9, m), a6.sub(a7x9, m), a2.sub(a3x9, m), a8.sub(a9x9, m), a4.sub(a5x9, m)), (a1, a7, a3, a9, a5,),)
}

struct FS034Direct {
    c1: Fq,
    c3: Fq,
    c7: Fq,
    c9: Fq,
}

fn tower034_to_direct(x: FS034, m: CircuitModulus) -> FS034Direct {
    let FS034 { c3: Fq2 { c0: a6, c1: a7 }, c4: Fq2 { c0: a8, c1: a9 } } = x;

    FS034Direct { c1: a6.sub(circuit_scale_9(a7, m), m), c3: a8.sub(circuit_scale_9(a9, m), m), c7: a7, c9: a9, }
}