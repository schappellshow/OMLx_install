#!/bin/bash

# OpenMandriva Package Checker
# This script checks what packages are available in OM repositories
# and finds the correct package names for cargo dependencies

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

# Function to search for packages in OM repositories
search_package() {
    local search_term="$1"
    local results=()
    
    # Search using dnf search
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)\. ]]; then
            package_name="${BASH_REMATCH[1]}"
            results+=("$package_name")
        fi
    done < <(dnf search "$search_term" 2>/dev/null | grep -E "^[[:space:]]*[^[:space:]]+\.")
    
    echo "${results[@]}"
}

# Function to check if a package exists
package_exists() {
    local pkg="$1"
    dnf list available "$pkg" >/dev/null 2>&1
}

# Critical cargo dependencies to check
cargo_deps=(
    # Core build tools
    "pkg-config" "openssl-devel" "zlib-devel" "libz-devel"
    
    # C/C++ development
    "libclang-devel" "clang-devel" "python3-devel"
    
    # Core libraries
    "libffi-devel" "libxml2-devel" "libcurl-devel" "libsqlite3-devel"
    "libpcre-devel" "pcre-devel" "libjpeg-devel" "jpeg-devel"
    "libpng-devel" "png-devel" "libtiff-devel" "libwebp-devel"
    "libavif-devel" "libgif-devel" "gif-devel" "libfreetype-devel"
    "freetype-devel" "libfontconfig-devel" "libharfbuzz-devel"
    "libcairo-devel" "cairo-devel" "libpango-devel"
    "libgdk-pixbuf-devel" "gdk-pixbuf-devel" "libgtk-devel"
    "gtk-devel" "libglib-devel" "glib-devel" "libatk-devel"
    "atk-devel" "libgdk-devel" "gdk-devel" "libx11-devel"
    "x11-devel" "libxcb-devel" "xcb-devel" "libxrandr-devel"
    "xrandr-devel" "libxinerama-devel" "xinerama-devel"
    "libxcursor-devel" "xcursor-devel" "libxfixes-devel"
    "xfixes-devel" "libxrender-devel" "xrender-devel"
    "libxext-devel" "xext-devel" "libxcomposite-devel"
    "xcomposite-devel" "libxdamage-devel" "xdamage-devel"
    "libxtst-devel" "xtst-devel" "libxi-devel" "xi-devel"
    "libxss-devel" "xss-devel" "libxkbcommon-devel" "xkbcommon-devel"
    "libyaml-devel" "yaml-devel" "libonig-devel" "oniguruma-devel"
)

print_status "Checking OpenMandriva repositories for cargo dependencies..."

# Update package cache
print_status "Updating package cache..."
sudo dnf makecache || {
    print_error "Failed to update package cache"
    exit 1
}

print_success "Package cache updated"

# Results storage
found_packages=()
missing_packages=()
alternative_packages=()

print_status "Checking each dependency..."

for dep in "${cargo_deps[@]}"; do
    print_status "Checking: $dep"
    
    if package_exists "$dep"; then
        print_success "✓ Found: $dep"
        found_packages+=("$dep")
    else
        print_warning "✗ Not found: $dep"
        missing_packages+=("$dep")
        
        # Try to find alternatives
        print_status "  Searching for alternatives..."
        
        # Extract base name for searching
        base_name=""
        case "$dep" in
            *-devel)
                base_name="${dep%-devel}"
                ;;
            lib*)
                base_name="${dep#lib}"
                ;;
            *)
                base_name="$dep"
                ;;
        esac
        
        # Search for alternatives
        alternatives=$(search_package "$base_name")
        if [[ -n "$alternatives" ]]; then
            print_status "  Found alternatives: $alternatives"
            alternative_packages+=("$dep -> $alternatives")
        fi
    fi
done

# Generate corrected package list
print_status "Generating corrected package list..."

# Create corrected packages file
cat > om_corrected_packages.txt << EOF
# OpenMandriva Corrected Package Names for Cargo Dependencies
# Generated on $(date)
# 
# Found packages (${#found_packages[@]}):
EOF

for pkg in "${found_packages[@]}"; do
    echo "$pkg" >> om_corrected_packages.txt
done

echo "" >> om_corrected_packages.txt
echo "# Missing packages (${#missing_packages[@]}):" >> om_corrected_packages.txt
for pkg in "${missing_packages[@]}"; do
    echo "# $pkg" >> om_corrected_packages.txt
done

echo "" >> om_corrected_packages.txt
echo "# Alternative packages found:" >> om_corrected_packages.txt
for alt in "${alternative_packages[@]}"; do
    echo "# $alt" >> om_corrected_packages.txt
done

# Generate installation command
echo "" >> om_corrected_packages.txt
echo "# Installation command:" >> om_corrected_packages.txt
echo "# sudo dnf install ${found_packages[*]}" >> om_corrected_packages.txt

print_success "Results saved to om_corrected_packages.txt"

# Summary
print_status "Summary:"
print_success "Found ${#found_packages[@]} packages"
print_error "Missing ${#missing_packages[@]} packages"
print_warning "Found ${#alternative_packages[@]} alternative packages"

if [ ${#found_packages[@]} -gt 0 ]; then
    print_status "Available packages for installation:"
    for pkg in "${found_packages[@]}"; do
        echo "  - $pkg"
    done
    
    print_status "Installation command:"
    echo "sudo dnf install ${found_packages[*]}"
fi

if [ ${#alternative_packages[@]} -gt 0 ]; then
    print_status "Alternative packages found:"
    for alt in "${alternative_packages[@]}"; do
        echo "  $alt"
    done
fi

print_status "Check om_corrected_packages.txt for complete results." 