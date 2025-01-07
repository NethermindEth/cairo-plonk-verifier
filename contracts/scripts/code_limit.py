import json
import subprocess

def calculate_bytecode_size(hex_strings):
    total_bytes = 0
    
    for hex_str in hex_strings:
        hex_str = hex_str.replace('0x', '')
        num_bytes = len(hex_str) // 2
        total_bytes += num_bytes
        
    return total_bytes

def get_sierra_size(path_filename):
    try:
        with open(path_filename, 'r') as file:
            data = json.load(file)
        
        # Extract sierra_program array
        if 'sierra_program' not in data:
            raise KeyError("No 'sierra_program' found in JSON file")
            
        sierra_program = data['sierra_program']
        
        # Calculate total size
        size = calculate_bytecode_size(sierra_program)
        return size
        
    except FileNotFoundError:
        print(f"Error: File '{path_filename}' not found")
    except json.JSONDecodeError:
        print(f"Error: File '{path_filename}' is not valid JSON")
    except KeyError as e:
        print(f"Error: {str(e)}")
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        
    return None

def get_bytecode_length_with_jq(path_filename):
    """Call the jq command to get the bytecode length."""
    try:
        # Run the jq command to get sierra_program length
        result = subprocess.run(
            ['jq', '.sierra_program | length', path_filename],
            capture_output=True,
            text=True,
            check=True
        )
        
        bytecode_length = int(result.stdout.strip())
        return bytecode_length
        
    except subprocess.CalledProcessError as e:
        print(f"Error running jq: {e}")
    except ValueError:
        print("Error: Unable to parse jq output as an integer")
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        
    return None

def main():
    # Path to JSON file
    path_filename = "path/to/contract_class.json"
    
    size = get_sierra_size(path_filename)
    if size is not None:
        print(f"Contract class size: {size:,} bytes")
    
    # Calculate size using jq
    bytecode_length = get_bytecode_length_with_jq(path_filename)
    if bytecode_length is not None:
        print(f"Contract Bytecode size (Number of felts in the program): {bytecode_length}")

if __name__ == "__main__":
    main()