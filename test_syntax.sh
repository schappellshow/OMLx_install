#!/bin/bash

# Test script to check syntax of install_test_1.sh
echo "Testing syntax of install_test_1.sh..."

# Use full path to bash to avoid Cursor AppImage interference
/usr/bin/bash -n install_test_1.sh

if [ $? -eq 0 ]; then
    echo "✅ Syntax check passed!"
else
    echo "❌ Syntax error found!"
fi 