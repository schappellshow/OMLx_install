# Cursor AppImage and Gear Lever Flatpak Additions

## **🎯 New Applications Added**

### **1. Gear Lever Flatpak**

#### **Application Details:**
- **Name:** Gear Lever
- **Flatpak ID:** `it.mijorus.gearlever`
- **Description:** A modern file manager for Linux
- **Installation:** Added to `flatpak.txt`

#### **Installation Command:**
```bash
flatpak install it.mijorus.gearlever -y
```

#### **Benefits:**
- **Modern interface** - Clean, intuitive file management
- **Fast performance** - Optimized for speed
- **Cross-platform** - Works on multiple Linux distributions
- **Flatpak distribution** - Self-contained, no dependency issues

### **2. Cursor AppImage**

#### **Application Details:**
- **Name:** Cursor
- **Type:** AppImage
- **Description:** AI-first code editor
- **Installation:** Added to main install script

#### **Installation Process:**
1. **Download AppImage** from official source
2. **Install to `~/.local/bin/cursor.AppImage`**
3. **Make executable** with proper permissions
4. **Create desktop entry** for easy access
5. **Add to applications menu** automatically

#### **Benefits:**
- **AI-powered coding** - Advanced AI assistance
- **No compilation** - Pre-built AppImage
- **Self-contained** - No dependency issues
- **Cross-platform** - Works on multiple Linux distributions
- **Easy updates** - Simple AppImage replacement

## **📋 Installation Details**

### **Gear Lever Flatpak**

**Added to `flatpak.txt`:**
```bash
it.mijorus.gearlever
```

**Installation location:** Standard Flatpak location (`~/.var/app/it.mijorus.gearlever/`)

**Launch method:** Applications menu or `flatpak run it.mijorus.gearlever`

### **Cursor AppImage**

**Installation location:** `~/.local/bin/cursor.AppImage`

**Desktop entry:** `~/.local/share/applications/cursor.desktop`

**Launch methods:**
- Applications menu
- Terminal: `~/.local/bin/cursor.AppImage`
- Desktop shortcut (if created)

## **🔧 Technical Implementation**

### **Cursor AppImage Installation Script:**

```bash
# Install Cursor AppImage
print_status "Installing Cursor AppImage..."

# Create applications directory if it doesn't exist
CURSOR_DIR="$HOME/.local/bin"
mkdir -p "$CURSOR_DIR"

# Download Cursor AppImage
CURSOR_URL="https://download.todesktop.com/230313mzl4w92u92/linux/x64"
CURSOR_FILE="$CURSOR_DIR/cursor.AppImage"

print_status "Downloading Cursor AppImage..."
if curl -L "$CURSOR_URL" -o "$CURSOR_FILE"; then
    # Make AppImage executable
    chmod +x "$CURSOR_FILE"
    
    # Create desktop entry
    print_status "Creating Cursor desktop entry..."
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/cursor.desktop" << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-first code editor
Exec=$CURSOR_FILE
Icon=cursor
Type=Application
Categories=Development;IDE;
StartupWMClass=cursor
EOF
    
    print_success "Cursor AppImage installed successfully"
else
    print_error "Failed to download Cursor AppImage"
fi
```

### **Gear Lever Flatpak Installation:**

**Automatic installation** via the existing Flatpak installation section in the main script.

## **🎯 Expected Results**

### **Gear Lever Installation:**
```bash
[INFO] Installing Flatpak: it.mijorus.gearlever
[SUCCESS] Gear Lever installed successfully
```

### **Cursor AppImage Installation:**
```bash
[INFO] Installing Cursor AppImage...
[INFO] Downloading Cursor AppImage...
[INFO] Creating Cursor desktop entry...
[SUCCESS] Cursor AppImage installed successfully
[INFO] Cursor is available at: ~/.local/bin/cursor.AppImage
[INFO] You can launch it from your applications menu or by running: ~/.local/bin/cursor.AppImage
```

## **🧪 Testing Recommendations**

### **1. Test Gear Lever Installation**
```bash
# Check if Gear Lever is installed
flatpak list | grep gearlever

# Launch Gear Lever
flatpak run it.mijorus.gearlever
```

### **2. Test Cursor AppImage Installation**
```bash
# Check if Cursor AppImage exists
ls -la ~/.local/bin/cursor.AppImage

# Test Cursor launch
~/.local/bin/cursor.AppImage --version

# Check desktop entry
cat ~/.local/share/applications/cursor.desktop
```

### **3. Test Full Installation**
```bash
# Run the complete install script
./install_test_1.sh
```

## **📋 Installation Order**

### **Updated Installation Sequence:**
1. **System updates and essential dependencies**
2. **Native packages** (from packages.txt)
3. **Flatpak applications** (including Gear Lever)
4. **Python applications**
5. **Individual RPM packages**
6. **[NEW] Cursor AppImage**
7. **Git-based projects** (including espanso)
8. **Oh My Zsh installation**
9. **Dotfiles setup**
10. **Cargo applications** (optional, with prompt)

## **🔍 Troubleshooting**

### **If Cursor AppImage Fails:**

#### **1. Check Download URL**
```bash
# Test download URL
curl -I https://download.todesktop.com/230313mzl4w92u92/linux/x64
```

#### **2. Manual Installation**
```bash
# Download manually
curl -L "https://download.todesktop.com/230313mzl4w92u92/linux/x64" -o ~/.local/bin/cursor.AppImage

# Make executable
chmod +x ~/.local/bin/cursor.AppImage

# Test launch
~/.local/bin/cursor.AppImage
```

#### **3. Alternative Download Sources**
- Check Cursor's official website for updated download links
- Use alternative download mirrors if available

### **If Gear Lever Flatpak Fails:**

#### **1. Check Flatpak Installation**
```bash
# Verify Flatpak is working
flatpak --version

# Update Flatpak repositories
flatpak update
```

#### **2. Manual Installation**
```bash
# Install manually
flatpak install it.mijorus.gearlever -y

# Launch manually
flatpak run it.mijorus.gearlever
```

## **📝 Summary**

### **✅ What's Added:**
1. **Gear Lever Flatpak** - Modern file manager via Flatpak
2. **Cursor AppImage** - AI-first code editor via AppImage
3. **Desktop integration** - Both apps appear in applications menu
4. **Easy access** - Multiple launch methods available

### **🎯 Benefits:**
- **Modern tools** - Latest file manager and code editor
- **No compilation** - Both are pre-built packages
- **Cross-platform** - Work on multiple Linux distributions
- **Easy maintenance** - Simple updates and replacements

### **🚀 Expected Improvements:**
- **Better file management** with Gear Lever
- **Enhanced coding experience** with Cursor's AI features
- **More complete development environment** with both tools
- **Consistent installation** across different systems

These additions provide you with modern, powerful tools for both file management and code editing! 🎉 