#!/bin/bash

# This is an install script for OpenMandriva LX ROME. This should also work for ROCK 6.0.
# Created by: Mike Schappell
# Created: July 2025
# Version 1.1
#
# Exit on any error
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

# Variables
config="$HOME/.config"
dotfiles="https://github.com/schappellshow/stow.git"
packages="./packages.txt"
flatpaks="./flatpak.txt"  # Fixed filename to match your actual file
stow_dir="$HOME/stow"

print_status "Starting OpenMandriva installation script..."

# Check if required files exist
print_status "Checking for required files..."
if [[ ! -f "$packages" ]]; then
    print_error "Package list file '$packages' not found!"
    exit 1
fi

if [[ ! -f "$flatpaks" ]]; then
    print_error "Flatpak list file '$flatpaks' not found!"
    exit 1
fi

print_success "All required files found."

# Clean package cache (both sudo and user as recommended for OM)
print_status "Cleaning package cache..."
sudo dnf clean all
dnf clean all
print_success "Package cache cleaned."

# Update System first on clean install
print_status "Updating system packages..."
sudo dnf distro-sync --allowerasing --refresh -y || {
    print_error "System update failed"
    exit 1
}

print_success "System updated successfully."

# Install essential dependencies after system update
print_status "Installing essential dependencies..."
sudo dnf install -y git wget curl || {
    print_error "Failed to install essential dependencies"
    exit 1
}

print_success "Essential dependencies installed."

# Install native packages via dnf
print_status "Installing native packages from $packages..."
if [[ -s "$packages" ]]; then
    # Read packages line by line to handle any formatting issues
    while IFS= read -r package || [[ -n "$package" ]]; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
        # Extract just the package name (before any version info)
        package_name=$(echo "$package" | awk '{print $1}' | cut -d'-' -f1-2)
        print_status "Installing: $package_name"
    done < "$packages"
    
    # Install all packages at once
    sudo dnf install -y $(grep -v '^[[:space:]]*#' "$packages" | grep -v '^[[:space:]]*$' | awk '{print $1}' | cut -d'-' -f1-2) || {
        print_error "Some native packages failed to install. Continuing anyway..."
    }
else
    print_error "Package list file is empty"
    exit 1
fi

print_success "Native packages installation completed."

# Install Flatpaks
print_status "Installing Flatpak applications from $flatpaks..."
if [[ -s "$flatpaks" ]]; then
    while IFS= read -r flatpak || [[ -n "$flatpak" ]]; do
        # Skip empty lines and comments
        [[ -z "$flatpak" || "$flatpak" =~ ^[[:space:]]*# ]] && continue
        # Extract just the app ID (before any version info)
        app_id=$(echo "$flatpak" | awk '{print $1}')
        print_status "Installing Flatpak: $app_id"
        flatpak install -y --user "$app_id" || {
            print_error "Failed to install $app_id, continuing..."
        }
    done < "$flatpaks"
else
    print_error "Flatpak list file is empty"
    exit 1
fi

print_success "Flatpak applications installation completed."

# Setup Dotfiles
print_status "Setting up dotfiles..."
if [[ -d "$stow_dir" ]]; then
    print_status "Removing existing stow directory..."
    rm -rf "$stow_dir"
fi

print_status "Cloning dotfiles repository..."
git clone "$dotfiles" "$stow_dir" || {
    print_error "Failed to clone dotfiles repository"
    exit 1
}

print_status "Applying dotfiles with stow..."
cd "$stow_dir" || {
    print_error "Failed to change to stow directory"
    exit 1
}

# Create config directory if it doesn't exist
mkdir -p "$config"

# Apply stow configuration
stow . || {
    print_error "Failed to apply dotfiles with stow"
    exit 1
}

print_success "Dotfiles applied successfully."

# Return to original directory
cd - > /dev/null

print_success "\n🎉 Installation script completed successfully!"
print_status "\nNext steps:"
print_status "1. Reboot your system to ensure all changes take effect"
print_status "2. Log out and log back in to apply dotfiles changes"
print_status "3. Check that all applications are working correctly"

print_status "\nInstallation log saved. Check for any warnings above."
