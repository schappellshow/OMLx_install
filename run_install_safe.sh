#!/bin/bash

# Safe wrapper script to run install_test_1.sh without Cursor AppImage interference

echo "🔧 Temporarily disabling Cursor AppImage to avoid interference..."
echo "📦 Running installation script..."

# Temporarily rename Cursor AppImage if it exists
if [[ -f "$HOME/.local/bin/cursor.AppImage" ]]; then
    mv "$HOME/.local/bin/cursor.AppImage" "$HOME/.local/bin/cursor.AppImage.bak"
    echo "✅ Cursor AppImage temporarily disabled"
fi

# Run the installation script
echo "🚀 Starting installation..."
bash install_test_1.sh

# Restore Cursor AppImage
if [[ -f "$HOME/.local/bin/cursor.AppImage.bak" ]]; then
    mv "$HOME/.local/bin/cursor.AppImage.bak" "$HOME/.local/bin/cursor.AppImage"
    echo "✅ Cursor AppImage restored"
fi

echo "🎉 Installation script completed!" 