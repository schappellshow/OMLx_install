#!/bin/bash

# Cargo Linker Diagnostic for OpenMandriva
# This script identifies and fixes cargo linking issues

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

# Function to check for critical system libraries
check_system_libs() {
    print_status "Checking critical system libraries..."
    echo
    
    # Check for essential libraries mentioned in the error
    local critical_libs=(
        "glibc-devel"      # Provides crti.o, crtn.o, Scrt1.o
        "glibc-static"     # Static libraries
        "libc-devel"       # Alternative name
        "gcc-devel"        # GCC development files
        "binutils-devel"   # Linker tools
        "libstdc++-devel"  # C++ standard library
        "libgcc-devel"     # GCC runtime library
    )
    
    local found=0
    local missing=0
    
    for lib in "${critical_libs[@]}"; do
        print_status "Checking: $lib"
        if check_package "$lib"; then
            ((found++))
        else
            ((missing++))
        fi
        echo
    done
    
    print_status "System libraries summary:"
    print_success "Found: $found packages"
    print_warning "Missing: $missing packages"
    echo
}

# Function to check for development tools
check_dev_tools() {
    print_status "Checking development tools..."
    echo
    
    local dev_tools=(
        "gcc"              # C compiler
        "gcc-c++"          # C++ compiler
        "make"             # Build tool
        "cmake"            # Build system
        "pkgconf"          # Package configuration
        "binutils"         # Linker and assembler
        "glibc-devel"      # C library development
    )
    
    local found=0
    local missing=0
    
    for tool in "${dev_tools[@]}"; do
        print_status "Checking: $tool"
        if check_package "$tool"; then
            ((found++))
        else
            ((missing++))
        fi
        echo
    done
    
    print_status "Development tools summary:"
    print_success "Found: $found packages"
    print_warning "Missing: $missing packages"
    echo
}

# Function to check for specific OpenMandriva packages
check_om_specific() {
    print_status "Checking OpenMandriva-specific packages..."
    echo
    
    local om_packages=(
        "lib64glibc-devel.x86_64"
        "lib64gcc-devel.x86_64"
        "lib64stdc++-devel.x86_64"
        "gcc-devel.x86_64"
        "binutils-devel.x86_64"
        "lib64util-devel.x86_64"
        "lib64rt-devel.x86_64"
        "lib64pthread-devel.x86_64"
        "lib64m-devel.x86_64"
        "lib64dl-devel.x86_64"
        "lib64c-devel.x86_64"
    )
    
    local found=0
    local missing=0
    
    for pkg in "${om_packages[@]}"; do
        print_status "Checking: $pkg"
        if check_package "$pkg"; then
            ((found++))
        else
            ((missing++))
        fi
        echo
    done
    
    print_status "OpenMandriva packages summary:"
    print_success "Found: $found packages"
    print_warning "Missing: $missing packages"
    echo
}

# Function to check linker configuration
check_linker_config() {
    print_status "Checking linker configuration..."
    echo
    
    # Check if essential object files exist
    local obj_files=(
        "/usr/lib64/Scrt1.o"
        "/usr/lib64/crti.o"
        "/usr/lib64/crtn.o"
        "/usr/lib/Scrt1.o"
        "/usr/lib/crti.o"
        "/usr/lib/crtn.o"
    )
    
    local found=0
    local missing=0
    
    for obj in "${obj_files[@]}"; do
        if [[ -f "$obj" ]]; then
            print_success "✓ Found: $obj"
            ((found++))
        else
            print_warning "✗ Missing: $obj"
            ((missing++))
        fi
    done
    
    echo
    
    # Check for essential libraries
    local lib_files=(
        "/usr/lib64/libutil.so"
        "/usr/lib64/librt.so"
        "/usr/lib64/libpthread.so"
        "/usr/lib64/libm.so"
        "/usr/lib64/libdl.so"
        "/usr/lib64/libc.so"
    )
    
    for lib in "${lib_files[@]}"; do
        if [[ -f "$lib" ]]; then
            print_success "✓ Found: $lib"
            ((found++))
        else
            print_warning "✗ Missing: $lib"
            ((missing++))
        fi
    done
    
    echo
    
    print_status "Linker configuration summary:"
    print_success "Found: $found files"
    print_warning "Missing: $missing files"
    echo
}

# Function to check Cargo configuration
check_cargo_config() {
    print_status "Checking Cargo configuration..."
    echo
    
    # Check if cargo is installed
    if command -v cargo >/dev/null 2>&1; then
        print_success "✓ Cargo is installed"
    else
        print_error "✗ Cargo is not installed"
        return 1
    fi
    
    # Check if rustc is installed
    if command -v rustc >/dev/null 2>&1; then
        print_success "✓ Rustc is installed"
    else
        print_error "✗ Rustc is not installed"
        return 1
    fi
    
    # Check cargo version
    local cargo_version=$(cargo --version 2>/dev/null || echo "unknown")
    print_status "Cargo version: $cargo_version"
    
    # Check rustc version
    local rustc_version=$(rustc --version 2>/dev/null || echo "unknown")
    print_status "Rustc version: $rustc_version"
    
    echo
}

# Function to generate fix recommendations
generate_fixes() {
    print_status "Generating fix recommendations..."
    echo
    
    cat > cargo_linker_fixes.txt << 'EOF'
# Cargo Linker Fixes for OpenMandriva
# Generated on $(date)

# =============================================================================
# MISSING PACKAGES TO INSTALL
# =============================================================================

# Essential development libraries for cargo linking
lib64glibc-devel.x86_64
lib64gcc-devel.x86_64
lib64stdc++-devel.x86_64
gcc-devel.x86_64
binutils-devel.x86_64

# Additional development libraries
lib64util-devel.x86_64
lib64rt-devel.x86_64
lib64pthread-devel.x86_64
lib64m-devel.x86_64
lib64dl-devel.x86_64
lib64c-devel.x86_64

# Build tools
gcc.x86_64
gcc-c++.x86_64
make.x86_64
cmake.x86_64
pkgconf.x86_64
binutils.x86_64

# =============================================================================
# COMMANDS TO RUN
# =============================================================================

# Install missing packages
sudo dnf install -y lib64glibc-devel.x86_64 lib64gcc-devel.x86_64 lib64stdc++-devel.x86_64 gcc-devel.x86_64 binutils-devel.x86_64

# Install additional development libraries
sudo dnf install -y lib64util-devel.x86_64 lib64rt-devel.x86_64 lib64pthread-devel.x86_64 lib64m-devel.x86_64 lib64dl-devel.x86_64 lib64c-devel.x86_64

# Install build tools
sudo dnf install -y gcc.x86_64 gcc-c++.x86_64 make.x86_64 cmake.x86_64 pkgconf.x86_64 binutils.x86_64

# =============================================================================
# CARGO CONFIGURATION
# =============================================================================

# Create cargo config to use system linker
mkdir -p ~/.cargo
cat > ~/.cargo/config.toml << 'CARGO_CONFIG'
[target.x86_64-unknown-linux-gnu]
linker = "gcc"
rustflags = ["-C", "link-arg=-fuse-ld=bfd"]

[build]
rustflags = ["-C", "link-arg=-fuse-ld=bfd"]
CARGO_CONFIG

# =============================================================================
# VERIFICATION STEPS
# =============================================================================

# Test cargo installation
cargo install --dry-run ripgrep

# Check if object files exist
ls -la /usr/lib64/Scrt1.o /usr/lib64/crti.o /usr/lib64/crtn.o

# Check if libraries exist
ls -la /usr/lib64/libutil.so /usr/lib64/librt.so /usr/lib64/libpthread.so /usr/lib64/libm.so /usr/lib64/libdl.so /usr/lib64/libc.so

EOF

    print_success "Generated cargo_linker_fixes.txt with detailed fix instructions"
}

# Main execution
main() {
    print_status "Starting Cargo Linker Diagnostic for OpenMandriva..."
    echo
    
    check_system_libs
    check_dev_tools
    check_om_specific
    check_linker_config
    check_cargo_config
    generate_fixes
    
    print_status "Diagnostic complete! Check cargo_linker_fixes.txt for solutions."
}

main "$@" 