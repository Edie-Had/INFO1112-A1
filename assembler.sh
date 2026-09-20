#!/bin/bash

# Test 1
if [ $# -eq 0 ]; then
    echo "usage: no argument is provided"
    exit 1
fi

# Test 2
if [ $# -gt 1 ]; then
    echo "usage: more than one arguments are provided"
    exit 1
fi

INPUT_FILE="$1"

# Test 3
if [ ! -f "$INPUT_FILE" ]; then
    echo "usage: input is not a file or it does not exist"
    exit 1
fi

# Test 4
if [ "${INPUT_FILE##*.}" != "vsc" ]; then
    echo "usage: input does not have the extension .vsc"
    exit 1
fi

# Test 5
if [ ! -s "$INPUT_FILE" ]; then
    echo "usage: the file is empty – no .bin file is produced"
    exit 1
fi

OUTPUT_FILE="${INPUT_FILE%.vsc}.bin"

# Opcode
LOAD_OPCODE=1
STORE_OPCODE=2
ADD_OPCODE=3
SUB_OPCODE=4
QUIT_OPCODE=8
PRINT_OPCODE=9

# Read file
line_num=0
dataArray=()

while IFS=$'\r' read -r line || [ -n "$line" ]; do
    dataArray[$line_num]="$line"
    line_num=$((line_num + 1))
done < "$INPUT_FILE"

n_values=${dataArray[0]}

# Check if n_values is number
if [ -z "$n_values" ]; then
    echo "Error: First line must be a number"
    exit 1
fi

rm -f "$OUTPUT_FILE"

# Write data values
for ((i = 0; i < n_values; i++)); do
    value_line=$((i + 1))
    value=${dataArray[$value_line]}
    
    if [ -z "$value" ]; then
        echo "Error: Invalid data value"
        exit 1
    fi
    
    if [ "$value" -gt 255 ] 2>/dev/null; then
        echo "Error: Data value out of range"
        exit 1
    fi
    
    printf "\\x$(printf '%02x' "$value")" >> "$OUTPUT_FILE"
done

# Process instructions
instruction_line=$((n_values + 1))
has_add_sub=0
has_quit=0

while [ $instruction_line -lt $line_num ]; do
    line="${dataArray[$instruction_line]}"
    
    if [ -z "$line" ]; then
        instruction_line=$((instruction_line + 1))
        continue
    fi
    
    IFS=',' read -r cmd reg addr <<< "$line"
    cmd=$(echo "$cmd" | xargs)
    reg=$(echo "$reg" | xargs)
    addr=$(echo "$addr" | xargs)
    
    # Get opcode using if-elif
    if [ "$cmd" = "LOAD" ]; then
        opcode=$LOAD_OPCODE
    elif [ "$cmd" = "STORE" ]; then
        opcode=$STORE_OPCODE
    elif [ "$cmd" = "ADD" ]; then
        opcode=$ADD_OPCODE
        has_add_sub=1
    elif [ "$cmd" = "SUB" ]; then
        opcode=$SUB_OPCODE
        has_add_sub=1
    elif [ "$cmd" = "QUIT" ]; then
        opcode=$QUIT_OPCODE
        has_quit=1
        reg=0
        addr=0
    elif [ "$cmd" = "PRINT" ]; then
        opcode=$PRINT_OPCODE
        addr=0
    else
        echo "Error: Unknown instruction '$cmd'"
        exit 1
    fi
    
    # Validate register (0-3)
    if [ "$reg" -lt 0 ] || [ "$reg" -gt 3 ] 2>/dev/null; then
        echo "Error: Invalid register"
        exit 1
    fi
    
    # Validate address (0-255)
    if [ "$addr" -gt 255 ] 2>/dev/null; then
        echo "Error: Invalid address"
        exit 1
    fi
    
    # Encode to bytes
    byte1=$((opcode*4 + reg))
    byte2=$addr
    
    printf "\\x$(printf '%02x' "$byte1")" >> "$OUTPUT_FILE"
    printf "\\x$(printf '%02x' "$byte2")" >> "$OUTPUT_FILE"
    
    instruction_line=$((instruction_line + 1))
done

# Display program type
if [ $has_quit -eq 1 ] && [ $has_add_sub -eq 0 ]; then
    echo "It is a QUIT program"
elif [ $has_add_sub -eq 1 ]; then
    echo "It is an ADD/SUB program"
fi

echo "The content of the .bin file is"
od -An -tx1 -v "$OUTPUT_FILE" | tr -d '\n' | sed 's/ //g' | sed 's/\(..\)/\1 /g' | xargs

exit 0