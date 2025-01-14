use crate::commands::types::{PLONKProof, VerificationKey};
use crate::commands::utils::{ensure_temp_dir};

use crate::commands::type_conversion::convert_u384_to_low_high;
use crate::error::CliError;
use dotenv::dotenv;
use serde_json;
use starknet::{
    accounts::{Account, ExecutionEncoding, SingleOwnerAccount}, // Call
    core::{
        chain_id,
        types::{BlockId, BlockTag, Call, Felt},
        utils::get_selector_from_name,
    },
    providers::{
        jsonrpc::{HttpTransport, JsonRpcClient},
        Url,
    },
    signers::{LocalWallet, SigningKey},
};
use std::env;
use std::path::PathBuf;

const DEFAULT_VK: &str = "verification_key.json";
const DEFAULT_PROOF: &str = "proof.json";
const DEFAULT_PUBLIC: &str = "public.json";

fn resolve_file_path(file_path: PathBuf, default_name: &str) -> Result<PathBuf, CliError> {
    if file_path.is_absolute() || file_path.to_str().unwrap_or("").starts_with("./") {
        Ok(file_path)
    } else {
        let temp_dir = PathBuf::from("./data/temp");
        Ok(temp_dir.join(
            file_path
                .file_name()
                .unwrap_or_else(|| default_name.as_ref()),
        ))
    }
}

pub async fn verify(
    vk_path: PathBuf,
    proof_path: PathBuf,
    public_inputs_path: PathBuf,
) -> Result<(), CliError> {
    // Load environment variables
    dotenv().ok();

    // Load environment variables
    let private_key = env::var("PRIVATE_KEY").expect("PRIVATE_KEY environment variable is not set");
    let contract_address =
        env::var("CONTRACT_ADDRESS").expect("CONTRACT_ADDRESS environment variable is not set");
    let account_address =
        env::var("ACCOUNT_ADDRESS").expect("ACCOUNT_ADDRESS environment variable is not set");
    let rpc_url =
        env::var("RPC_URL").expect("RPC_URL environment variable is not set");

    // Ensure temp directory exists
    ensure_temp_dir()?;

    // Resolve full paths
    let vk_full_path = resolve_file_path(vk_path, DEFAULT_VK)?;
    let proof_full_path = resolve_file_path(proof_path, DEFAULT_PROOF)?;
    let public_full_path = resolve_file_path(public_inputs_path, DEFAULT_PUBLIC)?;

    type PublicSignals = Vec<String>; // Public.json is an array of strings

    // Load and parse verification key
    let vk_json = std::fs::read_to_string(&vk_full_path)?;
    let vk: VerificationKey =
        serde_json::from_str(&vk_json).expect("Failed to parse verification key");

    // Load and parse proof
    let proof_json = std::fs::read_to_string(&proof_full_path)?;
    let proof: PLONKProof = serde_json::from_str(&proof_json).expect("Failed to parse proof");

    // Load and parse public inputs
    let public_json = std::fs::read_to_string(&public_full_path)?;
    let public_signals: PublicSignals =
        serde_json::from_str(&public_json).expect("Failed to parse public inputs");

    // // Prepare calldata
    let mut calldata: Vec<Felt> = vec![];

    // Add verification key fields
    let (n_low, n_high) = convert_u384_to_low_high(&vk.n);
    calldata.push(Felt::from_dec_str(&n_low).unwrap());
    calldata.push(Felt::from_dec_str(&n_high).unwrap());

    let (power_low, power_high) = convert_u384_to_low_high(&vk.power);
    calldata.push(Felt::from_dec_str(&power_low).unwrap());
    calldata.push(Felt::from_dec_str(&power_high).unwrap());

    let (k1_low, k1_high) = convert_u384_to_low_high(&vk.k1);
    calldata.push(Felt::from_dec_str(&k1_low).unwrap());
    calldata.push(Felt::from_dec_str(&k1_high).unwrap());

    let (k2_low, k2_high) = convert_u384_to_low_high(&vk.k2);
    calldata.push(Felt::from_dec_str(&k2_low).unwrap());
    calldata.push(Felt::from_dec_str(&k2_high).unwrap());

    let (n_public_low, n_public_high) = convert_u384_to_low_high(&vk.n_public);
    calldata.push(Felt::from_dec_str(&n_public_low).unwrap());
    calldata.push(Felt::from_dec_str(&n_public_high).unwrap());

    let (n_lagrange_low, n_lagrange_high) = convert_u384_to_low_high(&vk.n_lagrange);
    calldata.push(Felt::from_dec_str(&n_lagrange_low).unwrap());
    calldata.push(Felt::from_dec_str(&n_lagrange_high).unwrap());

    // Add G1 points for Qm, Qc, Ql, Qr, Qo, S1, S2, S3
    let g1_points = [
        &vk.qm, &vk.qc, &vk.ql, &vk.qr, &vk.qo, &vk.s1, &vk.s2, &vk.s3,
    ];

    for point in g1_points {
        // Process the first two values in each point
        for value in &point[0..2] {
            let (low, high) = convert_u384_to_low_high(value);
            calldata.push(Felt::from_dec_str(&low).unwrap());
            calldata.push(Felt::from_dec_str(&high).unwrap());
        }
    }

    // Add G2 points for X_2
    for sub_vector in &vk.x_2[0..2] {
        for value in sub_vector {
            let (low, high) = convert_u384_to_low_high(value);
            calldata.push(Felt::from_dec_str(&low).unwrap());
            calldata.push(Felt::from_dec_str(&high).unwrap());
        }
    }

    let (w_low, w_high) = convert_u384_to_low_high(&vk.w);
    calldata.push(Felt::from_dec_str(&w_low).unwrap());
    calldata.push(Felt::from_dec_str(&w_high).unwrap());

    // Add proof fields
    let proof_field_points = [
        &proof.a,
        &proof.b,
        &proof.c,
        &proof.z,
        &proof.t1,
        &proof.t2,
        &proof.t3,
        &proof.wxi,
        &proof.wxiw,
    ];

    for point in proof_field_points {
        for value in &point[0..2] {
            let (low, high) = convert_u384_to_low_high(value);
            calldata.push(Felt::from_dec_str(&low).unwrap());
            calldata.push(Felt::from_dec_str(&high).unwrap());
        }
    }

    // Add scalar proof fields
    let proof_scalar_fields = [
        &proof.eval_a,
        &proof.eval_b,
        &proof.eval_c,
        &proof.eval_s1,
        &proof.eval_s2,
        &proof.eval_zw,
    ];

    for scalar in proof_scalar_fields {
        let (low, high) = convert_u384_to_low_high(scalar);
        calldata.push(Felt::from_dec_str(&low).unwrap());
        calldata.push(Felt::from_dec_str(&high).unwrap());
    }

    // Add public signals
    let public_signal_length = public_signals.len();
    calldata.push(Felt::from_dec_str(&public_signal_length.to_string()).unwrap());
    
    for signal in public_signals {
        let (low, high) = convert_u384_to_low_high(signal.as_str());
        calldata.push(Felt::from_dec_str(&low).unwrap());
        calldata.push(Felt::from_dec_str(&high).unwrap());
    }

    // println!("Calldata for public_signals:");
    // print!("[");
    // for (i, value) in calldata.iter().enumerate() {
    //     if i == 0 {
    //         print!("{}", value); // Print the first value without a comma
    //     } else {
    //         print!(", {}", value); // Add a comma before subsequent values
    //     }
    // }
    // println!("]");

    // Starknet Provider and Account Setup
    let provider = JsonRpcClient::new(HttpTransport::new(
        Url::parse(&rpc_url).unwrap(),
    ));

    let signer = LocalWallet::from(SigningKey::from_secret_scalar(
        Felt::from_hex(&private_key).expect("Invalid PRIVATE_KEY format"),
    ));

    let verifier_contract_address =
        Felt::from_hex(&contract_address).expect("Invalid CONTRACT_ADDRESS format");
    let account_address = Felt::from_hex(&account_address).expect("Invalid ACCOUNT_ADDRESS format");

    let mut account = SingleOwnerAccount::new(
        provider,
        signer,
        account_address,
        chain_id::SEPOLIA,
        ExecutionEncoding::New,
    );

    // Set target block to Pending
    account.set_block_id(BlockId::Tag(BlockTag::Pending));

    // Execute Call (Example Interaction)
    let result = match account
        .execute_v3(vec![Call {
            to: verifier_contract_address,
            selector: get_selector_from_name("verify").unwrap(),
            calldata: calldata,
        }])
        .send()
        .await
    {
        Ok(result) => {
            println!("Transaction hash: {:#064x}", result.transaction_hash);
            println!("\nVerifying proof...");
            println!("✅ Proof is valid!");
            true
        }
        Err(error) => {
            println!("Transaction hash: Error occurred");
            println!("\nVerifying proof...");
            println!("❌ Proof is invalid!");
            println!("Error: {:?}", error);
            false
        }
    };

    Ok(())
}
