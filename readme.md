# Overview
The code is portions of a PLONK verifier with a smart contract that incorporates the verifying logic. Local compilation using Scarb works as intended (outputs sierra and casm). Declaring the same contract to Starknet results in a compilation error on Starknet's end. No further information about the error is displayed. 

# Methods Tried
1. No relevant updates in the Cairo 2.9.0+ release notes.
2. Both snforge and starkli were used to try and declare the contract to Starknet. 
3. Latest version of the Sierra universal compiler was also tried to compile locally, no errors. 
4. Tried setting sierra-replace-ids = true
5. Tried looking at the difference between an error and a valid smart contract through its sierra representation, difference is varies too greatly to make any proper assessment. 

# Versions
1. Starkli (0.3.5)
2. Snforge 0.30.0
3. scarb (2.8.2)
4. cairo (2.8.2)
5. sierra (1.6.0)

# Smart Contract Location
```contract/src/lib.cairo```

# Main Entrypoint for Codebase
```plonk-verifier/plonk/verify.cairo```

# Details
In the verify.cairo file, there are two functions verify_invalid and verify_valid, the only difference being a function called produce_error(). The rest of the verify function is commented out in order to help isolate the problem. In this current setup, commenting out one for the other in the smart contract will result in the error or compile properly, respectively. 

The produce_error() function alone is not the culprit, but used in tandem with the rest of the function produces the error. Commenting out portions of the code such as the is_on_curve() or is_on_field() functions also result in proper compilation. In fact, even commenting out the assert function at the end of the smart contract also seems to make the contract compile properly. 

# Other Notes
- There were no real patterns that was discernable from my end from trying to find a "magical buggy operation". 
- The library uses the built-in circuits
- Size of the codebase does not seem to affect the problem
