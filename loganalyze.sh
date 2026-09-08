#!/bin/bash

#added this comment

loganalyze(){

DIR="${1:-.}"

if [ ! -d "$DIR" ]; then
    echo "Error: Directory does not exist"
    exit 1
fi

> "$DIR/analysisData.log"
> "$DIR/summary.log"

total=0
max=0
maxfile=""

for file in "$DIR"/*.log; do
    [ -f "$file" ] || continue
    
    count=$(grep -i "error" "$file" 2>/dev/null | wc -l)
    name=$(basename "$file")
    
    echo "$name: $count errors" | tee -a "$DIR/analysisData.log"
    
    total=$((total + count))
    if [ "$count" -gt "$max" ]; then
        max=$count
        maxfile="$name"
    fi
done

# Print and save summary
echo "Total errors: $total" | tee -a "$DIR/summary.log"
echo "Most errors: $maxfile ($max errors)" | tee -a "$DIR/summary.log"
}
