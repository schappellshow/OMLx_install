# Espanso Cargo Build Fix

## **🔍 Problem Identified**

Espanso uses `cargo build` to compile from source, but it was missing the OpenSSL configuration that we added to the separate cargo installation script.

## **🐛 Root Cause**

### **Espanso Build Process:**
```bash
# Espanso uses cargo to build
cargo build -p espanso --release --no-default-features --features vendored-tls,modulo
```

### **Missing Dependencies:**
- **OpenSSL development packages** weren't installed before espanso build
- **OpenSSL environment variables** weren't set for espanso cargo build
- **pkg-config configuration** wasn't available for espanso build

## **✅ Solution Implemented**

### **1. Added OpenSSL Dependencies for Espanso**

**Added to espanso installation section:**
```bash
# Install OpenSSL development dependencies for espanso cargo build
print_status "Installing espanso OpenSSL dependencies..."
sudo dnf install -y libopenssl-devel.x86_64 lib64openssl-devel.x86_64 || {
    print_warning "Some OpenSSL dependencies failed to install"
}
```

### **2. Added OpenSSL Configuration for Espanso**

**Added OpenSSL environment variables:**
```bash
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
```

## **🔧 Technical Details**

### **Why This Was Needed:**

#### **1. Espanso Cargo Build**
Espanso is a Rust application that uses cargo to compile from source:
```bash
cargo build -p espanso --release --no-default-features --features vendored-tls,modulo
```

#### **2. OpenSSL Dependencies**
Espanso uses OpenSSL for TLS/SSL functionality:
- **`vendored-tls`** feature requires OpenSSL development libraries
- **`modulo`** feature may also use OpenSSL for certain operations

#### **3. Build Timing**
Espanso is built in the main script (before the optional cargo applications section), so it needed its own OpenSSL configuration.

### **Dependencies Required:**

#### **OpenSSL Development Packages:**
- **`libopenssl-devel.x86_64`** - OpenSSL development libraries
- **`lib64openssl-devel.x86_64`** - 64-bit OpenSSL development libraries

#### **X11 Development Packages (already present):**
- **`lib64x11-devel.x86_64`** - X11 development libraries
- **`lib64xkbcommon-devel.x86_64`** - XKB common development libraries
- **`lib64xrandr-devel.x86_64`** - XRandR development libraries

#### **Environment Variables:**
- **`OPENSSL_DIR`** - OpenSSL installation directory
- **`OPENSSL_LIB_DIR`** - OpenSSL library directory
- **`OPENSSL_INCLUDE_DIR`** - OpenSSL include directory
- **`PKG_CONFIG_PATH`** - pkg-config search path

## **🎯 Expected Results**

### **Before Fix:**
```bash
warning: openssl-sys@0.9.109: Could not find directory of OpenSSL installation
error: failed to run custom build command for `openssl-sys v0.9.109`
Could not find openssl via pkg-config:
pkg-config exited with status code 1
```

### **After Fix:**
```bash
[INFO] Installing espanso OpenSSL dependencies...
[INFO] Configuring OpenSSL for espanso build...
[INFO] OpenSSL configuration for espanso:
[INFO]   OPENSSL_DIR: /usr
[INFO]   OPENSSL_LIB_DIR: /usr/lib64
[INFO]   OPENSSL_INCLUDE_DIR: /usr/include
[INFO] Cloning espanso repository...
[INFO] Building espanso with cargo...
[SUCCESS] Espanso build completed successfully
```

## **🧪 Testing Recommendations**

### **1. Test Espanso Build**
```bash
# Test espanso build with OpenSSL configuration
cd ~/espanso
OPENSSL_DIR=$(pkg-config --variable=prefix openssl) \
OPENSSL_LIB_DIR=$(pkg-config --variable=libdir openssl) \
OPENSSL_INCLUDE_DIR=$(pkg-config --variable=includedir openssl) \
cargo build -p espanso --release --no-default-features --features vendored-tls,modulo
```

### **2. Test Full Script**
```bash
# Test the improved install script
./install_test_1.sh
```

### **3. Verify Espanso Installation**
```bash
# Check if espanso binary was installed
which espanso

# Check if espanso service is registered
espanso service status

# Test espanso functionality
espanso --version
```

## **📋 Installation Order**

### **Current Installation Sequence:**
1. **System updates and essential dependencies** (including cargo)
2. **Native packages** (from packages.txt)
3. **Flatpak applications**
4. **Python applications**
5. **Individual RPM packages**
6. **Git-based projects** (including espanso with OpenSSL config)
7. **Oh My Zsh installation**
8. **Dotfiles setup**
9. **Cargo applications** (optional, with prompt)

### **Espanso Build Process:**
1. **Install X11 dependencies** for GUI functionality
2. **Install OpenSSL dependencies** for cargo build
3. **Configure OpenSSL environment** for cargo
4. **Clone espanso repository**
5. **Build with cargo** using OpenSSL configuration
6. **Install binary** to `/usr/local/bin/espanso`
7. **Register systemd service**
8. **Start espanso**

## **🔍 Troubleshooting**

### **If Espanso Build Still Fails:**

#### **1. Check OpenSSL Installation**
```bash
# Verify OpenSSL development packages
dnf list installed | grep openssl

# Check pkg-config configuration
pkg-config --libs --cflags openssl
```

#### **2. Manual OpenSSL Configuration**
```bash
# Set OpenSSL environment variables manually
export OPENSSL_DIR=/usr
export OPENSSL_LIB_DIR=/usr/lib64
export OPENSSL_INCLUDE_DIR=/usr/include
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"

# Test espanso build
cd ~/espanso
cargo build -p espanso --release --no-default-features --features vendored-tls,modulo
```

#### **3. Alternative Installation Methods**
```bash
# Try with vendored OpenSSL
cargo build -p espanso --release --no-default-features --features vendored-tls,modulo

# Try with system OpenSSL
OPENSSL_NO_PKG_CONFIG=1 cargo build -p espanso --release --no-default-features --features vendored-tls,modulo
```

## **📝 Summary**

### **✅ What's Fixed:**
1. **OpenSSL dependencies** - Added required development packages
2. **Environment configuration** - Set OpenSSL paths for espanso build
3. **Build timing** - OpenSSL config available when espanso builds
4. **Error prevention** - Prevents OpenSSL-related build failures

### **🎯 Benefits:**
- **Reliable espanso build** - OpenSSL dependencies available
- **Consistent configuration** - Same OpenSSL setup as cargo apps
- **Better error handling** - Clear OpenSSL configuration logging
- **Successful compilation** - espanso should build without OpenSSL errors

### **🚀 Expected Improvements:**
- **Espanso builds successfully** without OpenSSL errors
- **Consistent cargo builds** across main script and cargo script
- **Better error messages** if OpenSSL issues occur
- **Reliable espanso installation** and service registration

This fix ensures that espanso has all the necessary OpenSSL dependencies and configuration to build successfully! 🎉 