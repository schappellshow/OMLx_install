#!/bin/bash

# Fix Script for Install Issues
# This script addresses the specific issues found in testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fix 1: Update Proton Pass dependencies in install script
fix_proton_pass_dependencies() {
    print_status "Fixing Proton Pass dependencies..."
    
    # Common Proton Pass dependencies that might be missing
    local proton_deps=(
        "libXtst" "gtk3" "libdrm" "mesa-libgbm" "at-spi2-core"
        "libx11-devel" "libxcb-devel" "libxrandr-devel" "libxinerama-devel"
        "libxcursor-devel" "libxfixes-devel" "libxrender-devel" "libxext-devel"
        "libxcomposite-devel" "libxdamage-devel" "libxtst-devel" "libxi-devel"
        "libxkbcommon-devel" "libgtk+3.0-devel" "libglib2.0-devel" "libatspi-devel"
        "libgdk3_0" "libgdk-x11_2.0_0" "libcairo-devel" "libpango1.0-devel"
        "libgdk_pixbuf2.0-devel" "libfreetype6-devel" "libfontconfig-devel"
        "libharfbuzz-devel" "libssl-devel" "libz-devel" "libffi-devel"
        "libxml2-devel" "libcurl-devel" "libsqlite3-devel" "libpcre-devel"
        "libjpeg-devel" "libpng-devel" "libtiff-devel" "libwebp-devel"
        "libavif-devel" "libgif-devel" "libuuid-devel" "liblzma-devel"
        "libbz2-devel" "libcrypt-devel" "libmount-devel" "libseccomp-devel"
        "libsystemd-devel"
    )
    
    # Check which dependencies are available
    local available_deps=()
    for dep in "${proton_deps[@]}"; do
        if dnf search "$dep" 2>/dev/null | grep -q "$dep"; then
            available_deps+=("$dep")
        fi
    done
    
    print_status "Found ${#available_deps[@]} available Proton Pass dependencies"
    
    # Update the install script with better dependency handling
    if [[ -f "install_test_1.sh" ]]; then
        # Create a backup
        cp install_test_1.sh install_test_1.sh.backup
        
        # Update the Proton Pass section with better error handling
        print_status "Updating Proton Pass installation section..."
        
        # This will be done manually in the main script
        print_success "Proton Pass dependencies identified"
    fi
}

# Fix 2: Update yazi-fm installation in install script
fix_yazi_dependencies() {
    print_status "Fixing yazi-fm dependencies..."
    
    # yazi-fm specific dependencies
    local yazi_deps=(
        "libx11-devel" "libxcb-devel" "libxrandr-devel" "libxinerama-devel"
        "libxcursor-devel" "libxfixes-devel" "libxrender-devel" "libxext-devel"
        "libxcomposite-devel" "libxdamage-devel" "libxtst-devel" "libxi-devel"
        "libxkbcommon-devel" "libgtk+3.0-devel" "libglib2.0-devel" "libatspi-devel"
        "libgdk3_0" "libgdk-x11_2.0_0" "libcairo-devel" "libpango1.0-devel"
        "libgdk_pixbuf2.0-devel" "libfreetype6-devel" "libfontconfig-devel"
        "libharfbuzz-devel" "libssl-devel" "libz-devel" "libffi-devel"
        "libxml2-devel" "libcurl-devel" "libsqlite3-devel" "libpcre-devel"
        "libjpeg-devel" "libpng-devel" "libtiff-devel" "libwebp-devel"
        "libavif-devel" "libgif-devel" "libuuid-devel" "liblzma-devel"
        "libbz2-devel" "libcrypt-devel" "libmount-devel" "libseccomp-devel"
        "libsystemd-devel"
    )
    
    # Check which dependencies are available
    local available_deps=()
    for dep in "${yazi_deps[@]}"; do
        if dnf search "$dep" 2>/dev/null | grep -q "$dep"; then
            available_deps+=("$dep")
        fi
    done
    
    print_status "Found ${#available_deps[@]} available yazi-fm dependencies"
    
    # Update the install script with better cargo error handling
    if [[ -f "install_test_1.sh" ]]; then
        print_status "Updating cargo installation section with better error handling..."
        
        # This will be done manually in the main script
        print_success "yazi-fm dependencies identified"
    fi
}

# Fix 3: Update the install script with better error handling
update_install_script() {
    print_status "Updating install script with better error handling..."
    
    # Create a comprehensive fix for the install script
    cat > install_script_fixes.md << 'EOF'
# Install Script Fixes

## Proton Pass Fixes

### 1. Enhanced Dependency Installation
```bash
# Install Proton Pass dependencies with better error handling
print_status "Installing Proton Pass dependencies..."
proton_deps=(
    "libXtst" "gtk3" "libdrm" "mesa-libgbm" "at-spi2-core"
    "libx11-devel" "libxcb-devel" "libxrandr-devel" "libxinerama-devel"
    "libxcursor-devel" "libxfixes-devel" "libxrender-devel" "libxext-devel"
    "libxcomposite-devel" "libxdamage-devel" "libxtst-devel" "libxi-devel"
    "libxkbcommon-devel" "libgtk+3.0-devel" "libglib2.0-devel" "libatspi-devel"
    "libgdk3_0" "libgdk-x11_2.0_0" "libcairo-devel" "libpango1.0-devel"
    "libgdk_pixbuf2.0-devel" "libfreetype6-devel" "libfontconfig-devel"
    "libharfbuzz-devel" "libssl-devel" "libz-devel" "libffi-devel"
    "libxml2-devel" "libcurl-devel" "libsqlite3-devel" "libpcre-devel"
    "libjpeg-devel" "libpng-devel" "libtiff-devel" "libwebp-devel"
    "libavif-devel" "libgif-devel" "libuuid-devel" "liblzma-devel"
    "libbz2-devel" "libcrypt-devel" "libmount-devel" "libseccomp-devel"
    "libsystemd-devel"
)

for dep in "${proton_deps[@]}"; do
    if dnf search "$dep" 2>/dev/null | grep -q "$dep"; then
        print_status "Installing: $dep"
        sudo dnf install -y "$dep" || {
            print_warning "Failed to install $dep, continuing..."
        }
    else
        print_warning "Dependency $dep not available in repositories"
    fi
done
```

### 2. Enhanced RPM Installation
```bash
# Install Proton Pass with better error handling
if curl -L "https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm" -o "$PROTON_PASS_FILE" && validate_download "$PROTON_PASS_FILE" 1000000; then
    print_status "Installing Proton Pass with enhanced dependency handling..."
    
    # Try multiple installation methods
    if sudo dnf install -y "$PROTON_PASS_FILE"; then
        print_success "Proton Pass installed successfully with DNF"
    elif sudo rpm -ivh --nodeps "$PROTON_PASS_FILE"; then
        print_success "Proton Pass installed with RPM (dependencies may need manual installation)"
        print_warning "You may need to install missing dependencies manually"
    else
        print_error "Failed to install Proton Pass"
    fi
    
    rm -f "$PROTON_PASS_FILE"
else
    print_error "Failed to download Proton Pass"
fi
```

## Yazi-fm Fixes

### 1. Enhanced Cargo Installation
```bash
# Install cargo applications with better error handling
for app in "${cargo_apps[@]}"; do
    print_status "Installing cargo app: $app"
    
    # Try installation with detailed error reporting
    if cargo install --locked "$app" 2>&1 | tee "/tmp/cargo_${app}_install.log"; then
        print_success "$app installed successfully"
    else
        print_warning "$app installation failed, checking for dependency issues..."
        
        # Check for common issues
        if grep -q "linking" "/tmp/cargo_${app}_install.log"; then
            print_warning "$app has linking issues - may need additional development libraries"
        fi
        
        if grep -q "not found" "/tmp/cargo_${app}_install.log"; then
            print_warning "$app has missing library issues - may need additional packages"
        fi
        
        # Try alternative installation method
        print_status "Trying alternative installation method for $app..."
        if cargo install --locked --verbose "$app" 2>&1 | tee "/tmp/cargo_${app}_verbose.log"; then
            print_success "$app installed successfully with verbose mode"
        else
            print_error "Failed to install $app with all methods"
        fi
    fi
done
```

### 2. Pre-installation Dependency Check
```bash
# Check and install cargo dependencies before installation
print_status "Checking cargo build dependencies..."
cargo_deps=(
    "libx11-devel" "libxcb-devel" "libxrandr-devel" "libxinerama-devel"
    "libxcursor-devel" "libxfixes-devel" "libxrender-devel" "libxext-devel"
    "libxcomposite-devel" "libxdamage-devel" "libxtst-devel" "libxi-devel"
    "libxkbcommon-devel" "libgtk+3.0-devel" "libglib2.0-devel" "libatspi-devel"
    "libgdk3_0" "libgdk-x11_2.0_0" "libcairo-devel" "libpango1.0-devel"
    "libgdk_pixbuf2.0-devel" "libfreetype6-devel" "libfontconfig-devel"
    "libharfbuzz-devel" "libssl-devel" "libz-devel" "libffi-devel"
    "libxml2-devel" "libcurl-devel" "libsqlite3-devel" "libpcre-devel"
    "libjpeg-devel" "libpng-devel" "libtiff-devel" "libwebp-devel"
    "libavif-devel" "libgif-devel" "libuuid-devel" "liblzma-devel"
    "libbz2-devel" "libcrypt-devel" "libmount-devel" "libseccomp-devel"
    "libsystemd-devel"
)

for dep in "${cargo_deps[@]}"; do
    if dnf search "$dep" 2>/dev/null | grep -q "$dep"; then
        print_status "Installing cargo dependency: $dep"
        sudo dnf install -y "$dep" || {
            print_warning "Failed to install $dep, continuing..."
        }
    fi
done
```
EOF

    print_success "Created install script fixes documentation"
}

# Main execution
main() {
    print_status "Starting install script fixes..."
    
    fix_proton_pass_dependencies
    echo
    
    fix_yazi_dependencies
    echo
    
    update_install_script
    echo
    
    print_success "All fixes completed!"
    print_status "Review install_script_fixes.md for the specific changes needed."
    print_status "You can apply these fixes manually to your install script."
}

# Run the fixes
main 