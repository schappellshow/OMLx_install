#!/bin/bash

# OpenMandriva LX ROME Installation Script
# This is the main installation script for OpenMandriva LX ROME. This should also work for ROCK 6.0.
# Created by: Mike Schappell
# Created: July 2025 | Edited: Aug 2025
# Version 2.0 - Production Ready
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

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# Function to refresh sudo timeout
refresh_sudo() {
    if ! sudo -n true 2>/dev/null; then
        print_status "Refreshing sudo timeout..."
        sudo -v || {
            print_error "Failed to refresh sudo timeout"
            print_warning "You may be prompted for password again"
        }
    fi
}

# Variables
config="$HOME/.config"
dotfiles="https://github.com/schappellshow/stow.git"
packages="./packages.txt"
flatpaks="./flatpak.txt"
stow_dir="$HOME/stow"
script_dir="$(pwd)"

print_status "Starting OpenMandriva LX ROME installation script..."
print_status "This script will install packages, applications, and configure your system"
print_status "💡 TIP: You only need to enter your password once at the beginning!"
print_status "The script will cache your sudo password for the entire installation session"
print_status ""

# Cache sudo password for the session to avoid repeated prompts
print_status "Caching sudo password for this session..."
print_status "You will only need to enter your password once"
if sudo -v; then
    print_success "Sudo password cached successfully"
    print_status "All subsequent sudo commands will run without password prompts"
else
    print_error "Failed to cache sudo password"
    print_warning "You may be prompted for password multiple times during installation"
fi
print_status ""

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
