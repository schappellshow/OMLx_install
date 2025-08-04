#!/bin/bash

# Proton Pass Dependency Checker
# This script checks what dependencies Proton Pass needs and if they're available

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

# Download and analyze Proton Pass RPM
print_status "Downloading Proton Pass RPM for analysis..."
PROTON_PASS_FILE="/tmp/proton-pass-analysis.rpm"

if curl -L "https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm" -o "$PROTON_PASS_FILE"; then
    print_success "Downloaded Proton Pass RPM"
    
    # Check file size
    local size=$(stat -c%s "$PROTON_PASS_FILE" 2>/dev/null || echo "0")
    if [[ $size -gt 1000000 ]]; then
        print_success "RPM file size: $size bytes"
        
        # Extract RPM information
        print_status "Analyzing RPM dependencies..."
        
        # Get package name
        local pkg_name=$(rpm -qp --queryformat '%{NAME}' "$PROTON_PASS_FILE" 2>/dev/null || echo "unknown")
        print_status "Package name: $pkg_name"
        
        # Get dependencies
        print_status "Checking dependencies..."
        rpm -qpR "$PROTON_PASS_FILE" 2>/dev/null | while IFS= read -r dep; do
            if [[ "$dep" =~ ^[[:space:]]*$ ]]; then
                continue
            fi
            
            # Clean up dependency string
            dep=$(echo "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Skip provides and conflicts
            if [[ "$dep" =~ ^Provides: ]] || [[ "$dep" =~ ^Conflicts: ]]; then
                continue
            fi
            
            # Extract package name from dependency
            local dep_pkg=$(echo "$dep" | sed 's/^\([^<>=]*\).*/\1/')
            dep_pkg=$(echo "$dep_pkg" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [[ -n "$dep_pkg" ]]; then
                print_status "Checking dependency: $dep_pkg"
                
                # Check if package is available
                if dnf search "$dep_pkg" 2>/dev/null | grep -q "$dep_pkg"; then
                    print_success "✓ Available: $dep_pkg"
                else
                    print_warning "✗ Not found: $dep_pkg"
                fi
            fi
        done
        
        # Test installation with detailed output
        print_status "Testing installation with detailed dependency check..."
        if sudo dnf install --assumeno "$PROTON_PASS_FILE" 2>&1 | tee /tmp/proton_install_test.log; then
            print_success "Proton Pass would install successfully"
        else
            print_error "Proton Pass has dependency issues"
            print_status "Check /tmp/proton_install_test.log for details"
        fi
        
    else
        print_error "Downloaded file is too small ($size bytes)"
    fi
    
    # Clean up
    rm -f "$PROTON_PASS_FILE"
else
    print_error "Failed to download Proton Pass RPM"
fi 