# PLONK Proof Verifier CLI

A command-line tool for verifying PLONK zero-knowledge proofs.

## Installation

```bash
# Build the project
cargo build

# Optional: Install globally
cargo install --path .
```

## Prerequisites

- Rust 1.70 or higher
- Cargo
- snarkjs (for generating proof components)

### Configuration
Create a .env file in the project root with the following variables:

```
PRIVATE_KEY=           # Your private key
CONTRACT_ADDRESS=0x07bb076ad972cb92eccdf2f32544cf68cf365911ec731008bc24c8b8a4049445
ACCOUNT_ADDRESS=       # Your account address
RPC_URL=              # Your RPC endpoint URL
```

## Usage

### 1. Generate Proof Components

Use snarkjs to generate the following files:
- verification_key.json
- proof.json
- public.json

### 2. Verify Proof

```bash
cargo run -- verify [OPTIONS]
```

Options:

- `--vk` - Path to verification key file (default: data/temp/verification_key.json)
- `--proof` - Path to proof file (default: data/temp/proof.json)
- `--public` - Path to public inputs file (default: data/temp/public.json)

Example:

```bash
# Using default file locations
cargo run -- verify

# Using custom file locations
cargo run -- verify \
  --vk ./custom/path/verification_key.json \
  --proof ./custom/path/proof.json \
  --public ./custom/path/public.json
```

## Project Structure

```
.
├── ./data
│   └── ./data/temp
├── ./src
│   ├── ./src/cli.rs
│   ├── ./src/commands
│   │   ├── ./src/commands/mod.rs
│   │   ├── ./src/commands/type_conversion.rs
│   │   ├── ./src/commands/types.rs
│   │   ├── ./src/commands/utils.rs
│   │   └── ./src/commands/verify.rs
│   ├── ./src/error.rs
│   ├── ./src/lib.rs
│   └── ./src/main.rs
```

## Development

### Building

```bash
cargo build
```