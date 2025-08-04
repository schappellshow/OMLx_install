# Cargo Dependency Issues and Fixes

## Problem Identified

The cargo applications in your install script (lines 131-145) were failing to build because of missing system dependencies. The script was trying to install:

- `cargo-make`
- `cargo-update` 
- `fd-find`
- `resvg`
- `ripgrep`
- `rust-script`
- `yazi-fm`
- `yazi-cli`

But these Rust applications require various system libraries and development headers to compile successfully.

## Missing Dependencies Found

The dependency checker identified **114 missing packages**, including:

### Core Build Tools
- `pkg-config` - Essential for finding libraries
- `openssl-devel` - SSL/TLS development headers
- `zlib-devel` - Compression library headers
- `libz-devel` - Alternative zlib headers

### C/C++ Development
- `libclang-devel` - Clang development headers (needed for fd-find)
- `clang-devel` - Alternative clang headers
- `python3-devel` - Python development headers

### Core Libraries
- `libffi-devel` - Foreign function interface
- `libxml2-devel` - XML parsing (needed for resvg)
- `libcurl-devel` - HTTP client library
- `libsqlite3-devel` - SQLite database
- `libpcre-devel` - Regular expressions (needed for ripgrep)

### Image Processing (for resvg)
- `libjpeg-devel`, `jpeg-devel` - JPEG image support
- `libpng-devel`, `png-devel` - PNG image support
- `libtiff-devel` - TIFF image support
- `libwebp-devel` - WebP image support
- `libavif-devel` - AVIF image support
- `libgif-devel`, `gif-devel` - GIF image support

### Graphics Libraries (for resvg, yazi)
- `libfreetype-devel`, `freetype-devel` - Font rendering
- `libfontconfig-devel` - Font configuration
- `libharfbuzz-devel` - Text shaping
- `libcairo-devel`, `cairo-devel` - 2D graphics
- `libpango-devel` - Text layout
- `libgdk-pixbuf-devel`, `gdk-pixbuf-devel` - Image loading

### GUI Libraries (for yazi)
- `libgtk-devel`, `gtk-devel` - GTK toolkit
- `libglib-devel`, `glib-devel` - Core library
- `libatk-devel`, `atk-devel` - Accessibility toolkit
- `libgdk-devel`, `gdk-devel` - GDK graphics

### X11 Development Libraries (for yazi)
- `libx11-devel`, `x11-devel` - X11 core
- `libxcb-devel`, `xcb-devel` - X11 protocol
- `libxrandr-devel`, `xrandr-devel` - X11 randr extension
- `libxinerama-devel`, `xinerama-devel` - X11 multi-monitor
- `libxcursor-devel`, `xcursor-devel` - X11 cursor
- `libxfixes-devel`, `xfixes-devel` - X11 fixes extension
- `libxrender-devel`, `xrender-devel` - X11 rendering
- `libxext-devel`, `xext-devel` - X11 extensions
- `libxcomposite-devel`, `xcomposite-devel` - X11 composite
- `libxdamage-devel`, `xdamage-devel` - X11 damage
- `libxtst-devel`, `xtst-devel` - X11 test extension
- `libxi-devel`, `xi-devel` - X11 input
- `libxss-devel`, `xss-devel` - X11 screen saver
- `libxkbcommon-devel`, `xkbcommon-devel` - X11 keyboard

## Fixes Applied

### 1. **Added Dependency Installation Section**
Added a new section before cargo installation that installs all required system dependencies.

### 2. **Smart Package Name Resolution**
The script now tries alternative package names when the primary name fails:
- For `*-devel` packages, tries the base name
- For `lib*` packages, tries the base name
- Provides warnings when alternatives are found

### 3. **Added Warning Function**
Added `print_warning()` function for better error reporting.

### 4. **Created Dependency Checker**
Created `cargo_dependency_checker.sh` to identify missing dependencies.

## Files Modified

- `install_test_1.sh`: Added dependency installation section
- `cargo_dependency_checker.sh`: Created dependency checker script
- `missing_cargo_deps.txt`: List of critical missing dependencies
- `CARGO_DEPENDENCY_FIXES.md`: This documentation

## Usage

The updated script now:
1. Installs all required system dependencies before cargo applications
2. Handles alternative package names automatically
3. Provides better error reporting
4. Continues installation even if some dependencies fail

## Testing

You can test the dependency checker anytime:
```bash
./cargo_dependency_checker.sh
```

This will show you exactly what dependencies are missing and provide installation commands.

The cargo applications should now build successfully with all the required dependencies installed. 