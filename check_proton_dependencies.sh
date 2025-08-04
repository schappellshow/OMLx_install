#!/bin/bash

# Proton Pass Dependency Checker for OpenMandriva
# This script checks which Proton Pass dependencies are actually available

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

# Function to search for packages in OM repositories
search_package() {
    local search_term="$1"
    local results=()
    
    # Search using dnf search
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)\\. ]]; then
            local pkg_name="${BASH_REMATCH[1]}"
            if [[ "$pkg_name" == *"$search_term"* ]]; then
                results+=("$pkg_name")
            fi
        fi
    done < <(dnf search "$search_term" 2>/dev/null | head -20)
    
    echo "${results[@]}"
}

# Function to check if a package exists
check_package_exists() {
    local package="$1"
    local search_results=($(search_package "$package"))
    
    if [[ ${#search_results[@]} -gt 0 ]]; then
        print_success "✓ Found: $package"
        for result in "${search_results[@]}"; do
            echo "  - $result"
        done
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
        lib*)
            # Try without lib prefix
            alternatives+=("${package#lib}")
            # Try with lib64 prefix
            alternatives+=("lib64${package#lib}")
            ;;
        *-devel)
            # Try without -devel suffix
            alternatives+=("${package%-devel}")
            # Try with different devel patterns
            alternatives+=("${package%-devel}-devel")
            ;;
        gtk3)
            alternatives+=("gtk+3.0" "gtk3.0")
            ;;
        libdrm)
            alternatives+=("lib64drm" "drm")
            ;;
        mesa-libgbm)
            alternatives+=("libgbm" "lib64gbm")
            ;;
        at-spi2-core)
            alternatives+=("at-spi2" "atspi2")
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

# Proton Pass dependencies from packages.txt
proton_deps=(
    # Core Proton Pass dependencies
    "libXtst" "gtk3" "libdrm" "mesa-libgbm" "at-spi2-core"
    
    # X11 development libraries (for Proton Pass GUI)
    "libx11-devel" "libxcb-devel" "libxrandr-devel" "libxinerama-devel"
    "libxcursor-devel" "libxfixes-devel" "libxrender-devel" "libxext-devel"
    "libxcomposite-devel" "libxdamage-devel" "libxtst-devel" "libxi-devel"
    "libxkbcommon-devel"
    
    # GUI libraries (for Proton Pass)
    "libgtk+3.0-devel" "libglib2.0-devel" "libatspi-devel" "libgdk3_0"
    "libgdk-x11_2.0_0" "libcairo-devel" "libpango1.0-devel"
    "libgdk_pixbuf2.0-devel" "libfreetype6-devel" "libfontconfig-devel"
    "libharfbuzz-devel"
    
    # Additional Proton Pass dependencies
    "libssl-devel" "libz-devel" "libffi-devel" "libxml2-devel" "libcurl-devel"
    "libsqlite3-devel" "libpcre-devel" "libjpeg-devel" "libpng-devel"
    "libtiff-devel" "libwebp-devel" "libavif-devel" "libgif-devel"
    "libuuid-devel" "liblzma-devel" "libbz2-devel" "libcrypt-devel"
    "libmount-devel" "libseccomp-devel" "libsystemd-devel"
)

print_status "Checking Proton Pass dependencies in OpenMandriva repositories..."
echo

local found=0
local missing=0
local alternatives_found=0

for dep in "${proton_deps[@]}"; do
    print_status "Checking: $dep"
    
    if check_package_exists "$dep"; then
        ((found++))
    else
        ((missing++))
        print_warning "Package not found: $dep"
        if find_alternative "$dep"; then
            ((alternatives_found++))
        fi
    fi
    echo
done

print_status "Summary:"
print_success "Found: $found packages"
print_warning "Missing: $missing packages"
if [[ $alternatives_found -gt 0 ]]; then
    print_success "Found alternatives for: $alternatives_found packages"
fi

# Create corrected packages list
print_status "Creating corrected packages list..."
cat > proton_pass_corrected_deps.txt << EOF
# Proton Pass Dependencies - OpenMandriva Corrected
# Generated on $(date)
# 
# Found: $found packages
# Missing: $missing packages
# Alternatives found: $alternatives_found packages

EOF

print_status "Check proton_pass_corrected_deps.txt for the corrected dependency list."
print_status "You can use this to update your packages.txt file with the correct package names." 