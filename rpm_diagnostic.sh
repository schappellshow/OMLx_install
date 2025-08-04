#!/bin/bash

# RPM Installation Diagnostic Script
# This script tests each RPM installation to identify specific issues

set -e

# Function to print colored output
print_status() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# Function to test RPM download and installation
test_rpm_installation() {
    local name="$1"
    local url="$2"
    local file="$3"
    local dependencies="$4"
    
    print_status "=== Testing $name installation ==="
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed"
        return 1
    fi
    
    # Test URL accessibility
    print_status "Testing URL accessibility..."
    if curl -I "$url" &> /dev/null; then
        print_success "URL is accessible"
    else
        print_error "URL is not accessible: $url"
        return 1
    fi
    
    # Download RPM
    print_status "Downloading $name..."
    if curl -L "$url" -o "$file"; then
        print_success "Download successful"
        
        # Check file size
        local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        if [[ $size -lt 1000 ]]; then
            print_error "Downloaded file is too small ($size bytes), likely an error page"
            return 1
        fi
        
        # Check if it's a valid RPM
        print_status "Validating RPM file..."
        if file "$file" | grep -q "RPM"; then
            print_success "Valid RPM file"
        else
            print_warning "File doesn't appear to be a valid RPM"
        fi
        
        # Check dependencies
        if [[ -n "$dependencies" ]]; then
            print_status "Checking dependencies: $dependencies"
            for dep in $dependencies; do
                if dnf list installed "$dep" &> /dev/null; then
                    print_success "Dependency $dep is installed"
                else
                    print_warning "Dependency $dep is not installed"
                fi
            done
        fi
        
        # Test installation
        print_status "Testing installation..."
        if sudo dnf install -y "$file" 2>&1 | tee /tmp/install_test.log; then
            print_success "Installation successful"
        else
            print_error "Installation failed. Check /tmp/install_test.log for details"
            return 1
        fi
        
        # Clean up
        rm -f "$file"
        
    else
        print_error "Download failed"
        return 1
    fi
    
    print_success "=== $name test completed ==="
    echo
}

# Test each RPM installation
print_status "Starting RPM installation diagnostics..."

# Test Warp terminal
test_rpm_installation \
    "Warp Terminal" \
    "https://releases.warp.dev/linux/v0.2024.10.29.08.02.stable_02/warp-terminal-v0.2024.10.29.08.02.stable_02-1-x86_64.rpm" \
    "/tmp/warp-terminal-test.rpm" \
    ""

# Test Mailspring
test_rpm_installation \
    "Mailspring" \
    "https://updates.getmailspring.com/download?platform=linuxRpm" \
    "/tmp/mailspring-test.rpm" \
    "libappindicator gtk3"

# Test Proton Pass
test_rpm_installation \
    "Proton Pass" \
    "https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm" \
    "/tmp/proton-pass-test.rpm" \
    "libXtst gtk3 libdrm mesa-libgbm at-spi2-core"

# Test PDF Studio Viewer (this is actually a shell script, not RPM)
print_status "=== Testing PDF Studio Viewer installation ==="
PDF_STUDIO_URL="https://download.qoppa.com/pdfstudioviewer/PDFStudioViewer_linux64.sh"
PDF_STUDIO_FILE="/tmp/PDFStudioViewer_linux64_test.sh"

print_status "Testing URL accessibility..."
if curl -I "$PDF_STUDIO_URL" &> /dev/null; then
    print_success "URL is accessible"
    
    print_status "Downloading PDF Studio Viewer..."
    if curl -L "$PDF_STUDIO_URL" -o "$PDF_STUDIO_FILE"; then
        print_success "Download successful"
        
        # Check file size
        local size=$(stat -c%s "$PDF_STUDIO_FILE" 2>/dev/null || echo "0")
        if [[ $size -lt 1000 ]]; then
            print_error "Downloaded file is too small ($size bytes), likely an error page"
        else
            print_success "Valid installer file"
            chmod +x "$PDF_STUDIO_FILE"
            print_success "Made installer executable"
        fi
        
        # Clean up
        rm -f "$PDF_STUDIO_FILE"
    else
        print_error "Download failed"
    fi
else
    print_error "URL is not accessible: $PDF_STUDIO_URL"
fi

print_success "=== PDF Studio Viewer test completed ==="
echo

print_success "RPM diagnostic tests completed!"
print_status "Check the output above for specific issues with each installation." 