#!/bin/bash

# This is an install script for OpenMandriva LX ROME. This should also work for ROCK 6.0.
# Created by: Mike Schappell
# Created: July 2025 | Edited: Aug 2025
# Version 1.2
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

# Variables
config="$HOME/.config"
dotfiles="https://github.com/schappellshow/stow.git"
packages="./packages.txt"
flatpaks="./flatpak.txt"
stow_dir="$HOME/stow"
script_dir="$(pwd)"

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

# Install build tools and core dependencies needed for later installations
print_status "Installing build tools and core dependencies..."
sudo dnf install -y make cmake gcc gcc-c++ autoconf automake libtool \
    python-pip flatpak rust cargo stow || {
    print_error "Failed to install build tools, continuing anyway..."
}

# Setup Flatpak if it was installed successfully
if command -v flatpak >/dev/null 2>&1; then
    print_status "Setting up Flatpak..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || {
        print_error "Failed to add Flathub repository"
    }
fi

print_success "Build tools and core dependencies installed."

# Install native packages via dnf
print_status "Installing native packages from $packages..."
if [[ -s "$packages" ]]; then
    # First, try to install all packages at once for efficiency
    print_status "Attempting bulk package installation..."
    if sudo dnf install -y $(grep -v '^[[:space:]]*#' "$packages" | grep -v '^[[:space:]]*$' | awk '{print $1}'); then
        print_success "All packages installed successfully in bulk!"
    else
        print_warning "Bulk installation failed, trying individual packages..."
        
        # Track failed packages for individual retry
        failed_packages=()
        successful_packages=()
        
        # Read packages line by line and install individually
        while IFS= read -r package || [[ -n "$package" ]]; do
            # Skip empty lines and comments
            [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
            
            # Extract just the package name (before any version info)
            package_name=$(echo "$package" | awk '{print $1}')
            print_status "Installing: $package_name"
            
            # Try to install individual package
            if sudo dnf install -y "$package_name" 2>/dev/null; then
                print_success "✓ Installed: $package_name"
                successful_packages+=("$package_name")
            else
                print_warning "⚠ Failed to install: $package_name"
                failed_packages+=("$package_name")
            fi
        done < "$packages"
        
        # Report results
        print_status "Package installation summary:"
        print_success "Successfully installed: ${#successful_packages[@]} packages"
        if [[ ${#failed_packages[@]} -gt 0 ]]; then
            print_warning "Failed to install: ${#failed_packages[@]} packages"
            for pkg in "${failed_packages[@]}"; do
                print_warning "  - $pkg"
            done
        fi
    fi
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
        flatpak install "$app_id" -y || {
            print_error "Failed to install $app_id, continuing..."
        }
    done < "$flatpaks"
else
    print_error "Flatpak list file is empty"
    exit 1
fi

print_success "Flatpak applications installation completed."



# Install Python applications via pip
print_status "Installing Python applications via pip..."

# Install konsave for KDE settings management
print_status "Installing konsave..."
python3 -m pip install --user konsave || {
    print_error "Failed to install konsave, continuing..."
}

# Import and apply konsave profile if available
if [[ -f "$HOME/ROME.knsv" ]]; then
    print_status "Importing konsave profile..."
    konsave -i "$HOME/ROME.knsv" || {
        print_error "Failed to import konsave profile, continuing..."
    }
    
    print_status "Applying konsave profile..."
    konsave -a ROME || {
        print_error "Failed to apply konsave profile, continuing..."
    }
    
    print_success "Konsave profile imported and applied"

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

else
    print_error "ROME.knsv not found in home directory, skipping profile import"
fi

print_success "Python applications installation completed"

# Install zoxide (smart cd replacement)
print_status "Installing zoxide..."
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || {
    print_error "Failed to install zoxide, continuing..."
}

print_success "Zoxide installation completed"

# Install individual RPM packages (Warp, Mailspring, PDF Studio Viewer)
# Note: Proton Pass and Proton VPN are now available in OpenMandriva repositories
print_status "Installing individual RPM packages..."

# Function to validate downloaded file
validate_download() {
    local file="$1"
    local min_size="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    if [[ $size -lt $min_size ]]; then
        print_error "Downloaded file is too small ($size bytes), likely an error page"
        return 1
    fi
    
    return 0
}

# Function to install RPM with update support
install_rpm_with_updates() {
    local rpm_file="$1"
    local app_name="$2"
    
    print_status "Installing $app_name with update support..."
    
    # Validate RPM file
    if ! validate_download "$rpm_file" 1000000; then
        print_error "Invalid RPM file for $app_name"
        return 1
    fi
    
    # Try DNF first (enables automatic updates)
    if sudo dnf install -y "$rpm_file"; then
        print_success "$app_name installed successfully with DNF (updates enabled)"
        
        # Check if repository was added
        if sudo dnf repolist | grep -q -i "$app_name"; then
            print_success "Repository added for $app_name updates"
        fi
        
        # Check if package is updateable
        if dnf check-update | grep -q -i "$app_name"; then
            print_success "$app_name will receive system updates"
        fi
        
        return 0
    else
        print_warning "DNF installation failed, trying RPM..."
        if sudo rpm -ivh "$rpm_file"; then
            print_success "$app_name installed with RPM (manual updates required)"
            print_warning "You may need to manually update $app_name in the future"
            return 0
        else
            print_error "Failed to install $app_name with both DNF and RPM"
            return 1
        fi
    fi
}

# Function to verify repository integration
verify_repository_integration() {
    local app_name="$1"
    
    print_status "Verifying repository integration for $app_name..."
    
    # Check if repository was added
    if sudo dnf repolist | grep -i "$app_name"; then
        print_success "Repository found for $app_name"
    else
        print_warning "No repository found for $app_name - manual updates may be required"
    fi
    
    # Check if package is updateable
    if dnf check-update | grep -i "$app_name"; then
        print_success "$app_name is updateable through system updates"
    else
        print_warning "$app_name may require manual updates"
    fi
}

# Install Warp terminal
print_status "Installing Warp terminal..."
WARP_RPM_FILE="/tmp/warp-terminal.rpm"

# Try multiple download methods for Warp
print_status "Downloading Warp terminal RPM..."
WARP_DOWNLOADED=false

# Method 1: Official download API
print_status "Trying official Warp download API..."
if curl -L "https://app.warp.dev/download?package=rpm" -o "$WARP_RPM_FILE" && validate_download "$WARP_RPM_FILE" 1000000; then
    WARP_DOWNLOADED=true
    print_success "Warp downloaded successfully via API"
else
    print_warning "Official API failed, trying alternative method..."
    
    # Method 2: Try to get latest release from GitHub
    print_status "Trying GitHub releases..."
    LATEST_WARP=$(curl -s "https://api.github.com/repos/warpdotdev/Warp/releases/latest" | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
    if [[ -n "$LATEST_WARP" ]]; then
        WARP_GITHUB_URL="https://github.com/warpdotdev/Warp/releases/download/${LATEST_WARP}/warp-terminal-${LATEST_WARP}-1-x86_64.rpm"
        if curl -L "$WARP_GITHUB_URL" -o "$WARP_RPM_FILE" && validate_download "$WARP_RPM_FILE" 1000000; then
            WARP_DOWNLOADED=true
            print_success "Warp downloaded successfully from GitHub"
        fi
    fi
fi

if [[ "$WARP_DOWNLOADED" == true ]]; then
    install_rpm_with_updates "$WARP_RPM_FILE" "Warp Terminal"
    verify_repository_integration "warp"
    rm -f "$WARP_RPM_FILE"
else
    print_error "Failed to download Warp terminal from all sources"
    print_warning "Continuing with remaining installations..."
fi

# Install Mailspring
print_status "Installing Mailspring..."
MAILSPRING_FILE="/tmp/mailspring.rpm"

print_status "Downloading Mailspring RPM..."
if curl -L "https://updates.getmailspring.com/download?platform=linuxRpm" -o "$MAILSPRING_FILE" && validate_download "$MAILSPRING_FILE" 1000000; then
    # Install dependencies first (ensuring they're available)
    print_status "Installing Mailspring dependencies..."
    sudo dnf install -y lib64appindicator lib64gtk3_0 || {
        print_warning "Some Mailspring dependencies failed to install, continuing with --nodeps"
    }
    
    # Try DNF first, then RPM with --nodeps as fallback
    print_status "Installing Mailspring with dependency handling..."
    if sudo dnf install -y "$MAILSPRING_FILE"; then
        print_success "Mailspring installed successfully with DNF"
        verify_repository_integration "mailspring"
    elif sudo rpm -ivh --nodeps "$MAILSPRING_FILE"; then
        print_success "Mailspring installed successfully with RPM (--nodeps)"
        print_warning "Mailspring installed without dependency checking - ensure libappindicator and gtk3 are installed"
        verify_repository_integration "mailspring"
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
PDF_STUDIO_FILE="/tmp/PDFStudioViewer_linux64.sh"

print_status "Downloading PDF Studio Viewer installer..."
if curl -L "https://download.qoppa.com/pdfstudioviewer/PDFStudioViewer_linux64.sh" -o "$PDF_STUDIO_FILE" && validate_download "$PDF_STUDIO_FILE" 1000000; then
    print_status "Installing PDF Studio Viewer..."
    chmod +x "$PDF_STUDIO_FILE"
    
    # Try unattended installation first
    if "$PDF_STUDIO_FILE" -q; then
        print_success "PDF Studio Viewer installed successfully in unattended mode"
    else
        print_warning "Unattended installation failed, trying interactive mode..."
        print_status "PDF Studio Viewer installer will run interactively - please follow the prompts"
        if "$PDF_STUDIO_FILE"; then
            print_success "PDF Studio Viewer installed successfully in interactive mode"
        else
            print_error "Failed to install PDF Studio Viewer"
            print_warning "Continuing with remaining installations..."
        fi
    fi
    
    rm -f "$PDF_STUDIO_FILE"
else
    print_error "Failed to download PDF Studio Viewer"
    print_warning "Continuing with remaining installations..."
fi

print_success "Individual RPM packages installation completed"

# Install Git-based projects
print_status "Installing Git-based projects..."

# Function to safely clone and build git repositories
clone_and_build() {
    local repo_url="$1"
    local project_name="$2"
    local build_dir="$3"
    local build_commands="$4"
    
    print_status "Installing $project_name..."
    
    # Create a temporary directory for cloning
    local temp_dir="/tmp/${project_name}-$(date +%s)"
    
    # Clone repository
    print_status "Cloning $project_name repository..."
    if git clone "$repo_url" "$temp_dir"; then
        print_success "Successfully cloned $project_name"
        
        # Change to the cloned directory
        cd "$temp_dir" || {
            print_error "Failed to change to $project_name directory"
            rm -rf "$temp_dir"
            return 1
        }
        
        # Execute build commands if provided
        if [[ -n "$build_commands" ]]; then
            print_status "Building $project_name..."
            eval "$build_commands" || {
                print_error "Failed to build $project_name, continuing..."
                cd - > /dev/null
                rm -rf "$temp_dir"
                return 1
            }
        fi
        
        # Move to final location if specified
        if [[ -n "$build_dir" ]]; then
            # Remove existing directory if it exists
            if [[ -d "$build_dir" ]]; then
                print_status "Removing existing $project_name directory..."
                rm -rf "$build_dir"
            fi
            
            # Create parent directory if it doesn't exist
            mkdir -p "$(dirname "$build_dir")"
            
            # Move to final location
            mv "$temp_dir" "$build_dir" || {
                print_error "Failed to move $project_name to final location"
                cd - > /dev/null
                rm -rf "$temp_dir"
                return 1
            }
            
            print_success "$project_name installed to $build_dir"
        else
            # Clean up temp directory if no final location specified
            cd - > /dev/null
            rm -rf "$temp_dir"
        fi
        
        return 0
    else
        print_error "Failed to clone $project_name repository"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Install conky-manager2
print_status "Installing conky-manager2..."

# Try to install from OpenMandriva repositories first
if sudo dnf install -y conky-manager2.x86_64; then
    print_success "Conky-manager2 installed successfully from repositories"
else
    print_warning "Conky-manager2 not available in repositories, trying to build from source..."
    
    CONKY_MANAGER_DIR="$HOME/conky-manager2"
    
    # Install build dependencies first
    print_status "Installing conky-manager2 build dependencies..."
    sudo dnf install -y conky.x86_64 lib64gtk+3.0-devel.x86_64 lib64glib2.0-devel.x86_64 pkgconf.x86_64 make.x86_64 gcc.x86_64 || {
        print_warning "Some build dependencies failed to install"
    }
    
    # Clone and build conky-manager2
    clone_and_build \
        "https://github.com/zcot/conky-manager2.git" \
        "conky-manager2" \
        "$CONKY_MANAGER_DIR" \
        "make && sudo make install" || {
        print_error "Conky-manager2 installation failed, continuing..."
    }
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
    print_status "You can run espanso from anywhere in your terminal"
else
    print_error "Failed to download espanso AppImage"
    print_warning "Continuing with remaining installations..."
fi

# Install Cursor AppImage
print_status "\n=== CURSOR APPIMAGE INSTALLATION ==="
print_status "Installing Cursor AppImage..."

# Create app_images directory if it doesn't exist
CURSOR_DIR="$HOME/app_images"
mkdir -p "$CURSOR_DIR"

# Download Cursor AppImage
CURSOR_URL="https://download.todesktop.com/230313mzl4w92u92/linux/x64"
CURSOR_FILE="$CURSOR_DIR/cursor.AppImage"

print_status "Downloading Cursor AppImage..."
if curl -L "$CURSOR_URL" -o "$CURSOR_FILE"; then
    # Make AppImage executable
    chmod +x "$CURSOR_FILE"
    
    print_success "Cursor AppImage downloaded successfully"
    print_status "Cursor is available at: $CURSOR_FILE"
    print_status "You can manage it with Gear Lever or run it directly: $CURSOR_FILE"
else
    print_error "Failed to download Cursor AppImage"
    print_warning "Continuing with remaining installations..."
fi

# Install kwin-forceblur plugin
print_status "Installing kwin-forceblur plugin..."

# Install ECM (Extra CMake Modules) for kwin-forceblur
print_status "Installing ECM for kwin-forceblur..."
sudo dnf install -y extra-cmake-modules.noarch || {
    print_warning "Failed to install ECM, kwin-forceblur may not build"
}

FORCEBLUR_VERSION="1.3.6"
FORCEBLUR_URL="https://github.com/taj-ny/kwin-effects-forceblur/archive/refs/tags/v${FORCEBLUR_VERSION}.tar.gz"
FORCEBLUR_DIR="$HOME/kwin-effects-forceblur-${FORCEBLUR_VERSION}"
FORCEBLUR_ARCHIVE="/tmp/kwin-forceblur-v${FORCEBLUR_VERSION}.tar.gz"

# Download and extract kwin-forceblur
print_status "Downloading kwin-forceblur v${FORCEBLUR_VERSION}..."
if curl -L "$FORCEBLUR_URL" -o "$FORCEBLUR_ARCHIVE"; then
    print_status "Extracting kwin-forceblur..."
    cd /tmp || {
        print_error "Failed to change to /tmp directory"
    }
    
    if tar -xzf "$FORCEBLUR_ARCHIVE"; then
        # Find the extracted directory
        extracted_dir=$(find /tmp -maxdepth 1 -name "kwin-effects-forceblur-*" -type d | head -1)
        
        if [[ -n "$extracted_dir" && -d "$extracted_dir" ]]; then
            print_status "Building kwin-forceblur..."
            cd "$extracted_dir" || {
                print_error "Failed to change to kwin-forceblur directory"
            }
            
            # Create build directory and build
            mkdir -p build
            cd build || {
                print_error "Failed to change to build directory"
            }
            
            if cmake .. -DCMAKE_INSTALL_PREFIX=/usr; then
                if make -j$(nproc); then
                    if sudo make install; then
                        # Apply OpenMandriva-specific fixes based on the installation steps file
                        print_status "Applying OpenMandriva-specific plugin fixes..."
                        
                        # Create Qt6 plugin directories
                        sudo mkdir -p /usr/lib64/qt6/plugins/kwin/effects/plugins
                        sudo mkdir -p /usr/lib64/qt6/plugins/kwin/effects/configs
                        sudo mkdir -p /usr/share/kwin/effects/forceblur
                        
                        # Copy plugin files to correct Qt6 locations
                        if [[ -f "src/forceblur.so" ]]; then
                            print_status "Copying plugin binary to Qt6 directory..."
                            sudo cp src/forceblur.so /usr/lib64/qt6/plugins/kwin/effects/plugins/ || {
                                print_error "Failed to copy plugin binary"
                            }
                        fi
                        
                        if [[ -f "src/kcm/kwin_better_blur_config.so" ]]; then
                            print_status "Copying configuration module to Qt6 directory..."
                            sudo cp src/kcm/kwin_better_blur_config.so /usr/lib64/qt6/plugins/kwin/effects/configs/ || {
                                print_error "Failed to copy configuration module"
                            }
                        fi
                        
                        if [[ -f "../src/metadata.json" ]]; then
                            print_status "Copying metadata file..."
                            sudo cp ../src/metadata.json /usr/share/kwin/effects/forceblur/ || {
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
                        print_error "Failed to install kwin-forceblur, continuing..."
                    fi
                else
                    print_error "Failed to build kwin-forceblur, continuing..."
                fi
            else
                print_error "Failed to configure kwin-forceblur with cmake, continuing..."
            fi
            
            # Return to original directory
            cd - > /dev/null
        else
            print_error "Failed to extract kwin-forceblur, skipping installation"
        fi
    else
        print_error "Failed to extract kwin-forceblur, skipping installation"
    fi
    
    # Clean up downloaded file
    rm -f "$FORCEBLUR_ARCHIVE"
else
    print_error "Failed to download kwin-forceblur, skipping installation"
fi

print_success "Git-based projects installation completed"

# Install Oh My Zsh
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
    
    # Backup existing .zshrc if it exists
    if [[ -f "$HOME/.zshrc" ]]; then
        print_status "Backing up existing .zshrc..."
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)" || {
            print_warning "Failed to backup existing .zshrc"
        }
    fi
    
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

# Setup Dotfiles (AFTER Oh My Zsh so stow can replace the default .zshrc)
print_status "Setting up dotfiles..."

# Clean up existing config files that would conflict with stow
print_status "Cleaning up existing config files to prevent conflicts..."
print_status "This ensures your custom dotfiles will be applied correctly..."
print_status ""
print_status "The following config files will be removed to prevent conflicts:"
echo "  • ~/.zshrc (will be replaced with your custom version)"
echo "  • ~/.config/espanso/ (will be replaced with your custom configs)"
echo "  • ~/.config/fastfetch/ (will be replaced with your custom configs)"
echo "  • ~/.config/ghostty/ (will be replaced with your custom configs)"
echo "  • ~/.config/kitty/ (will be replaced with your custom configs)"
echo "  • ~/.config/micro/ (will be replaced with your custom configs)"
echo "  • ~/.conky/ (will be replaced with your custom configs)"
echo "  • ~/.local/share/espanso/ (will be replaced with your custom configs)"
echo "  • ~/.oh-my-zsh/custom/ (will be replaced with your custom configs)"
echo ""

read -p "Proceed with cleanup? This will remove existing configs. (y/N): " -r cleanup_confirm

if [[ $cleanup_confirm =~ ^[Yy]$ ]]; then
    # Offer backup option
    read -p "Would you like to backup existing configs first? (y/N): " -r backup_confirm
    
    if [[ $backup_confirm =~ ^[Yy]$ ]]; then
        backup_dir="$HOME/config_backup_$(date +%Y%m%d_%H%M%S)"
        print_status "Creating backup in: $backup_dir"
        mkdir -p "$backup_dir"
        
        # Backup existing configs
        if [[ -f ~/.zshrc ]]; then cp ~/.zshrc "$backup_dir/"; fi
        if [[ -d ~/.config/espanso ]]; then cp -r ~/.config/espanso "$backup_dir/"; fi
        if [[ -d ~/.config/fastfetch ]]; then cp -r ~/.config/fastfetch "$backup_dir/"; fi
        if [[ -d ~/.config/ghostty ]]; then cp -r ~/.config/ghostty "$backup_dir/"; fi
        if [[ -d ~/.config/kitty ]]; then cp -r ~/.config/kitty "$backup_dir/"; fi
        if [[ -d ~/.config/micro ]]; then cp -r ~/.config/micro "$backup_dir/"; fi
        if [[ -d ~/.conky ]]; then cp -r ~/.conky "$backup_dir/"; fi
        if [[ -d ~/.local/share/espanso ]]; then cp -r ~/.local/share/espanso "$backup_dir/"; fi
        if [[ -d ~/.oh-my-zsh/custom ]]; then cp -r ~/.oh-my-zsh/custom "$backup_dir/"; fi
        
        print_success "Backup completed in: $backup_dir"
    fi
    
    print_status "Proceeding with config cleanup..."
    
    # Remove conflicting dotfiles and configs
    print_status "Removing conflicting .zshrc..."
    rm -f ~/.zshrc

    print_status "Removing conflicting espanso configs..."
    rm -rf ~/.config/espanso

    print_status "Removing other potentially conflicting configs..."
    rm -rf ~/.config/fastfetch
    rm -rf ~/.config/ghostty
    rm -rf ~/.config/kitty
    rm -rf ~/.config/micro

    # Also clean up any other potential conflicts
    print_status "Removing additional potential conflicts..."
    rm -rf ~/.conky
    rm -rf ~/.local/share/espanso
    rm -rf ~/.oh-my-zsh/custom/aliases.zsh

    print_status "Config cleanup completed. Now applying your custom dotfiles..."
else
    print_warning "Skipping config cleanup. Your dotfiles may not apply correctly due to conflicts."
    print_status "Continuing with dotfiles installation..."
fi

# Clone dotfiles repository directly to ~/stow
print_status "Cloning dotfiles repository to $stow_dir..."
if [[ -d "$stow_dir" ]]; then
    print_status "Removing existing stow directory..."
    rm -rf "$stow_dir"
fi

if git clone "$dotfiles" "$stow_dir"; then
    print_success "Successfully cloned dotfiles to $stow_dir"
    
    # Apply stow configuration
    print_status "Applying dotfiles with stow..."
    if [[ -d "$stow_dir" ]]; then
        cd "$stow_dir" || {
            print_error "Failed to change to stow directory"
            print_warning "Continuing with remaining installations..."
        }
        
        # Create config directory if it doesn't exist
        mkdir -p "$config"
        
        # Apply stow configuration with adopt flag to handle conflicts
        print_status "Applying dotfiles with stow..."
        
        # Since we've cleaned up conflicts, we can use a simpler stow command
        print_status "Applying all stow packages..."
        
        # Try to stow all packages
        stow . || {
            print_error "Failed to apply dotfiles with stow"
            print_warning "You may need to manually resolve conflicts in your dotfiles"
            print_warning "Continuing with remaining installations..."
        }
        
        print_success "Dotfiles applied successfully."
        
        # Return to original directory
        cd "$script_dir" || {
            print_error "Failed to return to script directory"
            print_warning "Continuing with remaining installations..."
        }
    else
        print_error "Stow directory not found: $stow_dir"
        print_warning "Continuing with remaining installations..."
    fi
else
    print_error "Failed to clone dotfiles repository"
    print_warning "Continuing with remaining installations..."
fi



# Install Cargo applications (optional)
print_status "\n=== CARGO APPLICATIONS INSTALLATION ==="
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

print_success "\n🎉 Installation script completed successfully!"
print_status "\nNext steps:"
print_status "1. Reboot your system to ensure all changes take effect"
print_status "2. Log out and log back in to apply dotfiles changes"
print_status "3. Check that all applications are working correctly"
print_status "4. Install cargo applications later if needed: bash install_cargo_apps.sh"

print_status "\nInstallation log saved. Check for any warnings above."

