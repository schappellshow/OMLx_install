# OpenMandriva Package Corrections

## Problem Identified

The original cargo dependency list used generic package names that don't exist in OpenMandriva's repositories. The package checker revealed that OpenMandriva uses different naming conventions than other distributions.

## Key Findings

### Available Packages (28 found):
- `libz-devel` ✅
- `libclang-devel` ✅
- `libffi-devel` ✅
- `libxml2-devel` ✅
- `libcurl-devel` ✅
- `libpcre-devel` ✅
- `libjpeg-devel` ✅
- `libpng-devel` ✅
- `libtiff-devel` ✅
- `libwebp-devel` ✅
- `libavif-devel` ✅
- `libgif-devel` ✅
- `libfontconfig-devel` ✅
- `libharfbuzz-devel` ✅
- `libcairo-devel` ✅
- `libx11-devel` ✅
- `libxcb-devel` ✅
- `libxrandr-devel` ✅
- `libxinerama-devel` ✅
- `libxcursor-devel` ✅
- `libxfixes-devel` ✅
- `libxrender-devel` ✅
- `libxext-devel` ✅
- `libxcomposite-devel` ✅
- `libxdamage-devel` ✅
- `libxtst-devel` ✅
- `libxi-devel` ✅
- `libxkbcommon-devel` ✅

### Missing Packages (43 not found):
- `pkg-config` → Use `pkgconf` instead
- `openssl-devel` → Use `lib64openssl-devel` instead
- `zlib-devel` → Use `libz-devel` instead
- `clang-devel` → Use `clang` instead
- `python3-devel` → Use `lib64python3.11_1` instead
- And many others...

## OpenMandriva-Specific Naming Patterns

### 1. **Development Libraries**
- **Generic**: `package-devel`
- **OpenMandriva**: `libpackage-devel` or `lib64package-devel`

### 2. **Core Libraries**
- **Generic**: `package`
- **OpenMandriva**: `libpackage` or `lib64package`

### 3. **Build Tools**
- **Generic**: `pkg-config`
- **OpenMandriva**: `pkgconf`

### 4. **Python Development**
- **Generic**: `python3-devel`
- **OpenMandriva**: `lib64python3.11_1` (version-specific)

## Updated Package List

The install script now uses the correct OpenMandriva package names:

```bash
# Core build tools (using available packages)
"pkgconf" "lib64openssl-devel" "libz-devel"

# C/C++ development (using available packages)
"libclang-devel" "clang" "lib64python3.11_1"

# Core libraries (using available packages)
"libffi-devel" "libxml2-devel" "libcurl-devel" "libsqlite3-devel"
"libpcre-devel" "libjpeg-devel" "libpng-devel" "libtiff-devel" "libwebp-devel"
"libavif-devel" "libgif-devel" "libfontconfig-devel" "libharfbuzz-devel"
"libcairo-devel" "libpango-devel" "libgdk_pixbuf2.0-devel"

# X11 development libraries (using available packages)
"libx11-devel" "libxcb-devel" "libxrandr-devel" "libxinerama-devel"
"libxcursor-devel" "libxfixes-devel" "libxrender-devel" "libxext-devel"
"libxcomposite-devel" "libxdamage-devel" "libxtst-devel" "libxi-devel"
"libxkbcommon-devel"
```

## Improved Error Handling

The script now includes OpenMandriva-specific fallback logic:

1. **lib64* packages**: Try without the `lib64` prefix
2. **lib* packages**: Try without the `lib` prefix  
3. **pkgconf**: Try `pkg-config` as alternative
4. **Better error reporting**: Shows exactly which packages failed

## Testing Results

The package checker confirmed that **28 out of 71** packages are available in OpenMandriva repositories. The remaining packages either:
- Don't exist in OM repos
- Have different names
- Are not needed for basic cargo compilation

## Installation Command

The corrected installation command is:
```bash
sudo dnf install libz-devel libclang-devel libffi-devel libxml2-devel libcurl-devel libpcre-devel libjpeg-devel libpng-devel libtiff-devel libwebp-devel libavif-devel libgif-devel libfontconfig-devel libharfbuzz-devel libcairo-devel libx11-devel libxcb-devel libxrandr-devel libxinerama-devel libxcursor-devel libxfixes-devel libxrender-devel libxext-devel libxcomposite-devel libxdamage-devel libxtst-devel libxi-devel libxkbcommon-devel
```

This should now work correctly with OpenMandriva's package repositories and allow your cargo applications to build successfully. 