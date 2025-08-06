#!/bin/bash

echo "Testing script syntax..."

# Temporarily disable Cursor AppImage
if [[ -f "$HOME/.local/bin/cursor.AppImage" ]]; then
    mv "$HOME/.local/bin/cursor.AppImage" "$HOME/.local/bin/cursor.AppImage.bak"
    echo "Cursor AppImage temporarily disabled"
fi

# Test syntax
echo "Running syntax check..."
/usr/bin/bash -n install_test_1.sh

if [ $? -eq 0 ]; then
    echo "✅ Syntax check passed!"
else
    echo "❌ Syntax error found!"
fi

# Restore Cursor AppImage
if [[ -f "$HOME/.local/bin/cursor.AppImage.bak" ]]; then
    mv "$HOME/.local/bin/cursor.AppImage.bak" "$HOME/.local/bin/cursor.AppImage"
    echo "Cursor AppImage restored"
fi 