use serde::{Deserialize, Deserializer, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct PLONKProof {
    #[serde(rename = "A")]
    pub a: [String; 3],
    #[serde(rename = "B")]
    pub b: [String; 3],
    #[serde(rename = "C")]
    pub c: [String; 3],
    #[serde(rename = "Z")]
    pub z: [String; 3],
    #[serde(rename = "T1")]
    pub t1: [String; 3],
    #[serde(rename = "T2")]
    pub t2: [String; 3],
    #[serde(rename = "T3")]
    pub t3: [String; 3],
    #[serde(rename = "Wxi")]
    pub wxi: [String; 3],
    #[serde(rename = "Wxiw")]
    pub wxiw: [String; 3],

    pub eval_a: String,
    pub eval_b: String,
    pub eval_c: String,
    pub eval_s1: String,
    pub eval_s2: String,
    pub eval_zw: String,

    pub protocol: String,
    pub curve: String,
}

fn deserialize_as_string<'de, D>(deserializer: D) -> Result<String, D::Error>
where
    D: Deserializer<'de>,
{
    // Deserialize any number or string into a String type
    let value = serde_json::Value::deserialize(deserializer)?;
    match value {
        serde_json::Value::Number(num) => Ok(num.to_string()),
        serde_json::Value::String(s) => Ok(s),
        _ => Err(serde::de::Error::custom("Expected a number or string")),
    }
}

fn default_n() -> String {
    "4096".to_string()
}

fn default_n_lagrange() -> String {
    "5".to_string()
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VerificationKey {
    #[serde(default = "default_n", deserialize_with = "deserialize_as_string")]
    pub n: String,

    pub protocol: String,
    pub curve: String,

    #[serde(rename = "nPublic", deserialize_with = "deserialize_as_string")]
    pub n_public: String,

    #[serde(
        default = "default_n_lagrange",
        deserialize_with = "deserialize_as_string"
    )]
    pub n_lagrange: String,

    #[serde(deserialize_with = "deserialize_as_string")]
    pub power: String,
    #[serde(deserialize_with = "deserialize_as_string")]
    pub k1: String,
    #[serde(deserialize_with = "deserialize_as_string")]
    pub k2: String,

    #[serde(rename = "Qm")]
    pub qm: [String; 3],
    #[serde(rename = "Ql")]
    pub ql: [String; 3],
    #[serde(rename = "Qr")]
    pub qr: [String; 3],
    #[serde(rename = "Qo")]
    pub qo: [String; 3],
    #[serde(rename = "Qc")]
    pub qc: [String; 3],
    #[serde(rename = "S1")]
    pub s1: [String; 3],
    #[serde(rename = "S2")]
    pub s2: [String; 3],
    #[serde(rename = "S3")]
    pub s3: [String; 3],

    #[serde(rename = "X_2")]
    pub x_2: [[String; 2]; 3],
    #[serde(deserialize_with = "deserialize_as_string")]
    pub w: String,
}

impl VerificationKey {
    /// Example validation
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
