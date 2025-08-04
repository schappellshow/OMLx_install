# Proton Pass Dependencies Reorganization

## Changes Made

### **1. Moved Dependencies to packages.txt**
- **Before**: 40+ Proton Pass dependencies were hardcoded in the install script
- **After**: All Proton Pass dependencies are now in a dedicated section in `packages.txt`

### **2. Benefits of This Approach**

#### **Cleaner Install Script**
- Removed 40+ lines of dependency management code
- Install script is now more focused on its core purpose
- Easier to read and maintain

#### **Better Organization**
- All system packages are now in one place (`packages.txt`)
- Proton Pass dependencies are clearly separated with their own section
- Easy to add new dependencies when Proton Pass updates

#### **Improved Maintainability**
- When Proton Pass needs new dependencies, just add them to `packages.txt`
- No need to modify the install script for dependency changes
- Consistent with how other packages are managed

### **3. New Structure in packages.txt**

```bash
# =============================================================================
# PROTON PASS DEPENDENCIES
# =============================================================================
# These packages are required for Proton Pass RPM installation
# Add new Proton Pass dependencies here if needed

# Core Proton Pass dependencies
libXtst.x86_64
gtk3.x86_64
libdrm.x86_64
mesa-libgbm.x86_64
at-spi2-core.x86_64

# X11 development libraries (for Proton Pass GUI)
libx11-devel.x86_64
libxcb-devel.x86_64
libxrandr-devel.x86_64
libxinerama-devel.x86_64
libxcursor-devel.x86_64
libxfixes-devel.x86_64
libxrender-devel.x86_64
libxext-devel.x86_64
libxcomposite-devel.x86_64
libxdamage-devel.x86_64
libxtst-devel.x86_64
libxi-devel.x86_64
libxkbcommon-devel.x86_64

# GUI libraries (for Proton Pass)
libgtk+3.0-devel.x86_64
libglib2.0-devel.x86_64
libatspi-devel.x86_64
libgdk3_0.x86_64
libgdk-x11_2.0_0.x86_64
libcairo-devel.x86_64
libpango1.0-devel.x86_64
libgdk_pixbuf2.0-devel.x86_64
libfreetype6-devel.x86_64
libfontconfig-devel.x86_64
libharfbuzz-devel.x86_64

# Additional Proton Pass dependencies
libssl-devel.x86_64
libz-devel.x86_64
libffi-devel.x86_64
libxml2-devel.x86_64
libcurl-devel.x86_64
libsqlite3-devel.x86_64
libpcre-devel.x86_64
libjpeg-devel.x86_64
libpng-devel.x86_64
libtiff-devel.x86_64
libwebp-devel.x86_64
libavif-devel.x86_64
libgif-devel.x86_64
libuuid-devel.x86_64
liblzma-devel.x86_64
libbz2-devel.x86_64
libcrypt-devel.x86_64
libmount-devel.x86_64
libseccomp-devel.x86_64
libsystemd-devel.x86_64
```

### **4. Simplified Install Script**

The Proton Pass section in the install script is now much cleaner:

```bash
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
    fi
    
    rm -f "$PROTON_PASS_FILE"
else
    print_error "Failed to download Proton Pass"
fi
```

### **5. How Dependencies Are Now Handled**

#### **Step 1: Package Installation (Early in Script)**
All Proton Pass dependencies are installed along with other packages from `packages.txt`:
```bash
# Install native packages from packages.txt
print_status "Installing native packages from $packages..."
while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
        # Extract package name (remove .x86_64 suffix)
        package_name="${line%.x86_64}"
        print_status "Installing: $package_name"
        sudo dnf install -y "$package_name" || {
            print_error "Failed to install $package_name"
        }
    fi
done < "$packages"
```

#### **Step 2: Proton Pass Installation (Later in Script)**
Proton Pass is installed with all dependencies already available:
```bash
# Proton Pass dependencies are now handled by packages.txt installation
print_status "Installing Proton Pass..."
```

### **6. Advantages for Future Development**

- **Consistency**: All system packages managed in one place
- **Simplicity**: Install script focuses on application installation, not dependency management
- **Flexibility**: Easy to add/remove dependencies without touching the install script
- **Maintainability**: Clear separation of concerns between packages and applications

### **7. How to Add New Proton Pass Dependencies**

#### **Step 1: Add to packages.txt**
If Proton Pass needs additional dependencies in the future, just add them to the Proton Pass dependencies section in `packages.txt`.

#### **Step 2: No Script Changes Needed**
The install script automatically handles all packages from `packages.txt`, so no changes are needed.

### **8. Testing the Changes**

#### **Verify Dependencies Are Installed**
```bash
# Check if Proton Pass dependencies are installed
dnf list installed | grep -E "(libXtst|gtk3|libdrm|mesa-libgbm|at-spi2-core)"
```

#### **Test Proton Pass Installation**
```bash
# Test the simplified installation
./test_install_script.sh rpms
```

### **9. Benefits Summary**

✅ **Cleaner Install Script**: Removed 40+ lines of dependency code
✅ **Better Organization**: All packages in one place
✅ **Easier Maintenance**: Add dependencies to packages.txt, not script
✅ **Consistent Approach**: Same pattern as cargo dependencies
✅ **Future-Proof**: Easy to add new dependencies

This reorganization makes your install script much cleaner and more maintainable, while keeping all the Proton Pass dependencies properly organized and easily accessible! 