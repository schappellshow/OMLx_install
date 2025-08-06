#!/bin/bash

# Safe wrapper script to run install_test_1.sh without Cursor AppImage interference

echo "🔧 Temporarily disabling Cursor AppImage to avoid interference..."
echo "📦 Running installation script..."

# Temporarily rename Cursor AppImage if it exists (multiple possible locations)
if [[ -f "$HOME/.local/bin/cursor.AppImage" ]]; then
    /bin/mv "$HOME/.local/bin/cursor.AppImage" "$HOME/.local/bin/cursor.AppImage.bak" 2>/dev/null
    echo "✅ Cursor AppImage temporarily disabled"
fi

if [[ -f "$HOME/AppImages/cursor.appimage" ]]; then
    /bin/cp "$HOME/AppImages/cursor.appimage" "$HOME/AppImages/cursor.appimage.bak" 2>/dev/null
    /bin/rm "$HOME/AppImages/cursor.appimage" 2>/dev/null
    echo "✅ Cursor AppImage (AppImages) temporarily disabled"
fi

# Run the installation script
echo "🚀 Starting installation..."
bash install_test_1.sh

# Restore Cursor AppImage
if [[ -f "$HOME/.local/bin/cursor.AppImage.bak" ]]; then
    /bin/mv "$HOME/.local/bin/cursor.AppImage.bak" "$HOME/.local/bin/cursor.AppImage" 2>/dev/null
    echo "✅ Cursor AppImage restored"
fi

if [[ -f "$HOME/AppImages/cursor.appimage.bak" ]]; then
    /bin/mv "$HOME/AppImages/cursor.appimage.bak" "$HOME/AppImages/cursor.appimage" 2>/dev/null
    /bin/chmod +x "$HOME/AppImages/cursor.appimage" 2>/dev/null
    echo "✅ Cursor AppImage (AppImages) restored"
fi

echo "🎉 Installation script completed!" 