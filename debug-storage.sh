#!/bin/bash

# Simple test to isolate the issue

echo "Testing basic script execution..."

# Test the script step by step
STORAGE_SCRIPT="/Users/johnsabba/Projects/Scripts/Storage/mac-storage-manager.sh"

echo "1. Testing syntax check..."
if bash -n "$STORAGE_SCRIPT"; then
    echo "✅ Syntax OK"
else
    echo "❌ Syntax error"
    exit 1
fi

echo "2. Testing direct function call..."
if bash -c "source '$STORAGE_SCRIPT'; show_help" 2>/dev/null; then
    echo "✅ Function call OK"
else
    echo "❌ Function call failed"
fi

echo "3. Testing script with help flag..."
if timeout 5s "$STORAGE_SCRIPT" --help 2>/dev/null; then
    echo "✅ Help flag OK"
else
    echo "❌ Help flag failed with code: $?"
fi

echo "4. Testing script with version flag..."
if timeout 5s "$STORAGE_SCRIPT" --version 2>/dev/null; then
    echo "✅ Version flag OK"
else
    echo "❌ Version flag failed"
fi