# Code Limit

A Python script for analyzing the size and bytecode length of Sierra contract class files. This tool helps developers understand the size characteristics of their smart contracts by providing both the total bytecode size in bytes and the number of field elements (felts) in the program.

#### ⚠️ Important Note on Size Calculation

Please be aware: The bytecode size calculation provided by this tool should be used as a rough estimate only. Even when the tool reports a bytecode size around 49,000 felts, you may still encounter "code size limit" errors when attempting to declare the contract class.

## Prerequisites

- Python 3.x
- `jq` command-line tool installed on your system
- JSON-formatted contract class files

## Installation

1. Clone this repository or download `code_limit.py`
2. Ensure you have `jq` installed:
   - For Ubuntu/Debian: `sudo apt-get install jq`
   - For macOS: `brew install jq`
   - For Windows: Download from the [official jq website](https://stedolan.github.io/jq/download/)

## Usage

Run it directly from the command line:

```bash
python code_limit.py
```

Before running, make sure to modify the `path_filename` variable in the `main()` function to point to your contract class JSON file:

```python
path_filename = "path/to/your/contract_class.json"
```

## Functions

### get_sierra_size(path_filename)

Calculates the total size in bytes of the Sierra program bytecode.

Parameters:

- `path_filename` (str): Path to the contract class JSON file

Returns:

- `int`: Total size in bytes, or `None` if an error occurs

### get_bytecode_length_with_jq(path_filename)

Uses `jq` to calculate the number of field elements in the Sierra program.

Parameters:

- `path_filename` (str): Path to the contract class JSON file

Returns:

- `int`: Number of field elements, or `None` if an error occurs

## Error Handling

The script handles various error cases:

- File not found
- Invalid JSON format
- Missing 'sierra_program' field
- JQ command failures
- General exceptions

## Example Output

```
Contract class size: 1,234 bytes
Contract Bytecode size (Number of felts in the program): 567
```
