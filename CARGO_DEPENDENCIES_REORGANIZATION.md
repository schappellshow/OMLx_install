# Cargo Dependencies Reorganization

## Changes Made

### 1. **Moved Cargo Dependencies to packages.txt**
- **Before**: All cargo dependencies were hardcoded in the install script (lines 135-175)
- **After**: Cargo dependencies are now in a dedicated section in `packages.txt`

### 2. **Benefits of This Approach**

#### **Cleaner Install Script**
- Removed 40+ lines of dependency management code
- Install script is now more focused on its core purpose
- Easier to read and maintain

#### **Better Organization**
- All system packages are now in one place (`packages.txt`)
- Cargo dependencies are clearly separated with their own section
- Easy to add new dependencies when adding new Rust applications

#### **Improved Maintainability**
- When adding new cargo applications, just add dependencies to `packages.txt`
- No need to modify the install script for dependency changes
- Consistent with how other packages are managed

### 3. **New Structure in packages.txt**

```bash
# =============================================================================
# CARGO BUILD DEPENDENCIES
# =============================================================================
# These packages are required for building Rust applications with cargo
# Add new cargo dependencies here when adding new Rust applications

# Core build tools
pkgconf.x86_64
lib64openssl-devel.x86_64
lib64z-devel.x86_64

# C/C++ development
lib64clang-devel.x86_64
lib64python3.11_1.x86_64

# Core libraries
lib64ffi-devel.x86_64
lib64xml2-devel.x86_64
lib64curl-devel.x86_64
lib64sqlite3-devel.x86_64
lib64pcre-devel.x86_64

# Image processing (for resvg)
lib64jpeg-devel.x86_64
lib64png-devel.x86_64
lib64tiff-devel.x86_64
lib64webp-devel.x86_64
lib64avif-devel.x86_64
lib64gif-devel.x86_64

# Graphics libraries (for resvg, yazi)
lib64freetype6-devel.x86_64
lib64fontconfig-devel.x86_64
lib64harfbuzz-devel.x86_64
lib64cairo-devel.x86_64
lib64pango1.0-devel.x86_64
lib64gdk_pixbuf2.0-devel.x86_64

# GUI libraries (for yazi)
lib64gtk+3.0-devel.x86_64
lib64glib2.0-devel.x86_64
lib64atspi-devel.x86_64
lib64gdk3_0.x86_64
lib64gdk-x11_2.0_0.x86_64

# X11 development (for GUI applications)
lib64x11-devel.x86_64
lib64xcb-devel.x86_64
lib64xrandr-devel.x86_64
lib64xinerama-devel.x86_64
lib64xcursor-devel.x86_64
lib64xfixes-devel.x86_64
lib64xrender-devel.x86_64
lib64xext-devel.x86_64

# Additional libraries
lib64uuid-devel.x86_64
lib64lzma-devel.x86_64
lib64bz2-devel.x86_64
lib64crypt-devel.x86_64
lib64mount-devel.x86_64
lib64seccomp-devel.x86_64
lib64systemd-devel.x86_64
```

### 4. **Simplified Install Script**

The cargo section in the install script is now much cleaner:

```bash
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
```

### 5. **How to Add New Cargo Applications**

#### **Step 1: Add the application to the install script**
```bash
# Add to the cargo_apps array
cargo_apps=("cargo-make" "cargo-update" "fd-find" "resvg" "ripgrep" "rust-script" "yazi-fm" "yazi-cli" "new-app")
```

#### **Step 2: Add dependencies to packages.txt**
If the new application needs additional system dependencies, add them to the cargo dependencies section in `packages.txt`.

### 6. **Advantages for Future Development**

- **Consistency**: All system packages managed in one place
- **Simplicity**: Install script focuses on application installation, not dependency management
- **Flexibility**: Easy to add/remove dependencies without touching the install script
- **Maintainability**: Clear separation of concerns between packages and applications 