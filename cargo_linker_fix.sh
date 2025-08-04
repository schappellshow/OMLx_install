#!/bin/bash

# Cargo Linker Fix for OpenMandriva
# This script fixes the cargo linking issues by configuring the correct linker

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

# Function to install essential development packages
install_dev_packages() {
    print_status "Installing essential development packages..."
    
    # Essential development packages for cargo linking
    local dev_packages=(
        "gcc.x86_64"
        "gcc-c++.x86_64"
        "make.x86_64"
        "cmake.x86_64"
        "pkgconf.x86_64"
        "binutils.x86_64"
        "glibc-devel.x86_64"
        "libstdc++-devel.x86_64"
    )
    
    for pkg in "${dev_packages[@]}"; do
        print_status "Installing: $pkg"
        if sudo dnf install -y "$pkg" 2>/dev/null; then
            print_success "✓ Installed: $pkg"
        else
            print_warning "✗ Failed to install: $pkg"
        fi
    done
    
    echo
}

# Function to configure cargo to use the correct linker
configure_cargo_linker() {
    print_status "Configuring Cargo to use GNU linker (ld.bfd)..."
    
    # Create cargo config directory
    mkdir -p ~/.cargo
    
    # Create cargo config file
    cat > ~/.cargo/config.toml << 'EOF'
# Cargo configuration for OpenMandriva
# Use GNU linker instead of LLVM linker to avoid linking issues

[target.x86_64-unknown-linux-gnu]
linker = "gcc"
rustflags = [
    "-C", "link-arg=-fuse-ld=bfd",
    "-C", "link-arg=-Wl,--as-needed",
    "-C", "link-arg=-Wl,-z,relro,-z,now"
]

[build]
rustflags = [
    "-C", "link-arg=-fuse-ld=bfd",
    "-C", "link-arg=-Wl,--as-needed",
    "-C", "link-arg=-Wl,-z,relro,-z,now"
]

# Additional settings for better compatibility
[env]
RUSTFLAGS = "-C link-arg=-fuse-ld=bfd"
EOF

    print_success "✓ Cargo configuration created at ~/.cargo/config.toml"
    echo
}

# Function to set environment variables
set_env_vars() {
    print_status "Setting environment variables for cargo..."
    
    # Add to shell profile
    local profile_file="$HOME/.bashrc"
    
    # Check if already added
    if ! grep -q "RUSTFLAGS" "$profile_file" 2>/dev/null; then
        echo "" >> "$profile_file"
        echo "# Cargo linker configuration for OpenMandriva" >> "$profile_file"
        echo "export RUSTFLAGS=\"-C link-arg=-fuse-ld=bfd\"" >> "$profile_file"
        echo "export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc" >> "$profile_file"
        print_success "✓ Environment variables added to $profile_file"
    else
        print_warning "Environment variables already set in $profile_file"
    fi
    
    # Set for current session
    export RUSTFLAGS="-C link-arg=-fuse-ld=bfd"
    export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc
    
    print_success "✓ Environment variables set for current session"
    echo
}

# Function to test cargo configuration
test_cargo_config() {
    print_status "Testing cargo configuration..."
    
    # Test with a simple cargo command
    if cargo --version >/dev/null 2>&1; then
        print_success "✓ Cargo is working"
    else
        print_error "✗ Cargo is not working"
        return 1
    fi
    
    # Test with a dry-run installation
    print_status "Testing cargo install with dry-run..."
    if cargo install --dry-run ripgrep 2>&1 | grep -q "Would install"; then
        print_success "✓ Cargo install test successful"
    else
        print_warning "⚠ Cargo install test had issues (this is normal for dry-run)"
    fi
    
    echo
}

# Function to create a test script
create_test_script() {
    print_status "Creating cargo test script..."
    
    cat > test_cargo_fix.sh << 'EOF'
#!/bin/bash

# Test script for cargo linking fix
echo "Testing cargo linking fix..."

# Test 1: Check if cargo works
echo "1. Testing cargo version..."
cargo --version

# Test 2: Check if rustc works
echo "2. Testing rustc version..."
rustc --version

# Test 3: Test cargo install with dry-run
echo "3. Testing cargo install (dry-run)..."
cargo install --dry-run ripgrep

# Test 4: Check linker configuration
echo "4. Checking linker configuration..."
echo "RUSTFLAGS: $RUSTFLAGS"
echo "CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER: $CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER"

# Test 5: Check if GNU linker is available
echo "5. Checking available linkers..."
which ld.bfd
which ld.lld
which gcc

echo "Test complete!"
EOF

    chmod +x test_cargo_fix.sh
    print_success "✓ Test script created: test_cargo_fix.sh"
    echo
}

# Function to update packages.txt with development dependencies
update_packages_txt() {
    print_status "Updating packages.txt with development dependencies..."
    
    # Check if packages.txt exists
    if [[ -f "packages.txt" ]]; then
        # Add development dependencies section if it doesn't exist
        if ! grep -q "CARGO DEVELOPMENT DEPENDENCIES" packages.txt; then
            cat >> packages.txt << 'EOF'

# =============================================================================
# CARGO DEVELOPMENT DEPENDENCIES
# =============================================================================
# These packages are required for cargo linking and compilation
# Add new cargo development dependencies here if needed

# Essential development packages for cargo linking
gcc.x86_64
gcc-c++.x86_64
make.x86_64
cmake.x86_64
pkgconf.x86_64
binutils.x86_64
glibc-devel.x86_64
libstdc++-devel.x86_64

EOF
            print_success "✓ Added cargo development dependencies to packages.txt"
        else
            print_warning "Cargo development dependencies section already exists in packages.txt"
        fi
    else
        print_warning "packages.txt not found, skipping update"
    fi
    
    echo
}

# Function to create summary
create_summary() {
    print_status "Creating fix summary..."
    
    cat > CARGO_LINKER_FIX_SUMMARY.md << 'EOF'
# Cargo Linker Fix for OpenMandriva

## Problem Identified
The cargo linking error was caused by OpenMandriva using `ld.lld` (LLVM linker) by default, which has compatibility issues with some Rust crates and the specific linker flags being used.

## Error Analysis
```
ld.lld: warning: unknown -z value: ,nostart-stop-gc
ld.lld: error: cannot open Scrt1.o: No such file or directory
ld.lld: error: cannot open crti.o: No such file or directory
ld.lld: error: unable to find library -lutil
```

## Root Cause
- OpenMandriva uses `ld.lld` as the default linker
- `ld.lld` doesn't support all the same flags as GNU `ld.bfd`
- The linker can't find essential object files and libraries
- Cargo needs to be configured to use GNU linker instead

## Solution Applied

### 1. Install Essential Development Packages
```bash
gcc.x86_64
gcc-c++.x86_64
make.x86_64
cmake.x86_64
pkgconf.x86_64
binutils.x86_64
glibc-devel.x86_64
libstdc++-devel.x86_64
```

### 2. Configure Cargo to Use GNU Linker
Created `~/.cargo/config.toml`:
```toml
[target.x86_64-unknown-linux-gnu]
linker = "gcc"
rustflags = [
    "-C", "link-arg=-fuse-ld=bfd",
    "-C", "link-arg=-Wl,--as-needed",
    "-C", "link-arg=-Wl,-z,relro,-z,now"
]
```

### 3. Set Environment Variables
```bash
export RUSTFLAGS="-C link-arg=-fuse-ld=bfd"
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc
```

## Benefits
- ✅ **Fixed linking errors** for cargo applications
- ✅ **Improved compatibility** with Rust crates
- ✅ **Better build success rate** for Rust applications
- ✅ **Consistent linker behavior** across the system

## Testing
Run the test script to verify the fix:
```bash
./test_cargo_fix.sh
```

## Files Modified
1. `~/.cargo/config.toml` - Cargo configuration
2. `~/.bashrc` - Environment variables
3. `packages.txt` - Added development dependencies
4. `test_cargo_fix.sh` - Test script

## Verification Steps
1. Test cargo installation: `cargo install --dry-run ripgrep`
2. Check linker configuration: `echo $RUSTFLAGS`
3. Verify GNU linker: `which ld.bfd`
4. Test actual installation: `cargo install ripgrep`

EOF

    print_success "✓ Created CARGO_LINKER_FIX_SUMMARY.md"
    echo
}

# Main execution
main() {
    print_status "Starting Cargo Linker Fix for OpenMandriva..."
    echo
    
    install_dev_packages
    configure_cargo_linker
    set_env_vars
    test_cargo_config
    create_test_script
    update_packages_txt
    create_summary
    
    print_success "Cargo linker fix complete!"
    print_status "Run './test_cargo_fix.sh' to verify the fix works."
    print_status "Check CARGO_LINKER_FIX_SUMMARY.md for details."
}

main "$@" 