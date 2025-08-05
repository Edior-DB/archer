#!/bin/bash

echo "=== Testing archer.sh execution ==="
echo "Current working directory: $(pwd)"
echo "Testing basic archer functionality..."

# Test if gum is available
if command -v gum >/dev/null 2>&1; then
    echo "✓ gum is available"
else
    echo "✗ gum is not available"
fi

echo ""
echo "=== Running archer.sh with debug ==="
echo ""

# Run archer with a timeout and capture output
timeout 3 bash -c 'echo "0" | bin/archer.sh' 2>&1 || echo "Command timed out or exited"

echo ""
echo "=== Test completed ==="
