# PLONK Proof Verifier CLI

A command-line tool for verifying PLONK zero-knowledge proofs.

## Installation

```bash
# Build the project
cargo build

# Optional: Install globally
cargo install --path .
```

## Usage

Verify a PLONK proof:

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

## File Formats

### Verification Key (verification_key.json)

```json
{
  "protocol": "plonk",
  "curve": "bn128",
  "nPublic": 5,
  "power": 12,
  "k1": "2",
  "k2": "3"
  // ... other verification key parameters
}
```

### Proof (proof.json)

```json
{
  "protocol": "plonk",
  "curve": "bn128",
  "A": ["...", "...", "1"],
  "B": ["...", "...", "1"]
  // ... other proof parameters
}
```

### Public Inputs (public.json)

```json
{
  // public input values
}
```

## Project Structure

```
.
├── Cargo.toml
├── data/
│   └── temp/           # Default location for input files
├── src/
│   ├── cli.rs         # CLI argument definitions
│   ├── commands/      # Command implementations
│   ├── error.rs       # Error handling
│   ├── lib.rs         # Library exports
│   └── main.rs        # Entry point
```

## Development

### Prerequisites

- Rust 1.70 or higher
- Cargo

### Building

```bash
cargo build
```
