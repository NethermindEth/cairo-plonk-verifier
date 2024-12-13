use bigdecimal::{num_traits::pow, BigDecimal};
use cairo_lang_macro::{inline_macro, Diagnostic, ProcMacroResult, TokenStream};
use cairo_lang_parser::utils::SimpleParserDatabase;

#[inline_macro]
pub fn some(token_stream: TokenStream) -> ProcMacroResult {
    // no-op
    ProcMacroResult::new(token_stream)
}

/// Compile-time power function.
///
/// Takes two arguments, `x, y`, calculates the value of `x` raised to the power of `y`.
///
/// ```
/// const MEGABYTE: u64 = pow!(2, 20);
/// assert_eq!(MEGABYTE, 1048576);
/// ```
#[inline_macro]
pub fn pow(token_stream: TokenStream) -> ProcMacroResult {
    let db = SimpleParserDatabase::default();
    let (parsed, _diag) = db.parse_virtual_with_diagnostics(token_stream);

    let macro_args: Vec<String> = parsed
        .descendants(&db)
        .next()
        .unwrap()
        .get_text(&db)
        .trim_matches(|c| c == '(' || c == ')')
        .split(',')
        .map(|s| s.trim().to_string())
        .collect();

    if macro_args.len() != 2 {
        return ProcMacroResult::new(TokenStream::empty()).with_diagnostics(
            Diagnostic::error(format!("Expected two arguments, got {:?}", macro_args)).into(),
        );
    }

    println!("macro args {:?}", macro_args[0]);
    let base: u32 = match macro_args[0].parse() {
        Ok(val) => val,
        Err(err) => {
            println!("{:?}", err); 
            return ProcMacroResult::new(TokenStream::empty())
                .with_diagnostics(Diagnostic::error("Invalid base value").into());
        }
    };

    let exp: u32 = match macro_args[1].parse() {
        Ok(val) => val,
        Err(_) => {
            return ProcMacroResult::new(TokenStream::empty())
                .with_diagnostics(Diagnostic::error("Invalid exponent value").into());
        }
    };

    let result: u32 = base * exp; 

    ProcMacroResult::new(TokenStream::new(result.to_string()))
}