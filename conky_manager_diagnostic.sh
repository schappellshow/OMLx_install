#!/bin/bash

# Conky Manager 2 Diagnostic for OpenMandriva
# This script identifies and fixes conky-manager2 build issues

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

# Function to check conky-manager2 dependencies
check_conky_dependencies() {
    print_status "Checking conky-manager2 dependencies..."
    echo
    
    # Common dependencies for conky-manager2
    local conky_deps=(
        "conky"              # Main conky package
        "conky-devel"        # Development files
        "gtk3"              # GTK3 for GUI
        "gtk3-devel"        # GTK3 development files
        "glib2"             # GLib library
        "glib2-devel"       # GLib development files
        "pkgconf"           # Package configuration
        "make"              # Build tool
        "gcc"               # C compiler
        "cmake"             # Build system (if needed)
        "python3"           # Python 3 (if needed)
        "python3-devel"     # Python 3 development files
        "python3-gi"        # Python GObject introspection
        "python3-gi-devel"  # Python GObject introspection development
        "gir1.2-gtk-3.0"   # GObject introspection for GTK3
        "gir1.2-glib-2.0"  # GObject introspection for GLib
    )
    
    local found=0
    local missing=0
    
    for dep in "${conky_deps[@]}"; do
        print_status "Checking: $dep"
        if check_package "$dep"; then
            ((found++))
        else
            ((missing++))
        fi
        echo
    done
    
    print_status "Conky dependencies summary:"
    print_success "Found: $found packages"
    print_warning "Missing: $missing packages"
    echo
}

# Function to check OpenMandriva-specific packages
check_om_conky_deps() {
    print_status "Checking OpenMandriva-specific conky packages..."
    echo
    
    local om_conky_deps=(
        "conky.x86_64"
        "conky-devel.x86_64"
        "lib64gtk3_0.x86_64"
        "lib64gtk+3.0-devel.x86_64"
        "lib64glib2.0.x86_64"
        "lib64glib2.0-devel.x86_64"
        "pkgconf.x86_64"
        "make.x86_64"
        "gcc.x86_64"
        "cmake.x86_64"
        "python3.x86_64"
        "python3-devel.x86_64"
        "python3-gi.x86_64"
        "python3-gi-devel.x86_64"
        "lib64girara-gtk3_3.x86_64"
        "lib64girara-gtk3-devel.x86_64"
    )
    
    local found=0
    local missing=0
    
    for dep in "${om_conky_deps[@]}"; do
        print_status "Checking: $dep"
        if check_package "$dep"; then
            ((found++))
        else
            ((missing++))
        fi
        echo
    done
    
    print_status "OpenMandriva conky dependencies summary:"
    print_success "Found: $found packages"
    print_warning "Missing: $missing packages"
    echo
}

# Function to test conky-manager2 build
test_conky_build() {
    print_status "Testing conky-manager2 build process..."
    echo
    
    # Create temporary directory for testing
    local test_dir="/tmp/conky-manager2-test-$(date +%s)"
    
    print_status "Cloning conky-manager2 for testing..."
    if git clone "https://github.com/zcot/conky-manager2.git" "$test_dir"; then
        print_success "Successfully cloned conky-manager2"
        
        cd "$test_dir" || {
            print_error "Failed to change to test directory"
            return 1
        }
        
        # Check if Makefile exists
        if [[ -f "Makefile" ]]; then
            print_success "Makefile found"
            
            # Check Makefile contents for dependencies
            print_status "Analyzing Makefile for dependencies..."
            if grep -q "pkg-config" Makefile; then
                print_warning "Makefile uses pkg-config - checking for pkg-config dependencies"
                grep "pkg-config" Makefile
            fi
            
            if grep -q "python" Makefile; then
                print_warning "Makefile uses Python - checking for Python dependencies"
                grep "python" Makefile
            fi
            
            if grep -q "gtk" Makefile; then
                print_warning "Makefile uses GTK - checking for GTK dependencies"
                grep "gtk" Makefile
            fi
            
            # Try to run make with verbose output
            print_status "Attempting to build conky-manager2..."
            if make V=1 2>&1 | tee "/tmp/conky-build.log"; then
                print_success "Conky-manager2 built successfully"
            else
                print_error "Conky-manager2 build failed"
                print_status "Build log saved to /tmp/conky-build.log"
                
                # Analyze build errors
                if grep -q "pkg-config" "/tmp/conky-build.log"; then
                    print_warning "Build failed due to pkg-config issues"
                fi
                
                if grep -q "gtk" "/tmp/conky-build.log"; then
                    print_warning "Build failed due to GTK issues"
                fi
                
                if grep -q "python" "/tmp/conky-build.log"; then
                    print_warning "Build failed due to Python issues"
                fi
                
                if grep -q "conky" "/tmp/conky-build.log"; then
                    print_warning "Build failed due to conky library issues"
                fi
            fi
        else
            print_error "Makefile not found in conky-manager2 repository"
        fi
        
        # Return to original directory
        cd - > /dev/null
        
        # Clean up
        rm -rf "$test_dir"
    else
        print_error "Failed to clone conky-manager2 repository"
    fi
    
    echo
}

# Function to generate fix recommendations
generate_conky_fixes() {
    print_status "Generating conky-manager2 fix recommendations..."
    echo
    
    cat > conky_manager_fixes.txt << 'EOF'
# Conky Manager 2 Fixes for OpenMandriva
# Generated on $(date)

# =============================================================================
# MISSING PACKAGES TO INSTALL
# =============================================================================

# Essential conky-manager2 dependencies
conky.x86_64
conky-devel.x86_64
lib64gtk3_0.x86_64
lib64gtk+3.0-devel.x86_64
lib64glib2.0.x86_64
lib64glib2.0-devel.x86_64
pkgconf.x86_64
make.x86_64
gcc.x86_64
cmake.x86_64

# Python dependencies (if needed)
python3.x86_64
python3-devel.x86_64
python3-gi.x86_64
python3-gi-devel.x86_64

# GObject introspection dependencies
lib64girara-gtk3_3.x86_64
lib64girara-gtk3-devel.x86_64

# =============================================================================
# COMMANDS TO RUN
# =============================================================================

# Install conky-manager2 dependencies
sudo dnf install -y conky.x86_64 conky-devel.x86_64 lib64gtk3_0.x86_64 lib64gtk+3.0-devel.x86_64 lib64glib2.0.x86_64 lib64glib2.0-devel.x86_64 pkgconf.x86_64 make.x86_64 gcc.x86_64 cmake.x86_64

# Install Python dependencies (if needed)
sudo dnf install -y python3.x86_64 python3-devel.x86_64 python3-gi.x86_64 python3-gi-devel.x86_64

# Install GObject introspection dependencies
sudo dnf install -y lib64girara-gtk3_3.x86_64 lib64girara-gtk3-devel.x86_64

# =============================================================================
# ALTERNATIVE INSTALLATION METHODS
# =============================================================================

# Method 1: Install from repository (if available)
sudo dnf install -y conky-manager2

# Method 2: Build with specific flags
cd ~/conky-manager2
make clean
make CFLAGS="-I/usr/include/gtk-3.0 -I/usr/include/glib-2.0 -I/usr/include/cairo -I/usr/include/pango-1.0 -I/usr/include/atk-1.0 -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/gio-unix-2.0/ -I/usr/include/gdk-pixbuf-2.0"
sudo make install

# Method 3: Use alternative conky manager
# Consider using conky-manager or other alternatives if conky-manager2 fails

# =============================================================================
# VERIFICATION STEPS
# =============================================================================

# Check if conky is installed
rpm -qa | grep conky

# Check if GTK3 development files are available
pkg-config --exists gtk+-3.0 && echo "GTK3 development files found" || echo "GTK3 development files missing"

# Check if conky-manager2 builds
cd ~/conky-manager2 && make clean && make

EOF

    print_success "Generated conky_manager_fixes.txt with detailed fix instructions"
}

# Main execution
main() {
    print_status "Starting Conky Manager 2 Diagnostic for OpenMandriva..."
    echo
    
    check_conky_dependencies
    check_om_conky_deps
    test_conky_build
    generate_conky_fixes
    
    print_status "Diagnostic complete! Check conky_manager_fixes.txt for solutions."
}

main "$@" 