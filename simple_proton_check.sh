#!/bin/bash

# Simple Proton Pass Dependency Checker
# This script checks which Proton Pass dependencies are actually available

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

# Function to check if a package exists
check_package() {
    local package="$1"
    
    if dnf search "$package" 2>/dev/null | grep -q "$package"; then
        print_success "✓ Found: $package"
        return 0
    else
        print_warning "✗ Not found: $package"
        return 1
    fi
}

# Proton Pass dependencies from packages.txt
proton_deps=(
    # Core Proton Pass dependencies
    "libXtst" "gtk3" "libdrm" "mesa-libgbm" "at-spi2-core"
    
    # X11 development libraries (for Proton Pass GUI)
    "libx11-devel" "libxcb-devel" "libxrandr-devel" "libxinerama-devel"
    "libxcursor-devel" "libxfixes-devel" "libxrender-devel" "libxext-devel"
    "libxcomposite-devel" "libxdamage-devel" "libxtst-devel" "libxi-devel"
    "libxkbcommon-devel"
    
    # GUI libraries (for Proton Pass)
    "libgtk+3.0-devel" "libglib2.0-devel" "libatspi-devel" "libgdk3_0"
    "libgdk-x11_2.0_0" "libcairo-devel" "libpango1.0-devel"
    "libgdk_pixbuf2.0-devel" "libfreetype6-devel" "libfontconfig-devel"
    "libharfbuzz-devel"
    
    # Additional Proton Pass dependencies
    "libssl-devel" "libz-devel" "libffi-devel" "libxml2-devel" "libcurl-devel"
    "libsqlite3-devel" "libpcre-devel" "libjpeg-devel" "libpng-devel"
    "libtiff-devel" "libwebp-devel" "libavif-devel" "libgif-devel"
    "libuuid-devel" "liblzma-devel" "libbz2-devel" "libcrypt-devel"
    "libmount-devel" "libseccomp-devel" "libsystemd-devel"
)

print_status "Checking Proton Pass dependencies in OpenMandriva repositories..."
echo

found=0
missing=0

for dep in "${proton_deps[@]}"; do
    print_status "Checking: $dep"
    
    if check_package "$dep"; then
        ((found++))
    else
        ((missing++))
        
        # Try some common alternatives
        case "$dep" in
            lib*)
                alt="${dep#lib}"
                if dnf search "$alt" 2>/dev/null | grep -q "$alt"; then
                    print_success "  → Alternative found: $alt"
                fi
                ;;
            *-devel)
                alt="${dep%-devel}"
                if dnf search "$alt" 2>/dev/null | grep -q "$alt"; then
                    print_success "  → Alternative found: $alt"
                fi
                ;;
            gtk3)
                if dnf search "gtk+3.0" 2>/dev/null | grep -q "gtk+3.0"; then
                    print_success "  → Alternative found: gtk+3.0"
                fi
                ;;
            mesa-libgbm)
                if dnf search "libgbm" 2>/dev/null | grep -q "libgbm"; then
                    print_success "  → Alternative found: libgbm"
                fi
                ;;
        esac
    fi
    echo
done

print_status "Summary:"
print_success "Found: $found packages"
print_warning "Missing: $missing packages"

# Create corrected packages list
print_status "Creating corrected packages list..."
cat > proton_pass_corrected_deps.txt << EOF
# Proton Pass Dependencies - OpenMandriva Corrected
# Generated on $(date)
# 
# Found: $found packages
# Missing: $missing packages

EOF

print_status "Check proton_pass_corrected_deps.txt for the corrected dependency list." 