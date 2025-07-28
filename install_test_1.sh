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

# Install Cargo applications
print_status "Installing cargo applications..."

# Define cargo applications to install
cargo_apps=("cargo-make" "cargo-update" "fd-find" "resvg" "ripgrep" "rust-script" "yazi-fm" "yazi-cli")

# Install cargo applications one by one for better error handling
for app in "${cargo_apps[@]}"; do
    print_status "Installing cargo app: $app"
    cargo install --locked "$app" || {
        print_error "Failed to install $app, continuing with other applications..."
    }
done

print_success "Cargo applications installation completed"

# Install Python applications via pip
print_status "Installing Python applications via pip..."

# Install konsave for KDE settings management
print_status "Installing konsave..."
python -m pip install --user konsave || {
    print_error "Failed to install konsave, continuing..."
}

# Import and apply konsave profile if available
if [[ -f "$HOME/ROME.knsv" ]]; then
    print_status "Importing konsave profile..."
    konsave -i "$HOME/ROME.knsv" || {
        print_error "Failed to import konsave profile, continuing..."
    }
    
    print_status "Applying konsave profile..."
    konsave -a "$HOME/ROME.knsv" || {
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

# Install Warp terminal
print_status "Installing Warp terminal..."
WARP_RPM_URL="https://releases.warp.dev/linux/v0.2024.10.29.08.02.stable_02/warp-terminal-v0.2024.10.29.08.02.stable_02-1-x86_64.rpm"
WARP_RPM_FILE="/tmp/warp-terminal.rpm"

# Download Warp RPM
print_status "Downloading Warp terminal RPM..."
curl -L "$WARP_RPM_URL" -o "$WARP_RPM_FILE" || {
    print_error "Failed to download Warp terminal, trying alternative method..."
    
    # Alternative: Try to get latest from their API or use a known stable URL
    print_status "Trying alternative download method..."
    curl -L "https://app.warp.dev/download?package=rpm" -o "$WARP_RPM_FILE" || {
        print_error "Failed to download Warp terminal, skipping installation"
        WARP_RPM_FILE=""
    }
}

# Install Warp if download was successful
if [[ -n "$WARP_RPM_FILE" && -f "$WARP_RPM_FILE" ]]; then
    print_status "Installing Warp terminal RPM..."
    sudo dnf install -y "$WARP_RPM_FILE" || {
        print_error "Failed to install Warp terminal with dnf, trying rpm..."
        sudo rpm -ivh "$WARP_RPM_FILE" || {
            print_error "Failed to install Warp terminal, continuing..."
        }
    }
    
    # Clean up downloaded file
    rm -f "$WARP_RPM_FILE"
    print_success "Warp terminal installation completed"
else
    print_error "Warp terminal installation skipped due to download failure"
fi

# Install Mailspring
print_status "Installing Mailspring..."
MAILSPRING_URL="https://updates.getmailspring.com/download?platform=linuxRpm"
MAILSPRING_FILE="/tmp/mailspring.rpm"

# Download Mailspring RPM
print_status "Downloading Mailspring RPM..."
curl -L "$MAILSPRING_URL" -o "$MAILSPRING_FILE" || {
    print_error "Failed to download Mailspring, skipping installation"
    MAILSPRING_FILE=""
}

# Install Mailspring if download was successful
if [[ -n "$MAILSPRING_FILE" && -f "$MAILSPRING_FILE" ]]; then
    print_status "Installing Mailspring RPM..."
    sudo dnf install -y "$MAILSPRING_FILE" || {
        print_error "Failed to install Mailspring with dnf, trying rpm..."
        sudo rpm -ivh "$MAILSPRING_FILE" || {
            print_error "Failed to install Mailspring, continuing..."
        }
    }
    
    # Clean up downloaded file
    rm -f "$MAILSPRING_FILE"
    print_success "Mailspring installation completed"
else
    print_error "Mailspring installation skipped due to download failure"
fi

# Install Proton Pass
print_status "Installing Proton Pass..."
PROTON_PASS_URL="https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm"
PROTON_PASS_FILE="/tmp/proton-pass.rpm"

# Download Proton Pass RPM
print_status "Downloading Proton Pass RPM..."
curl -L "$PROTON_PASS_URL" -o "$PROTON_PASS_FILE" || {
    print_error "Failed to download Proton Pass, skipping installation"
    PROTON_PASS_FILE=""
}

# Install Proton Pass if download was successful
if [[ -n "$PROTON_PASS_FILE" && -f "$PROTON_PASS_FILE" ]]; then
    print_status "Installing Proton Pass RPM..."
    sudo dnf install -y "$PROTON_PASS_FILE" || {
        print_error "Failed to install Proton Pass with dnf, trying rpm..."
        sudo rpm -ivh "$PROTON_PASS_FILE" || {
            print_error "Failed to install Proton Pass, continuing..."
        }
    }
    
    # Clean up downloaded file
    rm -f "$PROTON_PASS_FILE"
    print_success "Proton Pass installation completed"
else
    print_error "Proton Pass installation skipped due to download failure"
fi

# Install PDF Studio Viewer
print_status "Installing PDF Studio Viewer..."
PDF_STUDIO_URL="https://download.qoppa.com/pdfstudioviewer/PDFStudioViewer_linux64.sh"
PDF_STUDIO_FILE="/tmp/PDFStudioViewer_linux64.sh"

# Download PDF Studio Viewer installer
print_status "Downloading PDF Studio Viewer installer..."
curl -L "$PDF_STUDIO_URL" -o "$PDF_STUDIO_FILE" || {
    print_error "Failed to download PDF Studio Viewer, skipping installation"
    PDF_STUDIO_FILE=""
}

# Install PDF Studio Viewer if download was successful
if [[ -n "$PDF_STUDIO_FILE" && -f "$PDF_STUDIO_FILE" ]]; then
    print_status "Installing PDF Studio Viewer..."
    chmod +x "$PDF_STUDIO_FILE"
    # Run installer in unattended mode (if supported)
    "$PDF_STUDIO_FILE" -q || {
        print_error "Unattended installation failed, trying interactive mode..."
        print_status "PDF Studio Viewer installer will run interactively - please follow the prompts"
        "$PDF_STUDIO_FILE" || {
            print_error "Failed to install PDF Studio Viewer, continuing..."
        }
    }
    
    # Clean up downloaded file
    rm -f "$PDF_STUDIO_FILE"
    print_success "PDF Studio Viewer installation completed"
else
    print_error "PDF Studio Viewer installation skipped due to download failure"
fi

print_success "Individual RPM packages installation completed"

# Install Git-based projects
print_status "Installing Git-based projects..."

# Install conky-manager2
print_status "Installing conky-manager2..."
CONKY_MANAGER_DIR="/tmp/conky-manager2"

# Clone and build conky-manager2
print_status "Cloning conky-manager2 repository..."
git clone https://github.com/zcot/conky-manager2.git "$CONKY_MANAGER_DIR" || {
    print_error "Failed to clone conky-manager2, skipping installation"
    CONKY_MANAGER_DIR=""
}

if [[ -n "$CONKY_MANAGER_DIR" && -d "$CONKY_MANAGER_DIR" ]]; then
    print_status "Building and installing conky-manager2..."
    cd "$CONKY_MANAGER_DIR" || {
        print_error "Failed to change to conky-manager2 directory"
    }
    
    # Build and install
    make || {
        print_error "Failed to build conky-manager2, continuing..."
    }
    
    sudo make install || {
        print_error "Failed to install conky-manager2, continuing..."
    }
    
    # Return to original directory and cleanup
    cd - > /dev/null
    rm -rf "$CONKY_MANAGER_DIR"
    print_success "Conky-manager2 installation completed"
else
    print_error "Conky-manager2 installation skipped"
fi

# Install espanso
print_status "Installing espanso..."
ESPANSO_DIR="/tmp/espanso"

# Clone and build espanso
print_status "Cloning espanso repository..."
git clone https://github.com/espanso/espanso "$ESPANSO_DIR" || {
    print_error "Failed to clone espanso, skipping installation"
    ESPANSO_DIR=""
}

if [[ -n "$ESPANSO_DIR" && -d "$ESPANSO_DIR" ]]; then
    print_status "Building espanso..."
    cd "$ESPANSO_DIR" || {
        print_error "Failed to change to espanso directory"
    }
    
    # Build espanso with specific features
    cargo build -p espanso --release --no-default-features --features vendored-tls,modulo || {
        print_error "Failed to build espanso, continuing..."
    }
    
    # Install espanso binary
    if [[ -f "target/release/espanso" ]]; then
        print_status "Installing espanso binary..."
        sudo mv target/release/espanso /usr/local/bin/espanso || {
            print_error "Failed to install espanso binary, continuing..."
        }
        
        # Register espanso as systemd service
        print_status "Registering espanso as systemd service..."
        espanso service register || {
            print_error "Failed to register espanso service, continuing..."
        }
        
        # Start espanso
        print_status "Starting espanso..."
        espanso start || {
            print_error "Failed to start espanso, you may need to start it manually later"
        }
        
        print_success "Espanso installation and setup completed"
    else
        print_error "Espanso binary not found after build"
    fi
    
    # Return to original directory and cleanup
    cd - > /dev/null
    rm -rf "$ESPANSO_DIR"
else
    print_error "Espanso installation skipped"
fi

# Install kwin-forceblur plugin
print_status "Installing kwin-forceblur plugin..."
FORCEBLUR_VERSION="1.3.6"
FORCEBLUR_URL="https://github.com/taj-ny/kwin-effects-forceblur/archive/refs/tags/v${FORCEBLUR_VERSION}.tar.gz"
FORCEBLUR_DIR="/tmp/kwin-effects-forceblur-${FORCEBLUR_VERSION}"
FORCEBLUR_ARCHIVE="/tmp/kwin-forceblur-v${FORCEBLUR_VERSION}.tar.gz"

# Download and extract kwin-forceblur
print_status "Downloading kwin-forceblur v${FORCEBLUR_VERSION}..."
curl -L "$FORCEBLUR_URL" -o "$FORCEBLUR_ARCHIVE" || {
    print_error "Failed to download kwin-forceblur, skipping installation"
    FORCEBLUR_ARCHIVE=""
}

if [[ -n "$FORCEBLUR_ARCHIVE" && -f "$FORCEBLUR_ARCHIVE" ]]; then
    print_status "Extracting kwin-forceblur..."
    cd /tmp
    tar -xzf "$FORCEBLUR_ARCHIVE" || {
        print_error "Failed to extract kwin-forceblur, skipping installation"
        FORCEBLUR_DIR=""
    }
    
    if [[ -n "$FORCEBLUR_DIR" && -d "$FORCEBLUR_DIR" ]]; then
        print_status "Building kwin-forceblur..."
        cd "$FORCEBLUR_DIR" || {
            print_error "Failed to change to kwin-forceblur directory"
        }
        
        # Create build directory and build
        mkdir -p build
        cd build || {
            print_error "Failed to change to build directory"
        }
        
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr || {
            print_error "Failed to configure kwin-forceblur with cmake, continuing..."
        }
        
        make -j$(nproc) || {
            print_error "Failed to build kwin-forceblur, continuing..."
        }
        
        sudo make install || {
            print_error "Failed to install kwin-forceblur, continuing..."
        }
        
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
        
        # Return to original directory
        cd - > /dev/null
    fi
    
    # Cleanup
    rm -rf "$FORCEBLUR_DIR" "$FORCEBLUR_ARCHIVE"
else
    print_error "Kwin-forceblur installation skipped"
fi

print_success "Git-based projects installation completed"

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
