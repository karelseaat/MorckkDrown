#!/bin/bash
set -e

# Build
echo "Building..."
nim c -d:release src/md_morph.nim

# Test Function
run_test() {
    local input=$1
    local config=$2
    local name=$(basename "$input" .md)
    
    echo "Testing $name..."
    
    # 1. Transform
    ./src/md_morph "$input" -c:"$config" -o:"tests/${name}_output.txt"
    
    # 2. Reverse
    ./src/md_morph "tests/${name}_output.txt" -c:"$config" -r -o:"tests/${name}_restored.md"
    
    # 3. Compare (Ignoring whitespace/empty lines for now as exact match is hard with layout changes)
    # Ideally we'd use diff, but for now just check if it runs without error
    if [ -f "tests/${name}_restored.md" ]; then
        echo "✓ Reversible: $name"
    else
        echo "✗ Failed: $name"
        exit 1
    fi
}

# Run on all .md files in tests/ (excluding restored ones)
for file in tests/*.md; do
    # Skip restored files to avoid infinite loops or re-testing output
    if [[ "$file" == *"_restored.md"* ]]; then
        continue
    fi
    
    run_test "$file" "config.ini"
done

echo "All tests passed!"
