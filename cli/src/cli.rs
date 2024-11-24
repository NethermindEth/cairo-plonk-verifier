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
        #[arg(long = "vk")]
        verification_key: PathBuf,

        #[arg(long = "proof")]
        proof: PathBuf,

        #[arg(long = "public")]
        public_inputs: PathBuf,
    },
}