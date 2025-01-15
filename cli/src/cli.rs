use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser)]
#[command(version, about, long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    Verify {
        /// Verification key filename or path
        #[arg(
            long = "vk",
            help = "Verification key filename or path (default: verification_key.json)",
            long_help = "The verification key file (default: ./data/temp/verification_key.json)",
            default_value = "verification_key.json"
        )]
        verification_key: PathBuf,

        /// Proof filename or path
        #[arg(
            long = "proof",
            help = "Proof filename or path (default: proof.json)",
            long_help = "The proof file (default: ./data/temp/proof.json)",
            default_value = "proof.json"
        )]
        proof: PathBuf,

        /// Public inputs filename or path
        #[arg(
            long = "public",
            help = "Public inputs filename or path (default: public.json)",
            long_help = "The public inputs file (default: ./data/temp/public.json)",
            default_value = "public.json"
        )]
        public_inputs: PathBuf,
    },
}
