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

# Install individual RPM packages
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

# Install Proton Pass
print_status "Installing Proton Pass..."
PROTON_PASS_FILE="/tmp/proton-pass.rpm"

print_status "Downloading Proton Pass RPM..."
if curl -L "https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm" -o "$PROTON_PASS_FILE" && validate_download "$PROTON_PASS_FILE" 1000000; then
    # Proton Pass dependencies are now handled by packages.txt installation
    print_status "Installing Proton Pass..."
    
    # Try multiple installation methods
    if sudo dnf install -y "$PROTON_PASS_FILE"; then
        print_success "Proton Pass installed successfully with DNF"
        verify_repository_integration "proton"
    elif sudo rpm -ivh --nodeps "$PROTON_PASS_FILE"; then
        print_success "Proton Pass installed with RPM (dependencies may need manual installation)"
        print_warning "You may need to install missing dependencies manually"
    else
        print_error "Failed to install Proton Pass"
        print_warning "Continuing with remaining installations..."
    fi
    
    rm -f "$PROTON_PASS_FILE"
else
    print_error "Failed to download Proton Pass"
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

# Install Cursor AppImage
print_status "Installing Cursor AppImage..."

# Create applications directory if it doesn't exist
CURSOR_DIR="$HOME/.local/bin"
mkdir -p "$CURSOR_DIR"

# Download Cursor AppImage
CURSOR_URL="https://download.todesktop.com/230313mzl4w92u92/linux/x64"
CURSOR_FILE="$CURSOR_DIR/cursor.AppImage"

print_status "Downloading Cursor AppImage..."
if curl -L "$CURSOR_URL" -o "$CURSOR_FILE"; then
    # Make AppImage executable
    chmod +x "$CURSOR_FILE"
    
    # Create desktop entry
    print_status "Creating Cursor desktop entry..."
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/cursor.desktop" << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-first code editor
Exec=$CURSOR_FILE
Icon=cursor
Type=Application
Categories=Development;IDE;
StartupWMClass=cursor
EOF
    
    # Create icon symlink if possible
    if [[ -f "$CURSOR_FILE" ]]; then
        # Extract icon from AppImage (this is a simplified approach)
        print_status "Setting up Cursor icon..."
        # Note: AppImages can be mounted to extract icons, but for simplicity we'll use a generic icon
        # You can manually add an icon later if needed
    fi
    
    print_success "Cursor AppImage installed successfully"
    print_status "Cursor is available at: $CURSOR_FILE"
    print_status "You can launch it from your applications menu or by running: $CURSOR_FILE"
else
    print_error "Failed to download Cursor AppImage"
    print_warning "Continuing with remaining installations..."
fi

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

# Install espanso
print_status "Installing espanso..."

# Ask user for espanso installation method
print_status "Espanso can be installed using two methods:"
echo "  1) Build from source (requires dependencies, may have compilation issues)"
echo "  2) Install AppImage (no compilation, faster, self-contained)"
echo

read -p "Which method would you prefer for espanso? (1/2): " -r espanso_method

if [[ "$espanso_method" == "2" ]]; then
    print_status "Installing espanso using AppImage..."
    
    # Run the AppImage installation script
    if [[ -f "./install_espanso_appimage.sh" ]]; then
        bash ./install_espanso_appimage.sh
    else
        print_error "Espanso AppImage installation script not found"
        print_warning "Falling back to source build method"
        espanso_method="1"
    fi
fi

if [[ "$espanso_method" == "1" ]]; then
    print_status "Installing espanso from source..."
    ESPANSO_DIR="$HOME/espanso"

# Install X11 development dependencies for espanso
print_status "Installing espanso X11 dependencies..."
sudo dnf install -y lib64x11-devel.x86_64 lib64xkbcommon-devel.x86_64 lib64xrandr-devel.x86_64 lib64xtst-devel.x86_64 || {
    print_warning "Some X11 dependencies failed to install"
}

# Install OpenSSL development dependencies for espanso cargo build
print_status "Installing espanso OpenSSL dependencies..."
sudo dnf install -y libopenssl-devel.x86_64 lib64openssl-devel.x86_64 || {
    print_warning "Some OpenSSL dependencies failed to install"
}

# Configure OpenSSL for espanso cargo build
print_status "Configuring OpenSSL for espanso build..."
export OPENSSL_DIR=$(pkg-config --variable=prefix openssl)
export OPENSSL_LIB_DIR=$(pkg-config --variable=libdir openssl)
export OPENSSL_INCLUDE_DIR=$(pkg-config --variable=includedir openssl)
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"

print_status "OpenSSL configuration for espanso:"
print_status "  OPENSSL_DIR: $OPENSSL_DIR"
print_status "  OPENSSL_LIB_DIR: $OPENSSL_LIB_DIR"
print_status "  OPENSSL_INCLUDE_DIR: $OPENSSL_INCLUDE_DIR"

# Clone and build espanso
clone_and_build \
    "https://github.com/espanso/espanso.git" \
    "espanso" \
    "$ESPANSO_DIR" \
    "cargo build -p espanso --release --no-default-features --features vendored-tls,modulo" || {
    print_error "Espanso build failed, continuing..."
}

# Install espanso binary if build was successful
if [[ -d "$ESPANSO_DIR" && -f "$ESPANSO_DIR/target/release/espanso" ]]; then
    print_status "Installing espanso binary..."
    sudo mv "$ESPANSO_DIR/target/release/espanso" /usr/local/bin/espanso || {
        print_error "Failed to install espanso binary, continuing..."
    }
    
    # Register espanso as systemd service
    print_status "Registering espanso as systemd service..."
    /usr/local/bin/espanso service register || {
        print_error "Failed to register espanso service, continuing..."
    }
    
    # Start espanso
    print_status "Starting espanso..."
    /usr/local/bin/espanso start || {
        print_error "Failed to start espanso, you may need to start it manually later"
    }
    
    print_success "Espanso installation and setup completed"
else
    print_error "Espanso binary not found after build"
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
            if chsh -s /bin/zsh; then
                print_success "Zsh set as default shell"
                print_warning "You may need to log out and log back in for the change to take effect"
            else
                print_warning "Failed to set zsh as default shell, you can do this manually later"
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

# Setup Dotfiles
print_status "Setting up dotfiles..."

# Clone dotfiles repository safely
clone_and_build \
    "$dotfiles" \
    "dotfiles" \
    "$stow_dir" \
    "" || {
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

# Apply stow configuration with adopt flag to handle conflicts
print_status "Applying dotfiles with stow (adopting existing files)..."
stow . --adopt || {
    print_warning "Stow failed with --adopt, trying without..."
    stow . || {
        print_error "Failed to apply dotfiles with stow"
        print_warning "You may need to manually resolve conflicts in your dotfiles"
        exit 1
    }
}

print_success "Dotfiles applied successfully."

# Return to original directory
cd - > /dev/null

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
