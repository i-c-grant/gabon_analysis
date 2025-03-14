#!/bin/bash

# Check if an input file was provided
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 input_file" >&2
    exit 1
fi

input_file="$1"

# Check if the input file exists
if [[ ! -f "$input_file" ]]; then
    echo "Error: File '$input_file' not found." >&2
    exit 1
fi

# Find the line number containing "LFID"
header_line=$(grep -n "LFID" "$input_file" | head -1 | cut -d':' -f1)

if [[ -z "$header_line" ]]; then
    echo "Error: Could not find a line containing 'LFID' in the input file." >&2
    exit 1
fi

headers=$(sed -n "${header_line}p" "$input_file" | sed 's/^# //' | tr -s ' ' ',')

echo $headers

# Output everything after the header line
sed -n "$((header_line + 1)),\$p" "$input_file" | tr -s ' ' ','
