# Define the path to the original block note and the new file
input_file_path = '2.log'
output_file_path = 'filtered_debug_lines2.txt'

# Open the original file in read mode and the new file in write mode
with open(input_file_path, 'r') as input_file, open(output_file_path, 'w') as output_file:
    # Iterate through each line in the input file
    for line in input_file:
        # Check if the line contains the word 'DEBUG'
        if 'DEBUG' in line:
            # If it does, write this line to the output file
            output_file.write(line)

print(f"Lines containing 'DEBUG' have been written to {output_file_path}")
