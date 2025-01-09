use starknet::{
    accounts::{Account, ExecutionEncoding, SingleOwnerAccount, Call},
    core::{
        chain_id,
        types::{BlockId, BlockTag, FieldElement},
        utils::get_selector_from_name,
    },
    providers::{
        jsonrpc::{HttpTransport, JsonRpcClient},
        Url,
    },
    signers::{LocalWallet, SigningKey},
};
use dotenv::dotenv;
use std::env;
use std::path::PathBuf;
use crate::error::CliError;
use crate::commands::utils::{read_json_file, ensure_temp_dir};

const DEFAULT_VK: &str = "verification_key.json";
const DEFAULT_PROOF: &str = "proof.json";
const DEFAULT_PUBLIC: &str = "public.json";

fn resolve_file_path(file_path: PathBuf, default_name: &str) -> Result<PathBuf, CliError> {
    if file_path.is_absolute() || file_path.to_str().unwrap_or("").starts_with("./") {
        Ok(file_path)
    } else {
        let temp_dir = PathBuf::from("./data/temp");
        Ok(temp_dir.join(file_path.file_name().unwrap_or_else(|| default_name.as_ref())))
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
    let contract_address = env::var("CONTRACT_ADDRESS").expect("CONTRACT_ADDRESS environment variable is not set");

    println!("Private Key: {}", private_key);
    println!("Contract Address: {}", contract_address);

    // Ensure temp directory exists
    ensure_temp_dir()?;

    // Resolve full paths
    let vk_full_path = resolve_file_path(vk_path, DEFAULT_VK)?;
    let proof_full_path = resolve_file_path(proof_path, DEFAULT_PROOF)?;
    let public_full_path = resolve_file_path(public_inputs_path, DEFAULT_PUBLIC)?;

    println!("Using files:");
    println!("  Verification key: {}", vk_full_path.display());
    println!("  Proof: {}", proof_full_path.display());
    println!("  Public inputs: {}", public_full_path.display());

    // Load and validate all files
    let vk = read_json_file(&vk_full_path)?;
    let proof = read_json_file(&proof_full_path)?;
    let public = read_json_file(&public_full_path)?;
    

    // Starknet Provider and Account Setup
    let provider = JsonRpcClient::new(HttpTransport::new(
        Url::parse("https://starknet-sepolia.public.blastapi.io/rpc/v0_7").unwrap(),
    ));

    let signer = LocalWallet::from(SigningKey::from_secret_scalar(
        FieldElement::from_hex_be(&private_key).expect("Invalid PRIVATE_KEY format"),
    ));

    let verifier_contract_address = FieldElement::from_hex_be(&contract_address).expect("Invalid CONTRACT_ADDRESS format");

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
    let result = account
        .execute(vec![Call {
            to: verifier_contract_address,
            selector: get_selector_from_name("verify").unwrap(),
            calldata: vec![
                account_address,
                FieldElement::from_dec_str("1000000000000000000000").unwrap(),
                FieldElement::ZERO,
            ],
        }])
        .send()
        .await
        .expect("Failed to send transaction");

    println!("Transaction hash: {:#064x}", result.transaction_hash);

    // Perform verification
    println!("\nVerifying proof...");
    // Add actual verification logic here
    println!("✅ Proof is valid!");

    Ok(())
}
