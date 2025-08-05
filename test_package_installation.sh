#!/bin/bash

# Package Installation Diagnostic Script
# This script tests package installation to identify issues

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

# Function to test package installation
test_package_install() {
    local package="$1"
    local package_name=$(echo "$package" | awk '{print $1}')
    
    print_status "Testing installation of: $package_name"
    
    # Check if package exists in repositories
    if dnf search "$package_name" 2>/dev/null | grep -q "$package_name"; then
        print_success "✓ Package found in repositories: $package_name"
        
        # Test dry-run installation
        if sudo dnf install --assumeno "$package_name" 2>/dev/null | grep -q "Dependencies resolved"; then
            print_success "✓ Package can be installed: $package_name"
            return 0
        else
            print_warning "⚠ Package has dependency issues: $package_name"
            return 1
        fi
    else
        print_error "✗ Package not found in repositories: $package_name"
        return 2
    fi
}

# Function to test specific packages
test_specific_packages() {
    local packages=("ghostty.x86_64" "kitty.x86_64" "bat.x86_64" "fzf.x86_64")
    
    print_status "Testing specific packages..."
    echo
    
    for package in "${packages[@]}"; do
        test_package_install "$package"
        echo
    done
}

# Function to test all packages from packages.txt
test_all_packages() {
    local packages_file="./packages.txt"
    local failed_packages=()
    local successful_packages=()
    local not_found_packages=()
    
    print_status "Testing all packages from $packages_file..."
    echo
    
    while IFS= read -r package || [[ -n "$package" ]]; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
        
        local package_name=$(echo "$package" | awk '{print $1}')
        
        # Test the package
        if test_package_install "$package_name" >/dev/null 2>&1; then
            successful_packages+=("$package_name")
        elif [[ $? -eq 2 ]]; then
            not_found_packages+=("$package_name")
        else
            failed_packages+=("$package_name")
        fi
    done < "$packages_file"
    
    # Print summary
    echo
    print_status "=== PACKAGE INSTALLATION TEST SUMMARY ==="
    echo
    
    print_success "Successful packages (${#successful_packages[@]}):"
    for package in "${successful_packages[@]}"; do
        echo "  ✓ $package"
    done
    echo
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_warning "Packages with dependency issues (${#failed_packages[@]}):"
        for package in "${failed_packages[@]}"; do
            echo "  ⚠ $package"
        done
        echo
    fi
    
    if [[ ${#not_found_packages[@]} -gt 0 ]]; then
        print_error "Packages not found in repositories (${#not_found_packages[@]}):"
        for package in "${not_found_packages[@]}"; do
            echo "  ✗ $package"
        done
        echo
    fi
    
    print_status "Total packages tested: $(( ${#successful_packages[@]} + ${#failed_packages[@]} + ${#not_found_packages[@]} ))"
}

# Function to test the actual dnf install command from the script
test_script_install_command() {
    local packages_file="./packages.txt"
    
    print_status "Testing the exact dnf install command from the script..."
    echo
    
    # Get the package list exactly as the script does
    local package_list=$(grep -v '^[[:space:]]*#' "$packages_file" | grep -v '^[[:space:]]*$' | awk '{print $1}')
    
    print_status "Package list to install:"
    echo "$package_list" | head -10
    echo "... (showing first 10 packages)"
    echo
    
    # Test the dry-run installation
    print_status "Testing dry-run installation..."
    if sudo dnf install --assumeno $package_list 2>&1 | tee /tmp/dnf_test_output.log; then
        print_success "✓ All packages can be installed successfully!"
    else
        print_warning "⚠ Some packages failed to install. Check /tmp/dnf_test_output.log for details."
        
        # Show specific failures
        print_status "Failed packages:"
        grep "No match for argument" /tmp/dnf_test_output.log || echo "No 'No match for argument' errors found"
        echo
    fi
}

# Main execution
main() {
    print_status "Starting package installation diagnostic..."
    echo
    
    # Test specific packages first
    test_specific_packages
    echo
    
    # Test the script's install command
    test_script_install_command
    echo
    
    # Test all packages (optional - can be slow)
    read -p "Do you want to test all packages from packages.txt? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_all_packages
    else
        print_status "Skipping full package test. Run with 'test_all_packages' to test all packages."
    fi
    
    print_status "Package installation diagnostic complete!"
}

main "$@" 