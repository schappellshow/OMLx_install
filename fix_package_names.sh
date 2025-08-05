#!/bin/bash

# Package Name Fixer for OpenMandriva
# This script checks and fixes package names to match OpenMandriva's conventions

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

# Function to check if a package exists
check_package() {
    local package="$1"
    if dnf search "$package" 2>/dev/null | grep -q "$package"; then
        print_success "✓ Found: $package"
        return 0
    else
        print_warning "✗ Not found: $package"
        return 1
    fi
}

# Function to find alternative package names
find_alternative() {
    local package="$1"
    local alternatives=()
    
    # Common alternative patterns for OpenMandriva
    case "$package" in
        at-spi2)
            alternatives+=("at-spi2-core" "at-spi2-atk" "at-spi2-gtk3")
            ;;
        adwaita-icon)
            alternatives+=("adwaita-icon-theme" "adwaita-gtk3-theme")
            ;;
        appstream-glib)
            alternatives+=("lib64appstream-glib8" "appstream-glib-i18n")
            ;;
        bat-bash)
            alternatives+=("bat-bash-completion")
            ;;
        bat-zsh)
            alternatives+=("bat-zsh-completion")
            ;;
        extra-cmake)
            alternatives+=("extra-cmake-modules")
            ;;
        fonts-ttf)
            alternatives+=("fonts-ttf-bitstream-vera" "fonts-ttf-dejavu")
            ;;
        lib64avahi-client)
            alternatives+=("lib64avahi-client-devel")
            ;;
        lib64avahi-common)
            alternatives+=("lib64avahi-common-devel")
            ;;
        lib64gtk4-layer)
            alternatives+=("lib64gtk4-layer-shell")
            ;;
        lib64gtksourceview)
            alternatives+=("gtksourceview")
            ;;
        lib64gtk-vnc)
            alternatives+=("gtk-vnc-common" "gtk-vnc")
            ;;
        lib64harfbuzz-gir)
            alternatives+=("lib64harfbuzz-gir0.0")
            ;;
        lib64json-glib)
            alternatives+=("lib64json-glib-devel")
            ;;
        lib64luajit)
            alternatives+=("luajit" "lib64luajit-devel")
            ;;
        lib64spice-client)
            alternatives+=("lib64spice-client-gtk3.0_5")
            ;;
        lib64virt-glib)
            alternatives+=("lib64virt-glib-devel")
            ;;
        perl-XML)
            alternatives+=("perl-XML-Parser" "perl-XML-Simple")
            ;;
        python-charset)
            alternatives+=("python3-chardet")
            ;;
        python-libcap)
            alternatives+=("python3-libcap")
            ;;
        python-pkg)
            alternatives+=("python3-pkgconfig")
            ;;
        qemu-audio)
            alternatives+=("qemu-audio-alsa" "qemu-audio-pa")
            ;;
        qemu-block)
            alternatives+=("qemu-block-iscsi" "qemu-block-rbd")
            ;;
        qemu-char)
            alternatives+=("qemu-char-pty" "qemu-char-serial")
            ;;
        qemu-device)
            alternatives+=("qemu-device-usb" "qemu-device-virtio")
            ;;
        qemu-system)
            alternatives+=("qemu-system-x86" "qemu-system-arm")
            ;;
        qemu-ui)
            alternatives+=("qemu-ui-gtk" "qemu-ui-sdl")
            ;;
        qt6-qtbase)
            alternatives+=("qt6-qtbase-devel" "qt6-qtbase-common")
            ;;
        qt-avif)
            alternatives+=("qt6-qtimageformats")
            ;;
        qt-jpegxl)
            alternatives+=("qt6-qtimageformats")
            ;;
        qt-theme)
            alternatives+=("qt6-qtbase-theme-gtk3")
            ;;
        rust-std)
            alternatives+=("rust-std-static" "rust-std-wasm32")
            ;;
        shared-mime)
            alternatives+=("shared-mime-info")
            ;;
        vlc-plugin)
            alternatives+=("vlc-plugin-qt" "vlc-plugin-video-output")
            ;;
        x11-proto)
            alternatives+=("xorg-x11-proto-devel")
            ;;
        xdg-dbus)
            alternatives+=("xdg-dbus-proxy")
            ;;
        xdg-desktop)
            alternatives+=("xdg-desktop-portal" "xdg-desktop-portal-gtk")
            ;;
        xdg-user)
            alternatives+=("xdg-user-dirs" "xdg-user-dirs-gtk")
            ;;
    esac
    
    for alt in "${alternatives[@]}"; do
        if dnf search "$alt" 2>/dev/null | grep -q "$alt"; then
            print_success "  → Alternative found: $alt"
            return 0
        fi
    done
    
    return 1
}

# Function to process packages.txt and create corrected version
fix_packages_txt() {
    print_status "Processing packages.txt to fix package names..."
    
    # Create backup
    cp packages.txt packages.txt.backup
    
    # Read packages.txt and process each line
    local line_num=0
    local fixed_count=0
    local removed_count=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*$ ]]; then
            echo "$line" >> packages.txt.fixed
            continue
        fi
        
        # Extract package name (remove .x86_64, .noarch, etc.)
        local package_name=$(echo "$line" | sed 's/\.x86_64$//' | sed 's/\.noarch$//' | sed 's/\.i686$//')
        
        # Check if package exists
        if check_package "$package_name" >/dev/null 2>&1; then
            echo "$line" >> packages.txt.fixed
        else
            # Try to find alternative
            if find_alternative "$package_name" >/dev/null 2>&1; then
                # Find the actual alternative name
                case "$package_name" in
                    at-spi2)
                        echo "at-spi2-core.x86_64" >> packages.txt.fixed
                        ;;
                    adwaita-icon)
                        echo "adwaita-icon-theme.noarch" >> packages.txt.fixed
                        ;;
                    appstream-glib)
                        echo "lib64appstream-glib8.x86_64" >> packages.txt.fixed
                        ;;
                    bat-bash)
                        echo "bat-bash-completion.noarch" >> packages.txt.fixed
                        ;;
                    bat-zsh)
                        echo "bat-zsh-completion.noarch" >> packages.txt.fixed
                        ;;
                    extra-cmake)
                        echo "extra-cmake-modules.noarch" >> packages.txt.fixed
                        ;;
                    fonts-ttf)
                        echo "fonts-ttf-bitstream-vera.noarch" >> packages.txt.fixed
                        ;;
                    lib64avahi-client)
                        echo "lib64avahi-client-devel.x86_64" >> packages.txt.fixed
                        ;;
                    lib64avahi-common)
                        echo "lib64avahi-common-devel.x86_64" >> packages.txt.fixed
                        ;;
                    lib64gtk4-layer)
                        echo "lib64gtk4-layer-shell.x86_64" >> packages.txt.fixed
                        ;;
                    lib64gtksourceview)
                        echo "gtksourceview.x86_64" >> packages.txt.fixed
                        ;;
                    lib64gtk-vnc)
                        echo "gtk-vnc-common.x86_64" >> packages.txt.fixed
                        ;;
                    lib64harfbuzz-gir)
                        echo "lib64harfbuzz-gir0.0.x86_64" >> packages.txt.fixed
                        ;;
                    lib64json-glib)
                        echo "lib64json-glib-devel.x86_64" >> packages.txt.fixed
                        ;;
                    lib64luajit)
                        echo "luajit.x86_64" >> packages.txt.fixed
                        ;;
                    lib64spice-client)
                        echo "lib64spice-client-gtk3.0_5.x86_64" >> packages.txt.fixed
                        ;;
                    lib64virt-glib)
                        echo "lib64virt-glib-devel.x86_64" >> packages.txt.fixed
                        ;;
                    perl-XML)
                        echo "perl-XML-Parser.noarch" >> packages.txt.fixed
                        ;;
                    python-charset)
                        echo "python3-chardet.noarch" >> packages.txt.fixed
                        ;;
                    python-libcap)
                        echo "python3-libcap.x86_64" >> packages.txt.fixed
                        ;;
                    python-pkg)
                        echo "python3-pkgconfig.x86_64" >> packages.txt.fixed
                        ;;
                    qemu-audio)
                        echo "qemu-audio-alsa.x86_64" >> packages.txt.fixed
                        ;;
                    qemu-block)
                        echo "qemu-block-iscsi.x86_64" >> packages.txt.fixed
                        ;;
                    qemu-char)
                        echo "qemu-char-pty.x86_64" >> packages.txt.fixed
                        ;;
                    qemu-device)
                        echo "qemu-device-usb.x86_64" >> packages.txt.fixed
                        ;;
                    qemu-system)
                        echo "qemu-system-x86.x86_64" >> packages.txt.fixed
                        ;;
                    qemu-ui)
                        echo "qemu-ui-gtk.x86_64" >> packages.txt.fixed
                        ;;
                    qt6-qtbase)
                        echo "qt6-qtbase-devel.x86_64" >> packages.txt.fixed
                        ;;
                    qt-avif)
                        echo "qt6-qtimageformats.x86_64" >> packages.txt.fixed
                        ;;
                    qt-jpegxl)
                        echo "qt6-qtimageformats.x86_64" >> packages.txt.fixed
                        ;;
                    qt-theme)
                        echo "qt6-qtbase-theme-gtk3.x86_64" >> packages.txt.fixed
                        ;;
                    rust-std)
                        echo "rust-std-static.x86_64" >> packages.txt.fixed
                        ;;
                    shared-mime)
                        echo "shared-mime-info.x86_64" >> packages.txt.fixed
                        ;;
                    vlc-plugin)
                        echo "vlc-plugin-qt.x86_64" >> packages.txt.fixed
                        ;;
                    x11-proto)
                        echo "xorg-x11-proto-devel.x86_64" >> packages.txt.fixed
                        ;;
                    xdg-dbus)
                        echo "xdg-dbus-proxy.x86_64" >> packages.txt.fixed
                        ;;
                    xdg-desktop)
                        echo "xdg-desktop-portal.x86_64" >> packages.txt.fixed
                        ;;
                    xdg-user)
                        echo "xdg-user-dirs.x86_64" >> packages.txt.fixed
                        ;;
                    *)
                        print_warning "  → No alternative found for: $package_name (removing)"
                        ((removed_count++))
                        ;;
                esac
                ((fixed_count++))
            else
                print_warning "  → No alternative found for: $package_name (removing)"
                ((removed_count++))
            fi
        fi
    done < packages.txt
    
    # Replace original with fixed version
    mv packages.txt.fixed packages.txt
    
    print_status "Package name fixing complete!"
    print_success "Fixed: $fixed_count packages"
    print_warning "Removed: $removed_count packages"
    print_status "Backup saved as packages.txt.backup"
}

# Main execution
main() {
    print_status "Starting package name fix for OpenMandriva..."
    echo
    
    fix_packages_txt
    
    print_status "Package name fix complete!"
    print_status "You can now test the installation script with corrected package names."
}

main "$@" 