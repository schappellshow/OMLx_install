#!/bin/bash

# OpenMandriva LX ROME - ROOT ONLY Installation Script
# This script installs only system-level packages and applications
# Designed for systems with separate /home and root partitions
# Created by: Mike Schappell
# Created: August 2025
# Version 1.0
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
packages="./packages.txt"
flatpaks="./flatpak.txt"
script_dir="$(pwd)"

print_header() {
    echo -e "\033[1;36m========================================\033[0m"
    echo -e "\033[1;36m$1\033[0m"
    echo -e "\033[1;36m========================================\033[0m"
}

print_status "Starting OpenMandriva ROOT-ONLY installation script..."
print_status "This script will install system packages and applications ONLY"
print_status "Your /home directory and personal data will be preserved"
print_status "💡 TIP: You only need to enter your password once at the beginning!"
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

print_success "Essential dependencies installed."

# Install build tools and core dependencies needed for later installations
print_status "Installing build tools and core dependencies..."
sudo dnf install -y gcc-c++ make cmake pkgconfig || {
    print_error "Failed to install build tools"
    exit 1
}

print_success "Build tools and core dependencies installed."

# Setup Flatpak if it was installed successfully
print_status "Setting up Flatpak..."
if command -v flatpak >/dev/null 2>&1; then
    print_status "Flatpak is already installed"
else
    print_status "Installing Flatpak..."
    sudo dnf install -y flatpak || {
        print_error "Failed to install Flatpak"
        exit 1
    }
fi

# Refresh sudo timeout before package installation
refresh_sudo

# Install native packages
print_header "NATIVE PACKAGES INSTALLATION"
print_status "Installing packages from packages.txt..."

# Read packages file and install each package
while IFS= read -r package; do
    # Skip empty lines and comments
    [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
    
    print_status "Installing: $package"
    if sudo dnf install -y "$package"; then
        print_success "✓ $package installed successfully"
    else
        print_error "✗ Failed to install $package"
        print_warning "Continuing with remaining packages..."
    fi
done < "$packages"

print_success "Native packages installation completed"

# Refresh sudo timeout before flatpak installation
refresh_sudo

# Install Flatpaks
print_header "FLATPAK APPLICATIONS INSTALLATION"
print_status "Installing Flatpak applications..."

# Add Flathub repository if not already added
if ! flatpak remote-list | grep -q "flathub"; then
    print_status "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || {
        print_error "Failed to add Flathub repository"
        print_warning "Continuing with system flatpaks only..."
    }
fi

# Read flatpak file and install each application
while IFS= read -r flatpak; do
    # Skip empty lines and comments
    [[ -z "$flatpak" || "$flatpak" =~ ^[[:space:]]*# ]] && continue
    
    print_status "Installing Flatpak: $flatpak"
    if flatpak install -y flathub "$flatpak"; then
        print_success "✓ $flatpak installed successfully"
    else
        print_error "✗ Failed to install $flatpak"
        print_warning "Continuing with remaining flatpaks..."
    fi
done < "$flatpaks"

print_success "Flatpak applications installation completed"

# Install Python applications via pip (system-wide)
print_header "PYTHON APPLICATIONS INSTALLATION"
print_status "Installing Python applications..."

# Install pipx for Python package management (recommended for CLI tools)
print_status "Installing pipx for Python package management..."
python3 -m pip install --user pipx || {
    print_warning "Failed to install pipx, will use pip directly for trash-cli"
}

# Ensure pipx is in PATH
if command -v pipx >/dev/null 2>&1; then
    print_success "pipx installed successfully"
    # Add pipx to PATH if not already there
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        export PATH="$HOME/.local/bin:$PATH"
        print_status "Added pipx to PATH"
    fi
else
    print_warning "pipx not available, will use pip directly"
fi

# Install trash-cli for safe file deletion
print_status "Installing trash-cli..."
print_status "This provides safe file deletion by moving files to trash instead of permanent deletion"

# Try pipx first (recommended method)
if command -v pipx >/dev/null 2>&1; then
    print_status "Using pipx to install trash-cli..."
    pipx install trash-cli || {
        print_warning "pipx installation failed, trying pip..."
        python3 -m pip install --user trash-cli || {
            print_error "Failed to install trash-cli, continuing..."
        }
    }
else
    print_status "pipx not available, using pip to install trash-cli..."
    python3 -m pip install --user trash-cli || {
        print_error "Failed to install trash-cli, continuing..."
    }
fi

if command -v trash >/dev/null 2>&1; then
    print_success "trash-cli installed successfully"
    print_status "You can now use 'trash' command to safely delete files"
    print_status "Tip: Add 'alias rm=\"trash\"' to your .zshrc to make 'rm' use trash by default"
else
    print_warning "trash-cli installation may have failed"
fi

# Install zoxide (smart cd replacement)
print_status "Installing zoxide (smart cd replacement)..."
if curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; then
    print_success "Zoxide installed successfully"
    print_status "You can now use 'z' instead of 'cd' for smart directory navigation"
else
    print_warning "Failed to install zoxide, continuing..."
fi

# Refresh sudo timeout before RPM installation
refresh_sudo

# Install individual RPM packages (Warp, Mailspring, PDF Studio Viewer)
print_header "INDIVIDUAL RPM PACKAGES INSTALLATION"
print_status "Installing individual RPM packages..."

# Install Warp terminal
print_status "Installing Warp terminal..."
WARP_VERSION="0.2024.08.15.08.01.p"
WARP_ARCHIVE="warp-${WARP_VERSION}-x86_64.rpm"
WARP_URL="https://releases.warp.dev/stable/v${WARP_VERSION}/${WARP_ARCHIVE}"

if curl -L -o "$WARP_ARCHIVE" "$WARP_URL"; then
    print_status "Warp downloaded successfully"
    if sudo dnf install -y "$WARP_ARCHIVE"; then
        print_success "Warp terminal installed successfully"
        print_status "You can now launch Warp from your applications menu"
    else
        print_error "Failed to install Warp terminal"
    fi
    # Clean up downloaded file
    rm -f "$WARP_ARCHIVE"
else
    print_error "Failed to download Warp terminal"
fi

# Install Mailspring
print_status "Installing Mailspring..."
MAILSPRING_FILE="/tmp/mailspring.rpm"

print_status "Downloading Mailspring RPM..."
if curl -L "https://updates.getmailspring.com/download?platform=linuxRpm" -o "$MAILSPRING_FILE"; then
    print_status "Installing Mailspring dependencies..."
    sudo dnf install -y lib64appindicator lib64gtk3_0 || {
        print_warning "Some Mailspring dependencies failed to install, continuing with --nodeps"
    }

    if sudo dnf install -y "$MAILSPRING_FILE"; then
        print_success "Mailspring installed successfully with DNF"
    elif sudo rpm -ivh --nodeps "$MAILSPRING_FILE"; then
        print_success "Mailspring installed with RPM (--nodeps)"
        print_warning "Mailspring installed without dependency checking - ensure libappindicator and gtk3 are installed"
    else
        print_error "Failed to install Mailspring with both DNF and RPM methods"
        print_warning "Continuing with remaining installations..."
    fi

    rm -f "$MAILSPRING_FILE"
else
    print_error "Failed to download Mailspring"
    print_warning "Continuing with remaining installations..."
fi

# Install PDF Studio Viewer (shell script installer)
print_status "Installing PDF Studio Viewer..."
PDF_STUDIO_URL="https://download.qoppa.com/pdfstudioviewer/PDFStudioViewer_linux.sh"

if curl -L -o "PDFStudioViewer_linux.sh" "$PDF_STUDIO_URL"; then
    print_status "PDF Studio Viewer downloaded successfully"
    chmod +x "PDFStudioViewer_linux.sh"
    
    print_status "Running PDF Studio Viewer installer..."
    print_status "This installer will guide you through the installation process"
    print_status "Please follow the on-screen instructions"
    
    if ./PDFStudioViewer_linux.sh; then
        print_success "PDF Studio Viewer installed successfully"
    else
        print_warning "PDF Studio Viewer installation may have failed or was cancelled"
    fi
    
    # Clean up downloaded file
    rm -f "PDFStudioViewer_linux.sh"
else
    print_error "Failed to download PDF Studio Viewer"
fi

# Install Git-based projects
print_header "GIT-BASED PROJECTS INSTALLATION"
print_status "Installing Git-based projects..."

# Install conky-manager2
print_status "Installing conky-manager2..."
if git clone https://github.com/Conky-Conky/conky-manager2.git; then
    print_status "Conky-manager2 cloned successfully"
    cd conky-manager2 || {
        print_error "Failed to change to conky-manager2 directory"
        cd "$script_dir"
    }
    
    if make; then
        print_status "Conky-manager2 built successfully"
        if sudo make install; then
            print_success "Conky-manager2 installed successfully"
        else
            print_error "Failed to install conky-manager2"
        fi
    else
        print_error "Failed to build conky-manager2"
    fi
    
    # Return to original directory
    cd "$script_dir"
else
    print_error "Failed to clone conky-manager2"
fi

# Install espanso using AppImage
print_status "Installing espanso using AppImage..."

# Create the $HOME/opt destination folder (official method)
ESPANSO_DIR="$HOME/opt"
mkdir -p "$ESPANSO_DIR"

# Download the AppImage inside it (official URL)
ESPANSO_URL="https://github.com/espanso/espanso/releases/download/v2.2.1/Espanso-X11.AppImage"
ESPANSO_FILE="$ESPANSO_DIR/Espanso.AppImage"

print_status "Downloading espanso AppImage..."
if curl -L "$ESPANSO_URL" -o "$ESPANSO_FILE"; then
    print_success "Espanso AppImage downloaded successfully"

    # Make it executable (official method)
    chmod u+x "$ESPANSO_FILE"

    # Create the "espanso" command alias (official method)
    print_status "Registering espanso command alias..."
    if sudo "$ESPANSO_FILE" env-path register; then
        print_success "Espanso command alias registered successfully"

        # Register espanso as a systemd service (official method)
        print_status "Registering espanso service..."
        if espanso service register; then
            print_success "Espanso service registered successfully"

            # Start espanso (official method)
            print_status "Starting espanso..."
            if espanso start; then
                print_success "Espanso started successfully"
            else
                print_warning "Failed to start espanso, you may need to start it manually later"
            fi
        else
            print_warning "Failed to register espanso service, continuing..."
        fi
    else
        print_warning "Failed to register espanso command alias, but continuing..."
    fi

    print_success "Espanso AppImage installation completed"
    print_status "Espanso is available at: $ESPANSO_FILE"
else
    print_error "Failed to download espanso AppImage"
    print_warning "Continuing with remaining installations..."
fi

# Install Zed editor
print_status "Installing Zed editor..."
if curl -f https://zed.dev/install.sh | sh; then
    print_success "Zed editor installed successfully"
    print_status "Zed is available at: ~/.local/bin/zed"
else
    print_error "Failed to install Zed editor"
    print_warning "Continuing with remaining installations..."
fi

# Install kwin-effects-glass plugin (blur with force blur, rounded corners, refraction)
# Glass is a fork of kwin-forceblur for Plasma 6.5+
# Pinned to v6.6.1-2 — the last version supporting Plasma 6.5 (X11)
# Project: https://github.com/4v3ngR/kwin-effects-glass
print_status "Installing kwin-effects-glass plugin..."

# Install build dependencies for glass
print_status "Installing kwin-effects-glass build dependencies..."
sudo dnf install -y extra-cmake-modules \
  kwin-devel kwin-x11-devel lib64kdecorations3-devel \
  lib64KF6ConfigCore-devel lib64KF6ConfigWidgets-devel lib64KF6Crash-devel \
  lib64KF6GlobalAccel-devel lib64KF6GuiAddons-devel lib64KF6I18n-devel \
  lib64KF6KCMUtils-devel lib64KF6KIO-devel lib64KF6Notifications-devel \
  lib64KF6Service-devel lib64KF6WidgetsAddons-devel lib64KF6WindowSystem-devel \
  lib64Qt6Core-devel lib64Qt6DBus-devel lib64Qt6Gui-devel lib64Qt6Network-devel \
  lib64Qt6OpenGL-devel lib64Qt6UiTools-devel lib64Qt6Widgets-devel lib64Qt6Xml-devel \
  lib64epoxy-devel lib64xcb-devel || {
    print_warning "Some build dependencies failed to install, glass plugin may not build"
}

GLASS_VERSION="6.6.1-2"
GLASS_URL="https://github.com/4v3ngR/kwin-effects-glass/archive/refs/tags/v${GLASS_VERSION}.tar.gz"
GLASS_ARCHIVE="/tmp/kwin-effects-glass-v${GLASS_VERSION}.tar.gz"

# Download and extract kwin-effects-glass
print_status "Downloading kwin-effects-glass v${GLASS_VERSION}..."
if curl -L "$GLASS_URL" -o "$GLASS_ARCHIVE"; then
    print_status "Extracting kwin-effects-glass..."
    cd /tmp || {
        print_error "Failed to change to /tmp directory"
    }

    if tar -xzf "$GLASS_ARCHIVE"; then
        # Find the extracted directory
        extracted_dir=$(find /tmp -maxdepth 1 -name "kwin-effects-glass-*" -type d | head -1)

        if [[ -n "$extracted_dir" && -d "$extracted_dir" ]]; then
            print_status "Building kwin-effects-glass..."
            cd "$extracted_dir" || {
                print_error "Failed to change to kwin-effects-glass directory"
            }

            # Create build directory and build
            mkdir -p build
            cd build || {
                print_error "Failed to change to build directory"
            }

            # On OpenMandriva, KDE ECM installs to /usr/lib64/plugins/ but KWin
            # loads effects from /usr/lib64/qt6/plugins/. Override KDE_INSTALL_PLUGINDIR
            # so the plugin installs directly to the correct Qt6 path.
            if cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DKDE_INSTALL_PLUGINDIR=/usr/lib64/qt6/plugins; then
                if make -j$(nproc); then
                    if sudo make install; then
                        # Verify installation
                        print_status "Verifying kwin-effects-glass installation..."

                        if [[ -f "/usr/lib64/qt6/plugins/kwin-x11/effects/plugins/glass_x11.so" ]]; then
                            print_success "Glass plugin binary (X11) installed successfully"
                        else
                            print_warning "Glass X11 plugin binary not found in expected location"
                        fi

                        if [[ -f "/usr/lib64/qt6/plugins/kwin-x11/effects/configs/kwin_glass_config.so" ]]; then
                            print_success "Glass configuration module installed successfully"
                        else
                            print_warning "Glass configuration module not found in expected location"
                        fi

                        print_success "Kwin-effects-glass plugin installation completed"
                        print_status "Note: Disable any existing blur effects before enabling Glass (they conflict)"
                        print_status "Note: You may need to restart KWin or reboot to see the plugin in System Settings"
                    else
                        print_error "Failed to install kwin-effects-glass, continuing..."
                    fi
                else
                    print_error "Failed to build kwin-effects-glass, continuing..."
                fi
            else
                print_error "Failed to configure kwin-effects-glass with cmake, continuing..."
            fi

            # Return to original directory
            cd "$script_dir"
        else
            print_error "Failed to find extracted kwin-effects-glass directory, skipping installation"
        fi
    else
        print_error "Failed to extract kwin-effects-glass, skipping installation"
    fi

    # Clean up downloaded file
    rm -f "$GLASS_ARCHIVE"
else
    print_error "Failed to download kwin-effects-glass, skipping installation"
fi

print_success "Git-based projects installation completed"

# Install Oh My Zsh (system-wide)
print_header "OH MY ZSH INSTALLATION"
print_status "Installing Oh My Zsh..."

# Check if zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
    print_status "Installing zsh..."
    sudo dnf install -y zsh || {
        print_error "Failed to install zsh, skipping Oh My Zsh installation"
    }
fi

# Install Oh My Zsh if zsh is available
if command -v zsh >/dev/null 2>&1; then
    print_status "Installing Oh My Zsh..."
    
    # Install Oh My Zsh
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        print_success "Oh My Zsh installed successfully"
        
        # Set zsh as default shell if not already set
        if [[ "$SHELL" != "/bin/zsh" ]]; then
            print_status "Setting zsh as default shell..."
            
            # Check if zsh is in /etc/shells and add it if needed
            print_status "Checking zsh in /etc/shells..."
            if ! grep -q "/usr/bin/zsh" /etc/shells 2>/dev/null && ! grep -q "/bin/zsh" /etc/shells 2>/dev/null; then
                print_status "Adding zsh to /etc/shells..."
                echo "/usr/bin/zsh" | sudo tee -a /etc/shells > /dev/null
            else
                print_success "Zsh is already in /etc/shells"
            fi
            
            # Get the actual zsh path
            ZSH_PATH=$(which zsh)
            if [[ -n "$ZSH_PATH" ]]; then
                print_status "Using zsh at: $ZSH_PATH"
                if chsh -s "$ZSH_PATH"; then
                    print_success "Zsh set as default shell"
                    print_warning "You may need to log out and log back in for the change to take effect"
                else
                    print_warning "Failed to set zsh as default shell, you can do this manually later"
                fi
            else
                print_warning "Could not find zsh path, skipping default shell change"
            fi
        else
            print_success "Zsh is already the default shell"
        fi
    else
        print_error "Failed to install Oh My Zsh, continuing..."
    fi
else
    print_error "Zsh is not available, skipping Oh My Zsh installation"
fi

# Install Cargo applications (optional)
print_header "CARGO APPLICATIONS INSTALLATION"
print_status "Cargo applications can take a while to compile. Would you like to install them now?"
print_status "Available applications:"
echo "  • cargo-make    - Task runner and build tool"
echo "  • cargo-update  - Update installed binaries"
echo "  • fd-find       - Fast file finder"
echo "  • resvg         - SVG renderer"
echo "  • ripgrep       - Fast text search"
echo "  • rust-script   - Rust scripting tool"
echo "  • yazi-fm       - Terminal file manager"
echo "  • yazi-cli      - Yazi command line interface"
echo

read -p "Would you like to install cargo applications now? (y/N): " -r install_cargo

if [[ $install_cargo =~ ^[Yy]$ ]]; then
    print_status "Installing cargo applications..."
    
    # Check if cargo is available
    if ! command -v cargo >/dev/null 2>&1; then
        print_error "Cargo is not installed. Please install Rust and Cargo first."
        print_status "You can install Rust by running: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        print_warning "Skipping cargo applications installation"
    else
        # Run the cargo installation script
        if [[ -f "./install_cargo_apps.sh" ]]; then
            print_status "Running cargo installation script..."
            bash ./install_cargo_apps.sh
        else
            print_error "Cargo installation script not found: install_cargo_apps.sh"
            print_warning "You can run the cargo installation later with: bash install_cargo_apps.sh"
        fi
    fi
else
    print_warning "Skipping cargo applications installation"
    print_status "You can install cargo applications later by running: bash install_cargo_apps.sh"
fi

print_success "\n🎉 ROOT-ONLY Installation script completed successfully!"
print_status "\n📋 What was installed:"
print_status "✅ System packages from packages.txt"
print_status "✅ Flatpak applications from flatpak.txt"
print_status "✅ Python applications (pipx, trash-cli)"
print_status "✅ Zsh and Oh My Zsh"
print_status "✅ Individual applications (Warp, Mailspring, PDF Studio Viewer, Zed)"
print_status "✅ Development tools and build dependencies"
print_status "✅ KDE plugins and enhancements"
print_status "✅ Cargo applications (if selected)"
print_status ""
print_status "📁 What was NOT installed (preserved in /home):"
print_status "❌ Your personal dotfiles and configurations"
print_status "❌ User-specific application settings"
print_status "❌ Personal data and documents"
print_status "❌ User-installed applications in /home"
print_status ""
print_status "🔄 Next steps:"
print_status "1. Reboot your system to ensure all changes take effect"
print_status "2. Your /home directory is preserved and ready to use"
print_status "3. You can now run the full installation script to restore your dotfiles:"
print_status "   bash OMLx_install.sh"
print_status "4. Or manually restore your configurations as needed"
print_status ""
print_status "💡 Tip: This approach saves time on future reinstalls!"
print_status "   - Run this script for system packages"
print_status "   - Run the full script only when you want to restore dotfiles"

print_status "\nInstallation log saved. Check for any warnings above."
