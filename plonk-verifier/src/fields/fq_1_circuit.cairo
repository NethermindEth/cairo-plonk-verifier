use core::traits::TryInto;
use plonk_verifier::curve::{FIELD, get_field_nz, add, sub_field, mul, scl, sqr, div, neg, inv};
use plonk_verifier::curve::{
    add_u, sub_u, mul_u, sqr_u, scl_u, u512_reduce, u512_add_u256, u512_sub_u256
};
use integer::u512;
use plonk_verifier::fields::fq_generics::{TFqAdd, TFqSub, TFqMul, TFqDiv, TFqNeg, TFqPartialEq,};
use plonk_verifier::traits::{FieldUtils, FieldOps, FieldShortcuts, FieldMulShortcuts};
use debug::PrintTrait;

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

// IMPLEMENT CIRCUITS ALSO HERE ? HERE ARE OPERATIONS NO IN FIELD?
impl FqShort of FieldShortcuts<Fq> {
    #[inline(always)]
    fn u_add(self: Fq, rhs: Fq) -> Fq {

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

        let a0 = CircuitElement::<CircuitInput<0>>::new(self.c0);
        let a1 = CircuitElement::<CircuitInput<1>>::new(rhs.c0);


        let result = circuit_mul(a0, a1);

        let output = (result,);

        let instance = output
            .new_inputs()
            .next(self.c0.to_u384())
            .next(rhs.c0.to_u384())
            .done();
        
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD).unwrap();

        // Evaluate the circuit
        let result_u512 = match instance.eval(modulus) {
            Ok(res) => {
                let result_u384 = res.get_output(result);
                // Convert u384 to u512
                u512 { 
                    limb0: result_u384.limb0, 
                    limb1: result_u384.limb1, 
                    limb2: result_u384.limb2,
                    limb3: 0
                }
            },
            Err(_) => panic!("ERROR in circuit U_512_SUM")
        };

        result_u512
    }

    #[inline(always)]
    fn u512_add_fq(self: u512, rhs: Fq) -> u512 {

    let a0 = CircuitElement::<CircuitInput<0>>::new(self.c0);
    let a1 = CircuitElement::<CircuitInput<1>>::new(rhs.c0);


    let result = circuit_add(a0, a1);

    let output = (result,);

    let instance = output
        .new_inputs()
        .next(self.c0.to_u384())
        .next(rhs.c0.to_u384())
        .done();
    
    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD).unwrap();

    // Evaluate the circuit
    let result_u512 = match instance.eval(modulus) {
        Ok(res) => {
            let result_u384 = res.get_output(result);
            // Convert u384 to u512
            u512 { 
                limb0: result_u384.limb0, 
                limb1: result_u384.limb1, 
                limb2: result_u384.limb2,
                limb3: 0
            }
        },
        Err(_) => panic!("ERROR in circuit U_512_SUM")
    };

    result_u512
    }

    #[inline(always)]
    fn u512_sub_fq(self: u512, rhs: Fq) -> u512 {

    let a0 = CircuitElement::<CircuitInput<0>>::new(self.c0);
    let a1 = CircuitElement::<CircuitInput<1>>::new(rhs.c0);

    let result = circuit_sub(a0, a1);

    let output = (result,);

    let instance = output
        .new_inputs()
        .next(self.c0.to_u384())
        .next(rhs.c0.to_u384())
        .done();
    
    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD).unwrap();

    let result_u512 = match instance.eval(modulus) {
        Ok(res) => {
            let result_u384 = res.get_output(result);

            u512 { 
                limb0: result_u384.limb0, 
                limb1: result_u384.limb1, 
                limb2: result_u384.limb2,
                limb3: 0
            }
        },
        Err(_) => panic!("ERROR in circuit U_512_SUB")
    };

    result_u512
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
        Fq { c0: scl(self.c0, by) }
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
        
        a0 = CircuitElement::<CircuitInput<0>>::new(self.c0);
        a1 = CircuitElement::<CircuitInput<1>>::new(rhs.c0);

        let result = circuit_add(a0,a1);

        let instance = output
            .new_inputs()
            .next(self.c0.to_u384())
            .next(rhs.c0.to_u384())
            .done();
        
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD).unwrap();

        // Evaluate the circuit
        let c0 = match instance.eval(modulus) {
            Ok(res) => (
                res.get_output(result).try_into().unwrap(),
            ),
            Err(_) => panic!("ERROR in circuit U_FQ_ADD")
        };

        Fq {c0: c0}

    }

    #[inline(always)]
    fn sub(self: Fq, rhs: Fq) -> Fq {
        let a0 = CircuitElement::<CircuitInput<0>>::new(self.c0);
        let a1 = CircuitElement::<CircuitInput<1>>::new(rhs.c0);

        let result = circuit_sub(a0, a1);

        let instance = output
            .new_inputs()
            .next(self.c0.to_u384())
            .next(rhs.c0.to_u384())
            .done();
        
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD).unwrap();

        let c0 = match instance.eval(modulus) {
            Ok(res) => res.get_output(result).try_into().unwrap(),
            Err(_) => panic!("ERROR in circuit U_FQ_SUB")
        };

        Fq { c0: c0 }
    }

    #[inline(always)]
    fn mul(self: Fq, rhs: Fq) -> Fq {
        let a0 = CircuitElement::<CircuitInput<0>>::new(self.c0);
        let a1 = CircuitElement::<CircuitInput<1>>::new(rhs.c0);

        let result = circuit_mul(a0, a1);

        let instance = output
            .new_inputs()
            .next(self.c0.to_u384())
            .next(rhs.c0.to_u384())
            .done();
        
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD).unwrap();

        let c0 = match instance.eval(modulus) {
            Ok(res) => res.get_output(result).try_into().unwrap(),
            Err(_) => panic!("ERROR in circuit U_FQ_MUL")
        };

        Fq { c0: c0 }
    }

    fn div(self: Fq, rhs: Fq) -> Fq {
        let a0 = CircuitElement::<CircuitInput<0>>::new(self.c0);
        let a1 = CircuitElement::<CircuitInput<1>>::new(rhs.c0);
    
        let inverse_rhs = circuit_inverse(a1);
    
        let result = circuit_mul(a0, inverse_rhs);
    
        let output = (result,);
    
        let instance = output
            .new_inputs()
            .next(self.c0.to_u384())
            .next(rhs.c0.to_u384())
            .done();
        
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD).unwrap();
    
        // Evaluate the circuit
        let c0 = match instance.eval(modulus) {
            Ok(res) => res.get_output(result).try_into().unwrap(),
            Err(_) => panic!("ERROR in circuit U_FQ_DIV")
        };
    
        Fq { c0: c0 }
    }

    fn neg(self: Fq) -> Fq {
        // Create a CircuitElement for the input
        let a = CircuitElement::<CircuitInput<0>>::new(self.c0);
    
        // Create a CircuitElement for the modulus
        let modulus_element = CircuitElement::<CircuitInput<1>>::new(FIELD);
    
        // Subtract the input from the modulus
        let result = circuit_sub(modulus_element, a);
    
        let output = (result,);
    
        let instance = output
            .new_inputs()
            .next(self.c0.to_u384())
            .next(FIELD.to_u384())
            .done();
        
        let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD).unwrap();
    
        // Evaluate the circuit
        let c0 = match instance.eval(modulus) {
            Ok(res) => res.get_output(result).try_into().unwrap(),
            Err(_) => panic!("ERROR in circuit U_FQ_NEG")
        };
    
        Fq { c0: c0 }
    }

    #[inline(always)]
fn eq(lhs: @Fq, rhs: @Fq) -> bool {
    // Create CircuitElements for the inputs
    let a = CircuitElement::<CircuitInput<0>>::new(*lhs.c0);
    let b = CircuitElement::<CircuitInput<1>>::new(*rhs.c0);

    // Subtract the elements
    let diff = circuit_sub(a, b);

    let output = (diff,);

    let instance = output
        .new_inputs()
        .next((*lhs.c0).to_u384())
        .next((*rhs.c0).to_u384())
        .done();
    
    let modulus = TryInto::<_, CircuitModulus>::try_into(FIELD).unwrap();

    // Evaluate the circuit
    match instance.eval(modulus) {
        Ok(res) => {
            let result: bool = res.get_output(output).try_into().unwrap();
            result
        },
        Err(_) => panic!("ERROR in circuit FQ_EQ")
    }
}

    #[inline(always)]
    fn sqr(self: Fq) -> Fq {
        fq(sqr(self.c0))
    }

    #[inline(always)]
    fn inv(self: Fq, field_nz: NonZero<u256>) -> Fq {
        //fq(inv(self.c0))
        let a0 = CircuitElement::<CircuitInput<0>>::new(self.c0);
        //let a1 = CircuitElement::<CircuitInput<1>>::new(rhs.c0);
    
        let inverse_rhs = circuit_inverse(a0);
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
