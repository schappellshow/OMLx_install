#!/bin/bash

# Yazi Dependency Checker
# This script checks what dependencies yazi-fm needs and if they're available

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

# Check if cargo is available
if ! command -v cargo &> /dev/null; then
    print_error "Cargo is not available"
    exit 1
fi

print_status "Checking yazi-fm installation..."

# Check if yazi-fm is already installed
if cargo install --list | grep -q "yazi-fm"; then
    print_success "yazi-fm is already installed"
    exit 0
fi

# Check yazi-fm dependencies
print_status "Checking yazi-fm dependencies..."

# Common dependencies that yazi might need
local deps=(
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

local missing=()
local available=()

for dep in "${deps[@]}"; do
    if dnf search "$dep" 2>/dev/null | grep -q "$dep"; then
        available+=("$dep")
    else
        missing+=("$dep")
    fi
done

print_status "Available dependencies (${#available[@]}):"
for dep in "${available[@]}"; do
    print_success "✓ $dep"
done

if [[ ${#missing[@]} -gt 0 ]]; then
    print_warning "Missing dependencies (${#missing[@]}):"
    for dep in "${missing[@]}"; do
        print_warning "✗ $dep"
    done
fi

# Test yazi-fm installation
print_status "Testing yazi-fm installation..."
if cargo install --dry-run yazi-fm 2>&1 | tee /tmp/yazi_install_test.log; then
    print_success "yazi-fm would install successfully"
else
    print_error "yazi-fm has installation issues"
    print_status "Check /tmp/yazi_install_test.log for details"
    
    # Check for specific error messages
    if grep -q "linking" /tmp/yazi_install_test.log; then
        print_warning "Linking issues detected - may need additional development libraries"
    fi
    
    if grep -q "not found" /tmp/yazi_install_test.log; then
        print_warning "Missing libraries detected - may need additional packages"
    fi
fi

# Check if we can install missing dependencies
if [[ ${#missing[@]} -gt 0 ]]; then
    print_status "Attempting to install missing dependencies..."
    for dep in "${missing[@]}"; do
        print_status "Trying to install: $dep"
        if sudo dnf install --assumeno "$dep" 2>&1 | grep -q "Dependencies resolved"; then
            print_success "✓ $dep would install successfully"
        else
            print_warning "✗ $dep may not be available in repositories"
        fi
    done
fi 