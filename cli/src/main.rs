use clap::Parser;
use cli::{
    cli::{Cli, Commands},
    commands, CliError,
};
use tokio;

#[tokio::main]
async fn main() -> Result<(), CliError> {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Verify {
            verification_key,
            proof,
            public_inputs,
        } => {
            commands::verify::verify(
                verification_key.clone(),
                proof.clone(),
                public_inputs.clone(),
            )
            .await?;
        }
    }

    Ok(())
}
