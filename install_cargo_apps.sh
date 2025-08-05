#!/bin/bash

# Cargo Applications Installation Script
# This script installs Rust applications via cargo with proper OpenSSL configuration

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

# Function to check if cargo is available
check_cargo() {
    if ! command -v cargo >/dev/null 2>&1; then
        print_error "Cargo is not installed. Please install Rust and Cargo first."
        print_status "You can install Rust by running: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
    print_success "Cargo is available"
}

# Function to configure OpenSSL for cargo builds
configure_openssl() {
    print_status "Configuring OpenSSL for cargo builds..."
    
    # Set OpenSSL environment variables
    export OPENSSL_DIR=$(pkg-config --variable=prefix openssl)
    export OPENSSL_LIB_DIR=$(pkg-config --variable=libdir openssl)
    export OPENSSL_INCLUDE_DIR=$(pkg-config --variable=includedir openssl)
    export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"
    
    print_status "OpenSSL configuration:"
    print_status "  OPENSSL_DIR: $OPENSSL_DIR"
    print_status "  OPENSSL_LIB_DIR: $OPENSSL_LIB_DIR"
    print_status "  OPENSSL_INCLUDE_DIR: $OPENSSL_INCLUDE_DIR"
    print_status "  PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
    
    # Verify OpenSSL is accessible
    if pkg-config --exists openssl; then
        print_success "OpenSSL is properly configured"
    else
        print_error "OpenSSL not found by pkg-config"
        print_status "Installing OpenSSL development packages..."
        sudo dnf install -y libopenssl-devel.x86_64 lib64openssl-devel.x86_64 || {
            print_error "Failed to install OpenSSL development packages"
            exit 1
        }
    fi
}

# Function to install a single cargo application
install_cargo_app() {
    local app="$1"
    print_status "Installing cargo app: $app"
    
    # Try installation with detailed error reporting
    if cargo install --locked "$app" 2>&1 | tee "/tmp/cargo_${app}_install.log"; then
        print_success "$app installed successfully"
        return 0
    else
        print_warning "$app installation failed, checking for dependency issues..."
        
        # Check for OpenSSL issues specifically
        if grep -q "openssl\|OpenSSL" "/tmp/cargo_${app}_install.log"; then
            print_warning "$app has OpenSSL issues - checking OpenSSL configuration..."
            
            # Verify OpenSSL is properly installed
            if ! pkg-config --exists openssl; then
                print_error "OpenSSL not found by pkg-config, installing development packages..."
                sudo dnf install -y libopenssl-devel.x86_64 lib64openssl-devel.x86_64 || {
                    print_error "Failed to install OpenSSL development packages"
                    return 1
                }
            fi
            
            # Try with explicit OpenSSL environment variables
            print_status "Retrying $app with explicit OpenSSL configuration..."
            if OPENSSL_DIR=$(pkg-config --variable=prefix openssl) \
               OPENSSL_LIB_DIR=$(pkg-config --variable=libdir openssl) \
               OPENSSL_INCLUDE_DIR=$(pkg-config --variable=includedir openssl) \
               cargo install --locked "$app" 2>&1 | tee "/tmp/cargo_${app}_openssl.log"; then
                print_success "$app installed successfully with explicit OpenSSL config"
                return 0
            else
                print_error "Failed to install $app even with explicit OpenSSL configuration"
                return 1
            fi
        elif grep -q "linking" "/tmp/cargo_${app}_install.log"; then
            print_warning "$app has linking issues - may need additional development libraries"
        elif grep -q "not found" "/tmp/cargo_${app}_install.log"; then
            print_warning "$app has missing library issues - may need additional packages"
        fi
        
        # Try alternative installation method if not already tried
        if ! grep -q "openssl\|OpenSSL" "/tmp/cargo_${app}_install.log"; then
            print_status "Trying alternative installation method for $app..."
            if cargo install --locked --verbose "$app" 2>&1 | tee "/tmp/cargo_${app}_verbose.log"; then
                print_success "$app installed successfully with verbose mode"
                return 0
            else
                print_error "Failed to install $app with all methods"
                return 1
            fi
        fi
        
        return 1
    fi
}

# Function to install all cargo applications
install_all_cargo_apps() {
    print_status "Installing all cargo applications..."
    
    # Define cargo applications to install
    local cargo_apps=("cargo-make" "cargo-update" "fd-find" "resvg" "ripgrep" "rust-script" "yazi-fm" "yazi-cli")
    
    local successful_apps=()
    local failed_apps=()
    
    # Install cargo applications one by one for better error handling
    for app in "${cargo_apps[@]}"; do
        if install_cargo_app "$app"; then
            successful_apps+=("$app")
        else
            failed_apps+=("$app")
        fi
    done
    
    # Report results
    print_status "=== CARGO INSTALLATION SUMMARY ==="
    print_success "Successfully installed: ${#successful_apps[@]} applications"
    for app in "${successful_apps[@]}"; do
        print_success "  ✓ $app"
    done
    
    if [[ ${#failed_apps[@]} -gt 0 ]]; then
        print_warning "Failed to install: ${#failed_apps[@]} applications"
        for app in "${failed_apps[@]}"; do
            print_warning "  ⚠ $app"
        done
    fi
    
    print_status "Total applications processed: $(( ${#successful_apps[@]} + ${#failed_apps[@]} ))"
}

# Function to show available cargo applications
show_available_apps() {
    print_status "Available cargo applications:"
    echo "  • cargo-make    - Task runner and build tool"
    echo "  • cargo-update  - Update installed binaries"
    echo "  • fd-find       - Fast file finder"
    echo "  • resvg         - SVG renderer"
    echo "  • ripgrep       - Fast text search"
    echo "  • rust-script   - Rust scripting tool"
    echo "  • yazi-fm       - Terminal file manager"
    echo "  • yazi-cli      - Yazi command line interface"
    echo
}

# Function to install specific cargo applications
install_specific_apps() {
    print_status "Enter the names of cargo applications to install (space-separated):"
    print_status "Example: cargo-make fd-find ripgrep"
    read -p "Applications: " -r app_list
    
    if [[ -z "$app_list" ]]; then
        print_warning "No applications specified, skipping cargo installation"
        return
    fi
    
    local successful_apps=()
    local failed_apps=()
    
    for app in $app_list; do
        if install_cargo_app "$app"; then
            successful_apps+=("$app")
        else
            failed_apps+=("$app")
        fi
    done
    
    # Report results
    print_status "=== CARGO INSTALLATION SUMMARY ==="
    print_success "Successfully installed: ${#successful_apps[@]} applications"
    for app in "${successful_apps[@]}"; do
        print_success "  ✓ $app"
    done
    
    if [[ ${#failed_apps[@]} -gt 0 ]]; then
        print_warning "Failed to install: ${#failed_apps[@]} applications"
        for app in "${failed_apps[@]}"; do
            print_warning "  ⚠ $app"
        done
    fi
}

# Main execution
main() {
    print_status "Starting cargo applications installation..."
    echo
    
    # Check if cargo is available
    check_cargo
    
    # Configure OpenSSL
    configure_openssl
    
    # Show available applications
    show_available_apps
    
    # Ask user what they want to install
    print_status "What would you like to install?"
    echo "1) Install all cargo applications"
    echo "2) Install specific cargo applications"
    echo "3) Skip cargo installation"
    echo
    
    read -p "Enter your choice (1-3): " -r choice
    
    case $choice in
        1)
            print_status "Installing all cargo applications..."
            install_all_cargo_apps
            ;;
        2)
            print_status "Installing specific cargo applications..."
            install_specific_apps
            ;;
        3)
            print_warning "Skipping cargo installation"
            ;;
        *)
            print_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    
    print_success "Cargo applications installation completed!"
}

# Check if script is being sourced or run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 