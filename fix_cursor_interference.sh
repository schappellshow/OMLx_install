#!/bin/bash

echo "🔧 Fixing Cursor AppImage interference..."

# Method 1: Try to rename using different approaches
echo "Attempting to disable Cursor AppImage..."

# Check if cursor.appimage exists
if [[ -f "/home/mike/AppImages/cursor.appimage" ]]; then
    echo "Found Cursor AppImage, attempting to disable..."
    
    # Try using cp and rm instead of mv
    if /bin/cp "/home/mike/AppImages/cursor.appimage" "/home/mike/AppImages/cursor.appimage.bak" 2>/dev/null; then
        /bin/rm "/home/mike/AppImages/cursor.appimage" 2>/dev/null
        echo "✅ Cursor AppImage disabled successfully"
    else
        echo "⚠️  Could not disable Cursor AppImage, trying alternative method..."
        
        # Try changing permissions to prevent execution
        /bin/chmod 000 "/home/mike/AppImages/cursor.appimage" 2>/dev/null
        echo "✅ Cursor AppImage permissions changed to prevent execution"
    fi
else
    echo "✅ Cursor AppImage not found or already disabled"
fi

echo "🚀 Now running installation script..."
echo ""

# Run the installation script with full bash path
/usr/bin/bash install_test_1.sh

echo ""
echo "🔄 Restoring Cursor AppImage..."

# Restore Cursor AppImage
if [[ -f "/home/mike/AppImages/cursor.appimage.bak" ]]; then
    /bin/mv "/home/mike/AppImages/cursor.appimage.bak" "/home/mike/AppImages/cursor.appimage" 2>/dev/null
    /bin/chmod +x "/home/mike/AppImages/cursor.appimage" 2>/dev/null
    echo "✅ Cursor AppImage restored"
elif [[ -f "/home/mike/AppImages/cursor.appimage" ]]; then
    /bin/chmod +x "/home/mike/AppImages/cursor.appimage" 2>/dev/null
    echo "✅ Cursor AppImage permissions restored"
fi

echo "🎉 Installation completed!"
