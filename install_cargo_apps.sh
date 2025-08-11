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

# Function to test network connectivity to crates.io
test_network_connectivity() {
    print_status "Testing network connectivity to crates.io..."
    
    # Test DNS resolution
    if nslookup crates.io >/dev/null 2>&1; then
        print_success "DNS resolution to crates.io successful"
    else
        print_warning "DNS resolution to crates.io failed"
        print_status "Trying alternative DNS servers..."
        
        # Try with Google DNS
        if nslookup crates.io 8.8.8.8 >/dev/null 2>&1; then
            print_success "DNS resolution successful with Google DNS (8.8.8.8)"
            print_status "Consider updating your system DNS settings"
        else
            print_error "DNS resolution failed even with Google DNS"
        fi
    fi
    
    # Test HTTP connectivity
    if curl -s --connect-timeout 10 --max-time 30 "https://crates.io" >/dev/null 2>&1; then
        print_success "HTTP connectivity to crates.io successful"
    else
        print_warning "HTTP connectivity to crates.io failed"
        print_status "Checking if it's a firewall or proxy issue..."
        
        # Try with different timeout
        if curl -s --connect-timeout 30 --max-time 60 "https://crates.io" >/dev/null 2>&1; then
            print_success "HTTP connectivity successful with longer timeout"
        else
            print_error "HTTP connectivity failed even with longer timeout"
            print_status "This may indicate a network configuration issue"
        fi
    fi
    
    # Test git connectivity (used by cargo)
    if git ls-remote --exit-code https://github.com/rust-lang/crates.io-index >/dev/null 2>&1; then
        print_success "Git connectivity to crates.io-index successful"
    else
        print_warning "Git connectivity to crates.io-index failed"
        print_status "This may cause cargo installation issues"
    fi
}

# Function to configure cargo for better network handling
configure_cargo_network() {
    print_status "Configuring cargo for better network handling..."
    
    # Create or update cargo config file
    local cargo_config_dir="$HOME/.cargo"
    local cargo_config_file="$cargo_config_dir/config.toml"
    
    mkdir -p "$cargo_config_dir"
    
    # Create cargo config with network optimizations
    cat > "$cargo_config_file" << EOF
[net]
# Increase timeout for network operations
timeout = 120
# Increase retry attempts
retry = 5
# Use git CLI for git operations (more reliable)
git-fetch-with-cli = true

[build]
# Use multiple jobs for faster compilation
jobs = 4
# Enable incremental compilation
incremental = true

[target.x86_64-unknown-linux-gnu]
# Optimize for your system
rustflags = ["-C", "target-cpu=native"]
EOF
    
    print_success "Cargo network configuration created at: $cargo_config_file"
    
    # Set environment variables for current session
    export CARGO_NET_TIMEOUT=120
    export CARGO_NET_RETRY=5
    export CARGO_NET_GIT_FETCH_WITH_CLI=true
    export CARGO_BUILD_JOBS=4
    
    print_status "Cargo environment variables set:"
    print_status "  CARGO_NET_TIMEOUT: $CARGO_NET_TIMEOUT"
    print_status "  CARGO_NET_RETRY: $CARGO_NET_RETRY"
    print_status "  CARGO_NET_GIT_FETCH_WITH_CLI: $CARGO_NET_GIT_FETCH_WITH_CLI"
    print_status "  CARGO_BUILD_JOBS: $CARGO_BUILD_JOBS"
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
    local max_retries=3
    local retry_count=0
    
    print_status "Installing cargo app: $app"
    
    # Configure cargo for better network handling
    print_status "Configuring cargo for better network handling..."
    
    # Set cargo network timeout and retry settings
    export CARGO_NET_TIMEOUT=120
    export CARGO_NET_RETRY=5
    export CARGO_NET_GIT_FETCH_WITH_CLI=true
    
    # Try installation with network optimizations
    while [[ $retry_count -lt $max_retries ]]; do
        retry_count=$((retry_count + 1))
        print_status "Attempt $retry_count of $max_retries for $app"
        
        # Try with network optimizations
        if cargo install --locked --verbose "$app" 2>&1 | tee "/tmp/cargo_${app}_install_${retry_count}.log"; then
            print_success "$app installed successfully on attempt $retry_count"
            return 0
        else
            print_warning "$app installation failed on attempt $retry_count"
            
            # Check for specific error types
            local log_file="/tmp/cargo_${app}_install_${retry_count}.log"
            
            if grep -q "Timeout was reached\|spurious network error\|Resolving timed out" "$log_file"; then
                print_warning "Network timeout detected for $app"
                
                if [[ $retry_count -lt $max_retries ]]; then
                    print_status "Waiting 10 seconds before retry..."
                    sleep 10
                    
                    # Try alternative network configuration
                    print_status "Trying alternative network configuration..."
                    export CARGO_NET_TIMEOUT=180
                    export CARGO_NET_RETRY=10
                    continue
                else
                    print_error "All network attempts failed for $app"
                fi
            elif grep -q "openssl\|OpenSSL" "$log_file"; then
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
            elif grep -q "linking" "$log_file"; then
                print_warning "$app has linking issues - may need additional development libraries"
                if [[ $retry_count -lt $max_retries ]]; then
                    print_status "Trying to install additional development libraries..."
                    sudo dnf install -y gcc-c++ make cmake || {
                        print_warning "Failed to install development libraries"
                    }
                    continue
                fi
            elif grep -q "not found" "$log_file"; then
                print_warning "$app has missing library issues - may need additional packages"
                if [[ $retry_count -lt $max_retries ]]; then
                    print_status "Trying to install additional system packages..."
                    sudo dnf install -y pkgconfig || {
                        print_warning "Failed to install pkgconfig"
                    }
                    continue
                fi
            fi
            
            # If we get here, it's not a retryable error
            break
        fi
    done
    
    # If all retries failed, try alternative installation method
    print_status "Trying alternative installation method for $app..."
    
    # Try with different cargo source
    if cargo install --locked --verbose --git https://github.com/rust-lang/crates.io-index "$app" 2>&1 | tee "/tmp/cargo_${app}_git.log"; then
        print_success "$app installed successfully with git method"
        return 0
    else
        print_error "Failed to install $app with all methods"
        return 1
    fi
}

# Function to provide alternative installation methods
provide_alternatives() {
    print_status "=== ALTERNATIVE INSTALLATION METHODS ==="
    print_status "If cargo installation continues to fail due to network issues, try these alternatives:"
    echo
    echo "1. Use system package manager (OpenMandriva):"
    echo "   sudo dnf install ripgrep fd-find"
    echo
    echo "2. Download pre-compiled binaries:"
    echo "   • ripgrep: https://github.com/BurntSushi/ripgrep/releases"
    echo "   • fd-find: https://github.com/sharkdp/fd/releases"
    echo "   • yazi: https://github.com/ajeetdsouza/zoxide/releases"
    echo
    echo "3. Use flatpak alternatives:"
    echo "   flatpak install org.gnome.FileRoller  # File manager"
    echo "   flatpak install org.gnome.Gedit       # Text editor"
    echo
    echo "4. Network troubleshooting:"
    echo "   • Check firewall settings"
    echo "   • Try different DNS servers (8.8.8.8, 1.1.1.1)"
    echo "   • Use VPN if behind corporate firewall"
    echo "   • Check proxy settings if applicable"
    echo
    echo "5. Retry later:"
    echo "   Network issues may be temporary"
    echo "   You can run this script again later: bash install_cargo_apps.sh"
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
    
    print_success "Cargo applications installation completed!"
    
    # Show alternatives if any installations failed
    if [[ ${#failed_apps[@]} -gt 0 ]]; then
        echo
        provide_alternatives
    fi
}

# Main execution
main() {
    print_status "Starting cargo applications installation..."
    echo
    
    # Check if cargo is available
    check_cargo
    
    # Test network connectivity
    test_network_connectivity
    
    # Configure cargo network settings
    configure_cargo_network
    
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
    
    # Always show alternatives for future reference
    echo
    provide_alternatives
}

# Check if script is being sourced or run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 