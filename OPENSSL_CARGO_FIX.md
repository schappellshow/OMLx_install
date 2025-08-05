# OpenSSL Cargo Compilation Fix

## **🔍 Problem Identified**

The `cargo-update` installation was failing with OpenSSL-related errors:

```bash
warning: openssl-sys@0.9.109: Could not find directory of OpenSSL installation
error: failed to run custom build command for `openssl-sys v0.9.109`
Could not find openssl via pkg-config:
pkg-config exited with status code 1
```

## **🐛 Root Cause**

The `openssl-sys` crate requires OpenSSL development libraries to compile, but the cargo build process couldn't find them properly.

### **Specific Issues:**
1. **Missing OpenSSL Development Package:** `libopenssl-devel.x86_64` was not installed
2. **Environment Variables:** OpenSSL environment variables were not set for cargo builds
3. **pkg-config Configuration:** The build system couldn't locate OpenSSL via pkg-config

## **✅ Solutions Implemented**

### **1. Added Missing OpenSSL Development Package**

**Added to packages.txt:**
```bash
libopenssl-devel.x86_64
```

**Why this was needed:**
- OpenMandriva uses both `lib64openssl-devel.x86_64` and `libopenssl-devel.x86_64`
- The `openssl-sys` crate specifically looks for `libopenssl-devel`
- Both packages provide different components needed for compilation

### **2. Enhanced Cargo Installation Logic**

**Before (Original Script):**
```bash
# Basic cargo installation without OpenSSL configuration
cargo install --locked "$app"
```

**After (Improved Script):**
```bash
# Configure OpenSSL environment variables
export OPENSSL_DIR=$(pkg-config --variable=prefix openssl)
export OPENSSL_LIB_DIR=$(pkg-config --variable=libdir openssl)
export OPENSSL_INCLUDE_DIR=$(pkg-config --variable=includedir openssl)
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"

# Enhanced error handling for OpenSSL issues
if grep -q "openssl\|OpenSSL" "/tmp/cargo_${app}_install.log"; then
    # Retry with explicit OpenSSL configuration
    OPENSSL_DIR=$(pkg-config --variable=prefix openssl) \
    OPENSSL_LIB_DIR=$(pkg-config --variable=libdir openssl) \
    OPENSSL_INCLUDE_DIR=$(pkg-config --variable=includedir openssl) \
    cargo install --locked "$app"
fi
```

### **3. OpenSSL-Specific Error Detection**

The script now specifically detects OpenSSL-related errors and handles them:

```bash
# Check for OpenSSL issues specifically
if grep -q "openssl\|OpenSSL" "/tmp/cargo_${app}_install.log"; then
    print_warning "$app has OpenSSL issues - checking OpenSSL configuration..."
    
    # Verify OpenSSL is properly installed
    if ! pkg-config --exists openssl; then
        print_error "OpenSSL not found by pkg-config, installing development packages..."
        sudo dnf install -y libopenssl-devel.x86_64 lib64openssl-devel.x86_64
    fi
    
    # Retry with explicit OpenSSL environment variables
    print_status "Retrying $app with explicit OpenSSL configuration..."
    if OPENSSL_DIR=$(pkg-config --variable=prefix openssl) \
       OPENSSL_LIB_DIR=$(pkg-config --variable=libdir openssl) \
       OPENSSL_INCLUDE_DIR=$(pkg-config --variable=includedir openssl) \
       cargo install --locked "$app"; then
        print_success "$app installed successfully with explicit OpenSSL config"
    fi
fi
```

## **🔧 Technical Details**

### **OpenSSL Environment Variables**

The script now sets these critical environment variables:

```bash
export OPENSSL_DIR=$(pkg-config --variable=prefix openssl)
export OPENSSL_LIB_DIR=$(pkg-config --variable=libdir openssl)
export OPENSSL_INCLUDE_DIR=$(pkg-config --variable=includedir openssl)
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"
```

### **Package Dependencies**

**Required OpenSSL packages:**
- `lib64openssl-devel.x86_64` - 64-bit OpenSSL development libraries
- `libopenssl-devel.x86_64` - OpenSSL development libraries (cargo-specific)

### **pkg-config Configuration**

The script ensures pkg-config can find OpenSSL:

```bash
# Verify OpenSSL is accessible via pkg-config
pkg-config --libs --cflags openssl
# Expected output: -lssl -lcrypto
```

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
[INFO] Configuring OpenSSL for cargo builds...
[INFO] OpenSSL configuration:
[INFO]   OPENSSL_DIR: /usr
[INFO]   OPENSSL_LIB_DIR: /usr/lib64
[INFO]   OPENSSL_INCLUDE_DIR: /usr/include
[INFO] Installing cargo app: cargo-update
[SUCCESS] cargo-update installed successfully
```

## **🧪 Testing Recommendations**

### **1. Test OpenSSL Configuration**
```bash
# Verify OpenSSL is properly configured
pkg-config --libs --cflags openssl

# Check if OpenSSL development packages are installed
dnf list installed | grep openssl
```

### **2. Test Cargo OpenSSL Build**
```bash
# Test a simple OpenSSL-dependent cargo build
cargo install --locked cargo-update
```

### **3. Test the Full Script**
```bash
# Test the improved install script
./install_test_1.sh
```

## **📋 Affected Cargo Applications**

The following cargo applications are likely to benefit from this fix:

### **✅ Applications with OpenSSL Dependencies:**
- **`cargo-update`** - Direct OpenSSL dependency
- **`fd-find`** - May use OpenSSL for certain features
- **`ripgrep`** - May use OpenSSL for certain features
- **`yazi-fm`** - May use OpenSSL for network features

### **✅ Applications That Should Work Better:**
- **`cargo-make`** - Build system tool
- **`resvg`** - SVG renderer
- **`rust-script`** - Rust scripting tool
- **`yazi-cli`** - Terminal file manager

## **🔍 Troubleshooting**

### **If OpenSSL Issues Persist:**

#### **1. Check OpenSSL Installation**
```bash
# Verify OpenSSL development packages
sudo dnf install -y libopenssl-devel.x86_64 lib64openssl-devel.x86_64

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

# Test cargo installation
cargo install --locked cargo-update
```

#### **3. Alternative Installation Methods**
```bash
# Try with system OpenSSL
OPENSSL_NO_PKG_CONFIG=1 cargo install --locked cargo-update

# Try with vendored OpenSSL
cargo install --locked cargo-update --features vendored-openssl
```

## **📝 Summary**

### **✅ What's Fixed:**
1. **Missing OpenSSL development package** - Added `libopenssl-devel.x86_64`
2. **Environment variable configuration** - Set OpenSSL paths for cargo builds
3. **OpenSSL-specific error handling** - Detects and retries OpenSSL issues
4. **pkg-config configuration** - Ensures proper OpenSSL detection

### **🎯 Benefits:**
- **Reliable cargo compilation** - OpenSSL-dependent crates will build successfully
- **Better error handling** - Specific handling for OpenSSL issues
- **Automatic retry logic** - Retries failed builds with proper OpenSSL configuration
- **Detailed logging** - Shows OpenSSL configuration and build progress

### **🚀 Expected Improvements:**
- **`cargo-update`** should install successfully
- **Other OpenSSL-dependent crates** should build without issues
- **Better error messages** for OpenSSL-related problems
- **Automatic fallback** to explicit OpenSSL configuration

This fix should resolve the OpenSSL compilation issues you're experiencing with cargo applications! 🎉 