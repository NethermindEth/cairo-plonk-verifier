use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct PlONKProof {
    pub A: [String; 3],
    pub B: [String; 3],
    pub C: [String; 3],
    pub Z: [String; 3],
    pub T1: [String; 3],
    pub T2: [String; 3],
    pub T3: [String; 3],
    pub Wxi: [String; 3],
    pub Wxiw: [String; 3],
    pub eval_a: String,
    pub eval_b: String,
    pub eval_c: String,
    pub eval_s1: String,
    pub eval_s2: String,
    pub eval_zw: String,
    pub protocol: String,
    pub curve: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VerificationKey {
    pub protocol: String,
    pub curve: String,
    pub nPublic: u64,
    pub power: u64,
    pub k1: String,
    pub k2: String,
    pub Qm: [String; 3],
    pub Ql: [String; 3],
    pub Qr: [String; 3],
    pub Qo: [String; 3],
    pub Qc: [String; 3],
    pub S1: [String; 3],
    pub S2: [String; 3],
    pub S3: [String; 3],
    pub X_2: [[String; 2]; 3],
    pub w: String,
}

impl VerificationKey {
    pub fn validate(&self) -> Result<(), String> {
        if self.curve != "bn128" {
            return Err("Unsupported curve type".to_string());
        }
        
        if self.protocol != "plonk" {
            return Err("Unsupported protocol".to_string());
        }
        
        Ok(())
    }
}