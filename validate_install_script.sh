#!/bin/bash

# Install Script Validator
# This script validates the install script without running it

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

# Function to check script syntax
check_syntax() {
    local script="$1"
    print_status "Checking syntax for $script..."
    
    if bash -n "$script" 2>&1; then
        print_success "Syntax check passed for $script"
        return 0
    else
        print_error "Syntax check failed for $script"
        return 1
    fi
}

# Function to check for common issues
check_common_issues() {
    local script="$1"
    print_status "Checking for common issues in $script..."
    
    local issues=0
    
    # Check for hardcoded paths
    if grep -q "/home/mike" "$script"; then
        print_warning "Found hardcoded path '/home/mike' in $script"
        ((issues++))
    fi
    
    # Check for missing error handling
    if grep -q "curl.*-o" "$script" && ! grep -q "|| {" "$script"; then
        print_warning "Found curl commands without error handling in $script"
        ((issues++))
    fi
    
    # Check for sudo without error handling
    if grep -q "sudo " "$script" && ! grep -q "|| {" "$script"; then
        print_warning "Found sudo commands without error handling in $script"
        ((issues++))
    fi
    
    # Check for proper function definitions
    if grep -q "function " "$script"; then
        print_success "Found function definitions in $script"
    fi
    
    # Check for colored output functions
    if grep -q "print_status\|print_error\|print_success" "$script"; then
        print_success "Found colored output functions in $script"
    else
        print_warning "No colored output functions found in $script"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        print_success "No common issues found in $script"
        return 0
    else
        print_warning "Found $issues potential issues in $script"
        return 1
    fi
}

# Function to check file structure
check_file_structure() {
    local script="$1"
    print_status "Checking file structure for $script..."
    
    local issues=0
    
    # Check if file exists
    if [[ ! -f "$script" ]]; then
        print_error "File $script does not exist"
        return 1
    fi
    
    # Check if file is executable
    if [[ ! -x "$script" ]]; then
        print_warning "File $script is not executable"
        ((issues++))
    fi
    
    # Check file size
    local size=$(stat -c%s "$script" 2>/dev/null || echo "0")
    if [[ $size -lt 100 ]]; then
        print_warning "File $script is very small ($size bytes)"
        ((issues++))
    fi
    
    # Check for shebang
    if ! head -1 "$script" | grep -q "^#!/bin/bash"; then
        print_warning "File $script may not have proper shebang"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        print_success "File structure is good for $script"
        return 0
    else
        print_warning "Found $issues file structure issues in $script"
        return 1
    fi
}

# Function to check dependencies
check_dependencies() {
    local script="$1"
    print_status "Checking dependencies for $script..."
    
    local dependencies=(
        "curl" "git" "dnf" "rpm" "cargo" "flatpak" "sudo"
    )
    
    local missing=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_warning "Dependency $dep not found in PATH"
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_success "All dependencies are available"
        return 0
    else
        print_warning "Missing dependencies: ${missing[*]}"
        return 1
    fi
}

# Function to check for required files
check_required_files() {
    print_status "Checking for required files..."
    
    local required_files=(
        "install_test_1.sh"
        "packages.txt"
    )
    
    local missing=()
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            print_success "Found required file: $file"
        else
            print_error "Missing required file: $file"
            missing+=("$file")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_success "All required files are present"
        return 0
    else
        print_error "Missing required files: ${missing[*]}"
        return 1
    fi
}

# Function to analyze install script sections
analyze_script_sections() {
    local script="$1"
    print_status "Analyzing script sections for $script..."
    
    local sections=(
        "native packages"
        "cargo applications"
        "git repositories"
        "flatpak applications"
        "RPM packages"
        "dotfiles"
    )
    
    for section in "${sections[@]}"; do
        if grep -qi "$section" "$script"; then
            print_success "Found section: $section"
        else
            print_warning "Section not found: $section"
        fi
    done
}

# Main validation function
validate_install_script() {
    local script="install_test_1.sh"
    
    print_status "Starting validation of install script..."
    echo
    
    # Check file structure
    check_file_structure "$script"
    echo
    
    # Check syntax
    check_syntax "$script"
    echo
    
    # Check for common issues
    check_common_issues "$script"
    echo
    
    # Check dependencies
    check_dependencies "$script"
    echo
    
    # Check required files
    check_required_files
    echo
    
    # Analyze script sections
    analyze_script_sections "$script"
    echo
    
    print_success "Validation completed!"
    print_status "Review the output above for any issues that need to be addressed."
}

# Run validation
validate_install_script 