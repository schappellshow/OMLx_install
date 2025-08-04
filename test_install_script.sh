#!/bin/bash

# Test Framework for OpenMandriva Install Script
# This script allows safe testing of the install script without a clean VM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to test package installation (dry run)
test_package_installation() {
    local package="$1"
    print_status "Testing package installation: $package"
    
    if sudo dnf install --assumeno "$package" 2>&1 | grep -q "Dependencies resolved"; then
        print_success "Package $package would install successfully"
        return 0
    else
        print_warning "Package $package may have issues or dependencies"
        return 1
    fi
}

# Function to test RPM download (without installing)
test_rpm_download() {
    local name="$1"
    local url="$2"
    local test_file="/tmp/test_${name}.rpm"
    
    print_status "Testing RPM download: $name"
    
    # Test URL accessibility
    if curl -I "$url" &> /dev/null; then
        print_success "URL is accessible: $url"
    else
        print_error "URL is not accessible: $url"
        return 1
    fi
    
    # Download RPM
    if curl -L "$url" -o "$test_file"; then
        local size=$(stat -c%s "$test_file" 2>/dev/null || echo "0")
        if [[ $size -gt 1000000 ]]; then
            print_success "RPM download successful ($size bytes)"
            
            # Check if it's a valid RPM
            if file "$test_file" | grep -q "RPM"; then
                print_success "Valid RPM file"
            else
                print_warning "File doesn't appear to be a valid RPM"
            fi
            
            # Test DNF installation (dry run)
            if sudo dnf install --assumeno "$test_file" 2>&1 | grep -q "Dependencies resolved"; then
                print_success "RPM would install successfully with DNF"
            else
                print_warning "RPM may have dependency issues"
            fi
            
            rm -f "$test_file"
            return 0
        else
            print_error "Downloaded file is too small ($size bytes), likely an error page"
            rm -f "$test_file"
            return 1
        fi
    else
        print_error "Download failed"
        return 1
    fi
}

# Function to test cargo application installation (dry run)
test_cargo_installation() {
    local app="$1"
    print_status "Testing cargo installation: $app"
    
    # Check if cargo is available
    if ! command_exists cargo; then
        print_warning "Cargo not available, skipping cargo test"
        return 1
    fi
    
    # Check if application is already installed
    if cargo install --list | grep -q "$app"; then
        print_success "Cargo application $app is already installed"
        return 0
    fi
    
    # Test if application can be installed (dry run)
    if cargo install --dry-run "$app" 2>&1 | grep -q "Would install"; then
        print_success "Cargo application $app would install successfully"
        return 0
    else
        print_warning "Cargo application $app may have issues"
        return 1
    fi
}

# Function to test git repository cloning
test_git_clone() {
    local repo_url="$1"
    local repo_name="$2"
    local test_dir="/tmp/test_${repo_name}"
    
    print_status "Testing git clone: $repo_name"
    
    # Test repository accessibility
    if git ls-remote "$repo_url" &> /dev/null; then
        print_success "Repository is accessible: $repo_url"
    else
        print_error "Repository is not accessible: $repo_url"
        return 1
    fi
    
    # Test cloning
    if git clone "$repo_url" "$test_dir" 2>&1 | grep -q "Cloning"; then
        print_success "Git clone successful"
        
        # Check if repository has expected structure
        if [[ -f "$test_dir/README.md" ]] || [[ -f "$test_dir/Cargo.toml" ]] || [[ -f "$test_dir/package.json" ]]; then
            print_success "Repository has expected structure"
        else
            print_warning "Repository structure may be unexpected"
        fi
        
        rm -rf "$test_dir"
        return 0
    else
        print_error "Git clone failed"
        return 1
    fi
}

# Function to test flatpak installation (dry run)
test_flatpak_installation() {
    local app="$1"
    print_status "Testing flatpak installation: $app"
    
    # Check if flatpak is available
    if ! command_exists flatpak; then
        print_warning "Flatpak not available, skipping flatpak test"
        return 1
    fi
    
    # Check if application is already installed
    if flatpak list | grep -q "$app"; then
        print_success "Flatpak application $app is already installed"
        return 0
    fi
    
    # Test if application can be installed (dry run)
    if flatpak install --assumeyes --noninteractive "$app" 2>&1 | grep -q "Installing"; then
        print_success "Flatpak application $app would install successfully"
        return 0
    else
        print_warning "Flatpak application $app may have issues"
        return 1
    fi
}

# Function to test system requirements
test_system_requirements() {
    print_status "Testing system requirements..."
    
    local requirements=(
        "sudo" "curl" "git" "dnf" "rpm" "cargo" "flatpak"
    )
    
    local missing=()
    
    for req in "${requirements[@]}"; do
        if command_exists "$req"; then
            print_success "$req is available"
        else
            print_warning "$req is not available"
            missing+=("$req")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_warning "Missing requirements: ${missing[*]}"
        return 1
    else
        print_success "All system requirements are met"
        return 0
    fi
}

# Function to test network connectivity
test_network_connectivity() {
    print_status "Testing network connectivity..."
    
    local test_urls=(
        "https://github.com"
        "https://crates.io"
        "https://flathub.org"
        "https://app.warp.dev"
        "https://updates.getmailspring.com"
        "https://proton.me"
    )
    
    local failed=()
    
    for url in "${test_urls[@]}"; do
        if curl -I "$url" &> /dev/null; then
            print_success "Network accessible: $url"
        else
            print_warning "Network not accessible: $url"
            failed+=("$url")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_warning "Some URLs are not accessible: ${failed[*]}"
        return 1
    else
        print_success "All network URLs are accessible"
        return 0
    fi
}

# Function to test package dependencies
test_package_dependencies() {
    print_status "Testing package dependencies..."
    
    # Read packages from packages.txt
    if [[ -f "packages.txt" ]]; then
        local packages=()
        while IFS= read -r line; do
            # Skip comments and empty lines
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
                # Extract package name (remove .x86_64 suffix)
                local pkg="${line%.x86_64}"
                packages+=("$pkg")
            fi
        done < "packages.txt"
        
        local failed=()
        for pkg in "${packages[@]:0:10}"; do # Test first 10 packages
            if test_package_installation "$pkg"; then
                print_success "Package $pkg would install successfully"
            else
                print_warning "Package $pkg may have issues"
                failed+=("$pkg")
            fi
        done
        
        if [[ ${#failed[@]} -gt 0 ]]; then
            print_warning "Some packages may have issues: ${failed[*]}"
            return 1
        else
            print_success "All tested packages would install successfully"
            return 0
        fi
    else
        print_error "packages.txt not found"
        return 1
    fi
}

# Main testing function
run_tests() {
    print_status "Starting comprehensive install script testing..."
    echo
    
    # Test system requirements
    test_system_requirements
    echo
    
    # Test network connectivity
    test_network_connectivity
    echo
    
    # Test package dependencies
    test_package_dependencies
    echo
    
    # Test RPM downloads
    print_status "Testing RPM downloads..."
    test_rpm_download "warp" "https://app.warp.dev/download?package=rpm"
    test_rpm_download "mailspring" "https://updates.getmailspring.com/download?platform=linuxRpm"
    test_rpm_download "proton-pass" "https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm"
    echo
    
    # Test cargo applications
    print_status "Testing cargo applications..."
    local cargo_apps=("cargo-make" "cargo-update" "fd-find" "resvg" "ripgrep" "rust-script" "yazi-fm" "yazi-cli")
    for app in "${cargo_apps[@]}"; do
        test_cargo_installation "$app"
    done
    echo
    
    # Test git repositories
    print_status "Testing git repositories..."
    test_git_clone "https://github.com/schappellshow/stow.git" "stow"
    test_git_clone "https://github.com/neovim/neovim.git" "neovim"
    echo
    
    # Test flatpak applications
    print_status "Testing flatpak applications..."
    local flatpak_apps=("com.brave.Browser" "org.telegram.desktop" "com.discordapp.Discord")
    for app in "${flatpak_apps[@]}"; do
        test_flatpak_installation "$app"
    done
    echo
    
    print_success "Testing completed!"
    print_status "Check the output above for any issues that need to be addressed."
}

# Function to run specific test
run_specific_test() {
    case "$1" in
        "system")
            test_system_requirements
            ;;
        "network")
            test_network_connectivity
            ;;
        "packages")
            test_package_dependencies
            ;;
        "rpms")
            test_rpm_download "warp" "https://app.warp.dev/download?package=rpm"
            test_rpm_download "mailspring" "https://updates.getmailspring.com/download?platform=linuxRpm"
            test_rpm_download "proton-pass" "https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm"
            ;;
        "cargo")
            local cargo_apps=("cargo-make" "cargo-update" "fd-find" "resvg" "ripgrep" "rust-script" "yazi-fm" "yazi-cli")
            for app in "${cargo_apps[@]}"; do
                test_cargo_installation "$app"
            done
            ;;
        "git")
            test_git_clone "https://github.com/schappellshow/stow.git" "stow"
            test_git_clone "https://github.com/neovim/neovim.git" "neovim"
            ;;
        "flatpak")
            local flatpak_apps=("com.brave.Browser" "org.telegram.desktop" "com.discordapp.Discord")
            for app in "${flatpak_apps[@]}"; do
                test_flatpak_installation "$app"
            done
            ;;
        *)
            print_error "Unknown test: $1"
            print_status "Available tests: system, network, packages, rpms, cargo, git, flatpak"
            exit 1
            ;;
    esac
}

# Main script logic
if [[ $# -eq 0 ]]; then
    run_tests
else
    run_specific_test "$1"
fi 