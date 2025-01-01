pub fn get_imports() -> String {
    "use core::circuit::{\n\t\
            AddModGate as A,\n\t\
            SubModGate as S,\n\t\
            MulModGate as M,\n\t\
            InverseGate as I,\n\t\
            CircuitInput as CI,\n\t\
            CircuitElement as CE,\n\
            };\n".to_string()
}