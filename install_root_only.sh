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
MAILSPRING_VERSION="1.13.0"
MAILSPRING_ARCHIVE="mailspring-${MAILSPRING_VERSION}-linux-x64.deb"
MAILSPRING_URL="https://github.com/Foundry376/Mailspring/releases/download/${MAILSPRING_VERSION}/${MAILSPRING_ARCHIVE}"

if curl -L -o "$MAILSPRING_ARCHIVE" "$MAILSPRING_URL"; then
    print_status "Mailspring downloaded successfully"
    # Convert deb to rpm or install directly if possible
    if command -v alien >/dev/null 2>&1; then
        print_status "Converting deb to rpm using alien..."
        if alien -r "$MAILSPRING_ARCHIVE"; then
            local rpm_file=$(ls mailspring-*.rpm 2>/dev/null | head -1)
            if [[ -n "$rpm_file" ]]; then
                if sudo dnf install -y "$rpm_file"; then
                    print_success "Mailspring installed successfully"
                else
                    print_error "Failed to install converted Mailspring rpm"
                fi
                rm -f "$rpm_file"
            else
                print_error "Failed to convert deb to rpm"
            fi
        else
            print_error "Failed to convert deb to rpm using alien"
        fi
    else
        print_status "Installing alien for deb to rpm conversion..."
        if sudo dnf install -y alien; then
            print_status "Converting deb to rpm..."
            if alien -r "$MAILSPRING_ARCHIVE"; then
                local rpm_file=$(ls mailspring-*.rpm 2>/dev/null | head -1)
                if [[ -n "$rpm_file" ]]; then
                    if sudo dnf install -y "$rpm_file"; then
                        print_success "Mailspring installed successfully"
                    else
                        print_error "Failed to install converted Mailspring rpm"
                    fi
                    rm -f "$rpm_file"
                else
                    print_error "Failed to convert deb to rpm"
                fi
            else
                print_error "Failed to convert deb to rpm using alien"
            fi
        else
            print_error "Failed to install alien"
        fi
    fi
    # Clean up downloaded file
    rm -f "$MAILSPRING_ARCHIVE"
else
    print_error "Failed to download Mailspring"
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
ESPANSO_VERSION="2.1.8"
ESPANSO_ARCHIVE="espanso-linux-x86_64.tar.gz"
ESPANSO_URL="https://github.com/federico-terzi/espanso/releases/download/v${ESPANSO_VERSION}/${ESPANSO_ARCHIVE}"

if curl -L -o "$ESPANSO_ARCHIVE" "$ESPANSO_URL"; then
    print_status "Espanso downloaded successfully"
    if tar -xzf "$ESPANSO_ARCHIVE"; then
        print_status "Espanso extracted successfully"
        if sudo mv espanso /usr/local/bin/; then
            print_success "Espanso installed successfully"
            print_status "You can now use 'espanso' command"
        else
            print_error "Failed to move espanso to /usr/local/bin"
        fi
    else
        print_error "Failed to extract espanso"
    fi
    # Clean up downloaded file
    rm -f "$ESPANSO_ARCHIVE"
else
    print_error "Failed to download espanso"
fi

# Install Cursor AppImage
print_status "Installing Cursor AppImage..."
CURSOR_VERSION="0.45.0"
CURSOR_ARCHIVE="Cursor-${CURSOR_VERSION}-x86_64.AppImage"
CURSOR_URL="https://download.cursor.sh/linux/appImage/x64/${CURSOR_ARCHIVE}"

# Create AppImages directory if it doesn't exist
mkdir -p "$HOME/AppImages"

if curl -L -o "$HOME/AppImages/$CURSOR_ARCHIVE" "$CURSOR_URL"; then
    print_status "Cursor AppImage downloaded successfully"
    chmod +x "$HOME/AppImages/$CURSOR_ARCHIVE"
    
    # Create desktop entry
    cat > "$HOME/.local/share/applications/cursor.desktop" << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-first code editor
Exec=$HOME/AppImages/$CURSOR_ARCHIVE
Icon=cursor
Type=Application
Categories=Development;IDE;
StartupNotify=true
EOF
    
    print_success "Cursor AppImage installed successfully"
    print_status "You can now launch Cursor from your applications menu"
else
    print_error "Failed to download Cursor AppImage"
fi

# Install kwin-forceblur plugin
print_status "Installing kwin-forceblur plugin..."
FORCEBLUR_VERSION="1.0.0"
FORCEBLUR_ARCHIVE="kwin-forceblur-${FORCEBLUR_VERSION}.tar.gz"
FORCEBLUR_URL="https://github.com/esjeon/kwin-forceblur/archive/refs/tags/v${FORCEBLUR_VERSION}.tar.gz"

if curl -L -o "$FORCEBLUR_ARCHIVE" "$FORCEBLUR_URL"; then
    print_status "Kwin-forceblur downloaded successfully"
    if tar -xzf "$FORCEBLUR_ARCHIVE"; then
        print_status "Kwin-forceblur extracted successfully"
        cd "kwin-forceblur-${FORCEBLUR_VERSION}" || {
            print_error "Failed to change to kwin-forceblur directory"
            cd "$script_dir"
        }
        
        # Install ECM (Extra CMake Modules) for kwin-forceblur
        print_status "Installing ECM (Extra CMake Modules) for kwin-forceblur..."
        sudo dnf install -y extra-cmake-modules || {
            print_error "Failed to install ECM"
            cd "$script_dir"
        }
        
        if cmake -B build -S .; then
            print_status "Kwin-forceblur configured successfully"
            if cmake --build build; then
                print_status "Kwin-forceblur built successfully"
                
                # Copy plugin files to correct Qt6 locations
                if [[ -f "build/src/forceblur.so" ]]; then
                    print_status "Copying plugin binary to Qt6 directory..."
                    sudo cp build/src/forceblur.so /usr/lib64/qt6/plugins/kwin/effects/plugins/ || {
                        print_error "Failed to copy plugin binary"
                    }
                fi
                
                if [[ -f "build/src/kcm/kwin_better_blur_config.so" ]]; then
                    print_status "Copying configuration module to Qt6 directory..."
                    sudo cp build/src/kcm/kwin_better_blur_config.so /usr/lib64/qt6/plugins/kwin/effects/configs/ || {
                        print_error "Failed to copy configuration module"
                    }
                fi
                
                if [[ -f "src/metadata.json" ]]; then
                    print_status "Copying metadata file..."
                    sudo cp src/metadata.json /usr/share/kwin/effects/forceblur/ || {
                        print_error "Failed to copy metadata file"
                    }
                fi
                
                # Verify installations
                print_status "Verifying kwin-forceblur installation..."
                if [[ -f "/usr/lib64/qt6/plugins/kwin/effects/plugins/forceblur.so" ]]; then
                    print_success "Plugin binary installed successfully"
                else
                    print_error "Plugin binary not found in expected location"
                fi
                
                if [[ -f "/usr/lib64/qt6/plugins/kwin/effects/configs/kwin_better_blur_config.so" ]]; then
                    print_success "Configuration module installed successfully"
                else
                    print_error "Configuration module not found in expected location"
                fi
                
                if [[ -f "/usr/share/kwin/effects/forceblur/metadata.json" ]]; then
                    print_success "Metadata file installed successfully"
                else
                    print_error "Metadata file not found in expected location"
                fi
                
                print_success "Kwin-forceblur plugin installation completed"
                print_status "Note: You may need to restart KWin or reboot to see the plugin in System Settings"
            else
                print_error "Failed to build kwin-forceblur, continuing..."
            fi
        else
            print_error "Failed to configure kwin-forceblur with cmake, continuing..."
        fi
        
        # Return to original directory
        cd "$script_dir"
    else
        print_error "Failed to extract kwin-forceblur, skipping installation"
    fi
    # Clean up downloaded file
    rm -f "$FORCEBLUR_ARCHIVE"
else
    print_error "Failed to download kwin-forceblur, skipping installation"
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
print_status "✅ Individual applications (Warp, Mailspring, PDF Studio Viewer)"
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
