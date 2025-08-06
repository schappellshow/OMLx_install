#!/bin/bash

# Espanso AppImage Installation Script
# This script installs espanso using the AppImage instead of building from source

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

# Function to download and install espanso AppImage
install_espanso_appimage() {
    print_status "Installing espanso using AppImage..."
    
    # Create the $HOME/opt destination folder (official method)
    local espanso_dir="$HOME/opt"
    mkdir -p "$espanso_dir"
    
    # Download the AppImage inside it (official URL)
    local appimage_url="https://github.com/espanso/espanso/releases/download/v2.2.1/Espanso-X11.AppImage"
    local appimage_path="$espanso_dir/Espanso.AppImage"
    
    print_status "Downloading espanso AppImage..."
    if wget -O "$appimage_path" "$appimage_url"; then
        print_success "Espanso AppImage downloaded successfully"
        
        # Make it executable (official method)
        chmod u+x "$appimage_path"
        
        # Create the "espanso" command alias (official method)
        print_status "Registering espanso command alias..."
        if sudo "$appimage_path" env-path register; then
            print_success "Espanso command alias registered successfully"
        else
            print_warning "Failed to register espanso command alias, but continuing..."
        fi
        
        print_success "Espanso AppImage installed successfully"
        return 0
    else
        print_error "Failed to download espanso AppImage"
        return 1
    fi
}

# Function to register espanso service
register_espanso_service() {
    print_status "Registering espanso service..."
    
    # Check if espanso is available (after env-path register)
    if command -v espanso >/dev/null 2>&1; then
        # Register espanso as a systemd service (official method)
        if espanso service register; then
            print_success "Espanso service registered successfully"
            
            # Start espanso (official method)
            print_status "Starting espanso..."
            if espanso start; then
                print_success "Espanso started successfully"
                return 0
            else
                print_warning "Failed to start espanso, you may need to start it manually later"
                return 1
            fi
        else
            print_error "Failed to register espanso service"
            return 1
        fi
    else
        print_error "Espanso not found in PATH. The env-path register may have failed."
        print_warning "You may need to manually run: sudo ~/opt/Espanso.AppImage env-path register"
        return 1
    fi
}

# Function to test espanso installation
test_espanso_installation() {
    print_status "Testing espanso installation..."
    
    if command -v espanso >/dev/null 2>&1; then
        local version=$(espanso --version 2>/dev/null || echo "unknown")
        print_success "Espanso is available: $version"
        
        # Test service status
        if espanso service status >/dev/null 2>&1; then
            print_success "Espanso service is working"
        else
            print_warning "Espanso service may not be properly configured"
        fi
        
        return 0
    else
        print_error "Espanso is not available in PATH"
        return 1
    fi
}

# Function to show usage information
show_usage() {
    print_status "Espanso AppImage Installation"
    echo
    echo "This script installs espanso using the official AppImage instead of"
    echo "building from source. This avoids compilation issues and dependencies."
    echo
    echo "Benefits of AppImage installation:"
    echo "  • No compilation required"
    echo "  • No dependency issues"
    echo "  • Faster installation"
    echo "  • Self-contained"
    echo
    echo "The AppImage will be installed to: ~/opt/Espanso.AppImage"
    echo "The espanso command will be available system-wide"
    echo
}

# Main execution
main() {
    print_status "Starting espanso AppImage installation..."
    echo
    
    show_usage
    
    # Ask user if they want to proceed
    read -p "Do you want to install espanso using AppImage? (y/N): " -r install_appimage
    
    if [[ $install_appimage =~ ^[Yy]$ ]]; then
        # Install espanso AppImage
        if install_espanso_appimage; then
            # Register and start service
            register_espanso_service
            
            # Test installation
            test_espanso_installation
            
            print_success "Espanso AppImage installation completed!"
            print_status "You can now use espanso from anywhere in your terminal"
        else
            print_error "Espanso AppImage installation failed"
            return 1
        fi
    else
        print_warning "Skipping espanso AppImage installation"
    fi
}

# Check if script is being sourced or run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 