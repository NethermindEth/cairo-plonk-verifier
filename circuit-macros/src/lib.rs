use cairo_lang_macro::{inline_macro, ProcMacroResult, TokenStream};
use cairo_lang_parser::utils::SimpleParserDatabase;
use eyre::{eyre, Result};
use regex::Regex;

// EC Group Operations Fq
// let lambda = CircuitElement::<CircuitInput<i>> {};
// let x1 = CircuitElement::<CircuitInput<i + 1>> {};
// let y1 = CircuitElement::<CircuitInput<i + 2>> {};
// let x2 = CircuitElement::<CircuitInput<i + 3>> {};    
#[inline_macro]
pub fn point_on_slope_fq(token_stream: TokenStream) -> ProcMacroResult {
    let values = parse_circuit_inputs(token_stream).unwrap(); 
    println!("values {:?}", values); 
    ProcMacroResult::new(TokenStream::new("5".to_string()))
}



// Parses a macro input and returns args
fn parse_circuit_inputs(token_stream: TokenStream) -> Result<Vec<i32>> {
    let re = Regex::new(r"\(([^)]*)\)").unwrap();
    
    let db = SimpleParserDatabase::default();
    let (parsed, _diag) = db.parse_virtual_with_diagnostics(token_stream);
    let macro_args = parsed
        .descendants(&db)
        .next()
        .unwrap()
        .get_text(&db);

    if let Some(captures) = re.captures(&macro_args) {
        let val = captures.get(0).unwrap().as_str();
        println!("val: {:?}", val); 
        let parsed: Vec<i32> = val.trim_matches(|s|s == '(' || s == ')').split(',').map(|s|s.trim().parse::<i32>().unwrap()).collect(); 
        
        return Ok(parsed);
    }
    Err(eyre!("Parsing Error"))
}
