#!/bin/bash

# Cargo Dependency Checker for OpenMandriva
# This script checks what system dependencies are needed for cargo applications

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

# Cargo applications from your script
cargo_apps=("cargo-make" "cargo-update" "fd-find" "resvg" "ripgrep" "rust-script" "yazi-fm" "yazi-cli")

# Common Rust/Cargo dependencies that are often needed
common_deps=(
    "gcc" "gcc-c++" "make" "cmake" "pkg-config"
    "openssl-devel" "libssl-devel" "zlib-devel" "libz-devel"
    "libclang-devel" "clang-devel" "llvm-devel"
    "python3-devel" "python-devel"
    "libffi-devel" "libffi"
    "libxml2-devel" "libxml2"
    "libcurl-devel" "curl-devel"
    "libsqlite3-devel" "sqlite-devel"
    "libdb-devel" "db-devel"
    "libpcre-devel" "pcre-devel"
    "libonig-devel" "oniguruma-devel"
    "libyaml-devel" "yaml-devel"
    "libjpeg-devel" "jpeg-devel"
    "libpng-devel" "png-devel"
    "libtiff-devel" "tiff-devel"
    "libwebp-devel" "webp-devel"
    "libavif-devel" "avif-devel"
    "libheif-devel" "heif-devel"
    "libgif-devel" "gif-devel"
    "libfreetype-devel" "freetype-devel"
    "libfontconfig-devel" "fontconfig-devel"
    "libharfbuzz-devel" "harfbuzz-devel"
    "libcairo-devel" "cairo-devel"
    "libpango-devel" "pango-devel"
    "libgtk-devel" "gtk-devel"
    "libglib-devel" "glib-devel"
    "libgdk-pixbuf-devel" "gdk-pixbuf-devel"
    "libatk-devel" "atk-devel"
    "libgdk-devel" "gdk-devel"
    "libx11-devel" "x11-devel"
    "libxcb-devel" "xcb-devel"
    "libxrandr-devel" "xrandr-devel"
    "libxinerama-devel" "xinerama-devel"
    "libxcursor-devel" "xcursor-devel"
    "libxfixes-devel" "xfixes-devel"
    "libxrender-devel" "xrender-devel"
    "libxext-devel" "xext-devel"
    "libxcomposite-devel" "xcomposite-devel"
    "libxdamage-devel" "xdamage-devel"
    "libxtst-devel" "xtst-devel"
    "libxi-devel" "xi-devel"
    "libxrandr-devel" "xrandr-devel"
    "libxss-devel" "xss-devel"
    "libxkbcommon-devel" "xkbcommon-devel"
    "libwayland-devel" "wayland-devel"
    "libdrm-devel" "drm-devel"
    "libgbm-devel" "gbm-devel"
    "libvulkan-devel" "vulkan-devel"
    "libalsa-devel" "alsa-devel"
    "libpulse-devel" "pulseaudio-devel"
    "libjack-devel" "jack-devel"
    "libsndfile-devel" "sndfile-devel"
    "libogg-devel" "ogg-devel"
    "libvorbis-devel" "vorbis-devel"
    "libflac-devel" "flac-devel"
    "libmp3lame-devel" "lame-devel"
    "libopus-devel" "opus-devel"
    "libspeex-devel" "speex-devel"
    "libtheora-devel" "theora-devel"
    "libvpx-devel" "vpx-devel"
    "libx264-devel" "x264-devel"
    "libx265-devel" "x265-devel"
    "libavcodec-devel" "ffmpeg-devel"
    "libavformat-devel" "ffmpeg-devel"
    "libavutil-devel" "ffmpeg-devel"
    "libswscale-devel" "ffmpeg-devel"
    "libswresample-devel" "ffmpeg-devel"
    "libavfilter-devel" "ffmpeg-devel"
    "libavdevice-devel" "ffmpeg-devel"
    "libpostproc-devel" "ffmpeg-devel"
    "libass-devel" "ass-devel"
    "libfribidi-devel" "fribidi-devel"
    "libfontconfig-devel" "fontconfig-devel"
    "libfreetype-devel" "freetype-devel"
    "libharfbuzz-devel" "harfbuzz-devel"
    "libpango-devel" "pango-devel"
    "libcairo-devel" "cairo-devel"
    "libgdk-pixbuf-devel" "gdk-pixbuf-devel"
    "libgtk-devel" "gtk-devel"
    "libglib-devel" "glib-devel"
    "libatk-devel" "atk-devel"
    "libgdk-devel" "gdk-devel"
    "libx11-devel" "x11-devel"
    "libxcb-devel" "xcb-devel"
    "libxrandr-devel" "xrandr-devel"
    "libxinerama-devel" "xinerama-devel"
    "libxcursor-devel" "xcursor-devel"
    "libxfixes-devel" "xfixes-devel"
    "libxrender-devel" "xrender-devel"
    "libxext-devel" "xext-devel"
    "libxcomposite-devel" "xcomposite-devel"
    "libxdamage-devel" "xdamage-devel"
    "libxtst-devel" "xtst-devel"
    "libxi-devel" "xi-devel"
    "libxrandr-devel" "xrandr-devel"
    "libxss-devel" "xss-devel"
    "libxkbcommon-devel" "xkbcommon-devel"
    "libwayland-devel" "wayland-devel"
    "libdrm-devel" "drm-devel"
    "libgbm-devel" "gbm-devel"
    "libvulkan-devel" "vulkan-devel"
    "libalsa-devel" "alsa-devel"
    "libpulse-devel" "pulseaudio-devel"
    "libjack-devel" "jack-devel"
    "libsndfile-devel" "sndfile-devel"
    "libogg-devel" "ogg-devel"
    "libvorbis-devel" "vorbis-devel"
    "libflac-devel" "flac-devel"
    "libmp3lame-devel" "lame-devel"
    "libopus-devel" "opus-devel"
    "libspeex-devel" "speex-devel"
    "libtheora-devel" "theora-devel"
    "libvpx-devel" "vpx-devel"
    "libx264-devel" "x264-devel"
    "libx265-devel" "x265-devel"
    "libavcodec-devel" "ffmpeg-devel"
    "libavformat-devel" "ffmpeg-devel"
    "libavutil-devel" "ffmpeg-devel"
    "libswscale-devel" "ffmpeg-devel"
    "libswresample-devel" "ffmpeg-devel"
    "libavfilter-devel" "ffmpeg-devel"
    "libavdevice-devel" "ffmpeg-devel"
    "libpostproc-devel" "ffmpeg-devel"
    "libass-devel" "ass-devel"
    "libfribidi-devel" "fribidi-devel"
)

# Function to check if a package is installed
check_package() {
    local pkg="$1"
    if rpm -q "$pkg" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to find alternative package names
find_alternative() {
    local pkg="$1"
    local alternatives=()
    
    # Common alternative patterns
    case "$pkg" in
        *-devel)
            base="${pkg%-devel}"
            alternatives+=("$base" "lib64${base}" "lib${base}")
            ;;
        lib64*)
            base="${pkg#lib64}"
            alternatives+=("$base" "lib$base" "${base}-devel")
            ;;
        lib*)
            base="${pkg#lib}"
            alternatives+=("$base" "lib64$base" "${base}-devel")
            ;;
        *)
            alternatives+=("lib64$pkg" "lib$pkg" "${pkg}-devel")
            ;;
    esac
    
    for alt in "${alternatives[@]}"; do
        if check_package "$alt"; then
            echo "$alt"
            return 0
        fi
    done
    return 1
}

print_status "Checking system dependencies for cargo applications..."

# Check what's already installed from packages.txt
print_status "Checking currently installed packages..."
installed_packages=()
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # Extract package name (remove version info)
    pkg_name=$(echo "$line" | awk '{print $1}' | cut -d'-' -f1-2)
    installed_packages+=("$pkg_name")
done < packages.txt

print_success "Found ${#installed_packages[@]} installed packages"

# Check common dependencies
print_status "Checking common Rust/Cargo dependencies..."
missing_deps=()

for dep in "${common_deps[@]}"; do
    if ! check_package "$dep"; then
        # Try to find alternative package name
        if alt_pkg=$(find_alternative "$dep"); then
            print_warning "Package '$dep' not found, but found alternative: $alt_pkg"
        else
            missing_deps+=("$dep")
            print_error "Missing dependency: $dep"
        fi
    else
        print_success "Found: $dep"
    fi
done

# Specific dependencies for each cargo application
print_status "Checking specific dependencies for each cargo application..."

# cargo-make dependencies
print_status "cargo-make dependencies:"
cargo_make_deps=("make" "cmake" "pkg-config" "openssl-devel")
for dep in "${cargo_make_deps[@]}"; do
    if ! check_package "$dep"; then
        missing_deps+=("$dep")
        print_error "Missing for cargo-make: $dep"
    fi
done

# fd-find dependencies
print_status "fd-find dependencies:"
fd_deps=("libclang-devel" "clang-devel")
for dep in "${fd_deps[@]}"; do
    if ! check_package "$dep"; then
        missing_deps+=("$dep")
        print_error "Missing for fd-find: $dep"
    fi
done

# resvg dependencies
print_status "resvg dependencies:"
resvg_deps=("libxml2-devel" "libcairo-devel" "libpango-devel" "libgdk-pixbuf-devel")
for dep in "${resvg_deps[@]}"; do
    if ! check_package "$dep"; then
        missing_deps+=("$dep")
        print_error "Missing for resvg: $dep"
    fi
done

# ripgrep dependencies
print_status "ripgrep dependencies:"
ripgrep_deps=("pcre-devel" "libpcre-devel")
for dep in "${ripgrep_deps[@]}"; do
    if ! check_package "$dep"; then
        missing_deps+=("$dep")
        print_error "Missing for ripgrep: $dep"
    fi
done

# yazi dependencies
print_status "yazi dependencies:"
yazi_deps=("libx11-devel" "libxcb-devel" "libxrandr-devel" "libxinerama-devel" "libxcursor-devel" "libxfixes-devel" "libxrender-devel" "libxext-devel" "libxcomposite-devel" "libxdamage-devel" "libxtst-devel" "libxi-devel" "libxrandr-devel" "libxss-devel" "libxkbcommon-devel")
for dep in "${yazi_deps[@]}"; do
    if ! check_package "$dep"; then
        missing_deps+=("$dep")
        print_error "Missing for yazi: $dep"
    fi
done

# Remove duplicates from missing_deps
missing_deps=($(printf "%s\n" "${missing_deps[@]}" | sort -u))

print_status "Summary:"
if [ ${#missing_deps[@]} -eq 0 ]; then
    print_success "All dependencies appear to be installed!"
else
    print_error "Missing dependencies (${#missing_deps[@]}):"
    for dep in "${missing_deps[@]}"; do
        echo "  - $dep"
    done
    
    print_status "To install missing dependencies, run:"
    echo "sudo dnf install ${missing_deps[*]}"
fi

print_status "Note: Some packages might have different names in OpenMandriva."
print_status "If installation still fails, try searching for alternative package names." 