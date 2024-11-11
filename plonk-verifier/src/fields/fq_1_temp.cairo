use core::traits::TryInto;
use plonk_verifier::curve::{FIELD, get_field_nz, add, sub_field, mul, scl, sqr, div, neg, inv};

use plonk_verifier::curve::{
    add_u, sub_u, mul_u, sqr_u, scl_u, u512_reduce, u512_add_u256, u512_sub_u256
};
use core::integer::{u128, u256, u512};
use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
use plonk_verifier::traits::{FieldUtils, FieldOps, FieldShortcuts, FieldMulShortcuts};
use debug::PrintTrait;
use core::circuit::conversions::{from_u128, from_u256};

use core::circuit::{
    CircuitElement, CircuitInput, circuit_add,circuit_sub,circuit_inverse, circuit_mul, EvalCircuitTrait, CircuitOutputsTrait,
    CircuitModulus, AddInputResultTrait, CircuitInputs, u384
};

use core::internal::bounded_int::BoundedInt;
use core::traits::Into;



use plonk_verifier::curve::constants::FIELD_U384;


#[derive(Copy, Drop, Serde, Debug)]
struct Fq {
    c0: u256
}


#[inline(always)]
fn fq(c0: u256) -> Fq {
    Fq { c0 }
}

impl FqIntoU512Tuple of Into<Fq, u512> {
    #[inline(always)]
    fn into(self: Fq) -> u512 {
        u512 { limb0: self.c0.low,
               limb1: self.c0.high,
               limb2: 0,
               limb3: 0, }
    }
}

trait Convert {
    fn to_u256(self: u128) -> u256;
}

impl U128ToU256 of Convert {
    fn to_u256(self: u128) -> u256 {
        u256 {
            low: self,
            high: 0_u128,
        }
    }
}

//----------------------------------------------------



//----------------------------------------------------

impl FqShort of FieldShortcuts<Fq> {
    #[inline(always)]
    fn u_add(self: Fq, rhs: Fq) -> Fq {
        // Operation without modding can only be done like 4 times
        Fq { c0: add_u(self.c0, rhs.c0), }
    }

    #[inline(always)]
    fn u_sub(self: Fq, rhs: Fq) -> Fq {
        Fq { c0: sub_u(self.c0, rhs.c0), }
    }

    #[inline(always)]
    fn fix_mod(self: Fq) -> Fq {
        let (_q, c0, _) = integer::u256_safe_divmod(self.c0, get_field_nz());
        Fq { c0 }
    }
}

impl FqMulShort of FieldMulShortcuts<Fq, u512> {
    #[inline(always)]
    fn u_mul(self: Fq, rhs: Fq) -> u512 {
        
        mul_u(self.c0, rhs.c0)
        
        //let a0 = CircuitElement::<CircuitInput<0>> {};
        //let a1 = CircuitElement::<CircuitInput<1>> {};

        // Define the multiplication circuit
        //let result = circuit_mul(a0, a1);

        // Set the modulus (replace FIELD_U384 with your specific modulus)
        //let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        // Convert inputs to u384
        //let a0_u384 = u384::from(self.c0);
        //let b0_u384 = u384::from(rhs.c0);

        // Evaluate the circuit
        //let outputs = match (result,)
        //    .new_inputs()
        //    .next(a0_u384)
        //    .next(b0_u384)
        //    .done()
       //     .eval(modulus)
       // {
       //     Result::Ok(outputs) => outputs,
       //     Result::Err(_) => panic("ERROR in circuit FQ_MUL_512"),
       // };

        // Retrieve the output as u384
        //let res_u384: u384 = outputs.get_output(result).try_into().unwrap();

        // Convert u384 to u512
        
        
        //let value_u512 = 1
    }

    #[inline(always)]
    fn u512_add_fq(self: u512, rhs: Fq) -> u512 {
        u512_add_u256(self, rhs.c0)
    }

    #[inline(always)]
    fn u512_sub_fq(self: u512, rhs: Fq) -> u512 {
        u512_sub_u256(self, rhs.c0)
    }

    #[inline(always)]
    fn u_sqr(self: Fq) -> u512 {
        sqr_u(self.c0)
    }

    #[inline(always)]
    fn to_fq(self: u512, field_nz: NonZero<u256>) -> Fq {
        fq(u512_reduce(self, field_nz))
    }
}

impl FqUtils of FieldUtils<Fq, u128> {
    #[inline(always)]
    fn one() -> Fq {
        fq(1)
    }

    #[inline(always)]
    fn zero() -> Fq {
        fq(0)
    }

    #[inline(always)]
    fn scale(self: Fq, by: u128) -> Fq {
        //Fq { c0: scl(self.c0, by) }
        

        let a_c0 = CircuitElement::<CircuitInput<0>> {};
        let scalar = CircuitElement::<CircuitInput<2>> {};

        let scaled = circuit_mul(a_c0, scalar);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let a0 = from_u256(self.c0);
        let scalar = from_u256(by.to_u256());

        let outputs =
            match (scaled,)
                .new_inputs()
                .next(a0)
                .next(scalar)
                .done()
                .eval(modulus) {
            Result::Ok(outputs) => { outputs },
            Result::Err(_) => { panic!("Expected success") }
        };

        let res = Fq { c0: outputs.get_output(scaled).try_into().unwrap() };

        res

    }

    #[inline(always)]
    fn mul_by_nonresidue(self: Fq,) -> Fq {
        if self.c0 == 0 {
            self
        } else {
            -self
        }
    }

    #[inline(always)]
    fn conjugate(self: Fq) -> Fq {
        assert(false, 'no_impl: fq conjugate');
        FieldUtils::zero()
    }

    #[inline(always)]
    fn frobenius_map(self: Fq, power: usize) -> Fq {
        assert(false, 'no_impl: fq frobenius_map');
        fq(0)
    }
}

impl FqOps of FieldOps<Fq> {
    #[inline(always)]
    fn add(self: Fq, rhs: Fq) -> Fq {
        // Create circuit elements for the inputs
        let a0 = CircuitElement::<CircuitInput<0>>{};
        let a1 = CircuitElement::<CircuitInput<1>>{};

        let result = circuit_add(a0, a1);

        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

        let a0 = from_u256(self.c0);
        let b0 = from_u256(rhs.c0);


        let outputs =
            match (result,).new_inputs()
                           .next(a0)
                           .next(b0)
                           .done()
                           .eval(modulus) {
                                            Result::Ok(outputs) => { outputs },
                                            Result::Err(_) => { panic!("ERROR in circuit FQ_ADD") }
        };

        let outFq = Fq { c0: outputs.get_output(result).try_into().unwrap()};
        outFq
        
    }

    #[inline(always)]
    fn sub(self: Fq, rhs: Fq) -> Fq {
    //fq(sub_field(self.c0, rhs.c0))
    // Create circuit elements for the inputs
    let a0 = CircuitElement::<CircuitInput<0>>{};
    let a1 = CircuitElement::<CircuitInput<1>>{};

    let result = circuit_sub(a0, a1);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let a0 = from_u256(self.c0);
    let b0 = from_u256(rhs.c0);


    let outputs =
        match (result,).new_inputs()
                       .next(a0)
                       .next(b0)
                       .done()
                       .eval(modulus) {
                                        Result::Ok(outputs) => { outputs },
                                        Result::Err(_) => { panic!("ERROR in circuit FQ_SUB") }
                                      };

    let outFq = Fq { c0: outputs.get_output(result).try_into().unwrap()};
    outFq
    }

    #[inline(always)]
    fn mul(self: Fq, rhs: Fq) -> Fq {
        //fq(mul(self.c0, rhs.c0))

    // Create circuit elements for the inputs
    let a0 = CircuitElement::<CircuitInput<0>>{};
    let a1 = CircuitElement::<CircuitInput<1>>{};

    let result = circuit_mul(a0, a1);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let a0 = from_u256(self.c0);
    let b0 = from_u256(rhs.c0);


    let outputs =
            match (result,).new_inputs()
                           .next(a0)
                           .next(b0)
                           .done()
                           .eval(modulus){
                                            Result::Ok(outputs) => { outputs },
                                            Result::Err(_) => { panic!("ERROR in circuit FQ_MUL") }
                                         };

    let outFq = Fq { c0: outputs.get_output(result).try_into().unwrap()};
    outFq

    }

    #[inline(always)]
    fn div(self: Fq, rhs: Fq) -> Fq {
        //fq(div(self.c0, rhs.c0))

        // Create circuit elements for the inputs
    let a0 = CircuitElement::<CircuitInput<0>>{};
    let a1 = CircuitElement::<CircuitInput<1>>{};

    let temp = circuit_inverse(a1);
    let result = circuit_mul(a0, temp);

    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();

    let a0 = from_u256(self.c0);
    let b0 = from_u256(rhs.c0);


    let outputs =
            match (result,).new_inputs()
                           .next(a0)
                           .next(b0)
                           .done()
                           .eval(modulus) {
                                            Result::Ok(outputs) => { outputs },
                                            Result::Err(_) => { panic!("ERROR in circuit FQ_DIV") }
                                        };

    let outFq = Fq { c0: outputs.get_output(result).try_into().unwrap()};
    outFq

    }

    #[inline(always)]
    fn neg(self: Fq) -> Fq {
        fq(neg(self.c0))

    // Create circuit elements for the inputs
   

    }

    #[inline(always)]
    fn eq(lhs: @Fq, rhs: @Fq) -> bool {
        *lhs.c0 == *rhs.c0
    }

    #[inline(always)]
    fn sqr(self: Fq) -> Fq {
        fq(sqr(self.c0))
    }

    #[inline(always)]
    fn inv(self: Fq, field_nz: NonZero<u256>) -> Fq {
        //fq(inv(self.c0))
        //              field_nz                       IT IS NOT BEEN USED
        let a0 = CircuitElement::<CircuitInput<0>>{};

        let result = circuit_inverse(a0);
    
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD_U384).unwrap();
    
        let a0 = from_u256(self.c0);
    
        let outputs =
                match (result,).new_inputs()
                               .next(a0)
                               .done()
                               .eval(modulus) {
                                                Result::Ok(outputs) => { outputs },
                                                Result::Err(_) => { panic!("ERROR in circuit FQ_") }
                                              };
    
        let outFq = Fq { c0: outputs.get_output(result).try_into().unwrap()};
        outFq

    }
}

impl FqIntoU256 of Into<Fq, u256> {
    #[inline(always)]
    fn into(self: Fq) -> u256 {
        self.c0
    }
}
impl U256IntoFq of Into<u256, Fq> {
    #[inline(always)]
    fn into(self: u256) -> Fq {
        fq(self)
    }
}
impl Felt252IntoFq of Into<felt252, Fq> {
    #[inline(always)]
    fn into(self: felt252) -> Fq {
        fq(self.into())
    }
}
