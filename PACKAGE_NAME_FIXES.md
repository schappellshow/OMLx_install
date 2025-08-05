# Package Name Fixes for OpenMandriva

## **Problem Identified**

The packages.txt file contains many generic package names that don't match OpenMandriva's actual package naming conventions, causing "No match for argument" errors during installation.

## **Root Cause**

The packages.txt file was generated from a different system or uses generic package names that don't exist in OpenMandriva repositories.

## **Packages That Need Fixing**

### **❌ Packages Not Found (Need Removal or Correction):**

#### **1. AT-SPI Packages**
- **`at-spi2`** → **`at-spi2-core`** (already fixed)

#### **2. Icon Theme Packages**
- **`adwaita-icon`** → **`adwaita-icon-theme`** (already fixed)

#### **3. AppStream Packages**
- **`appstream-glib`** → **`appstream-glib-i18n`** (already exists)

#### **4. Bat Completion Packages**
- **`bat-bash`** → **`bat-bash-completion`** (already exists)
- **`bat-zsh`** → **`bat-zsh-completion`** (already exists)

#### **5. CMake Packages**
- **`extra-cmake`** → **`extra-cmake-modules`** (already exists)

#### **6. Font Packages**
- **`fonts-ttf`** → **`fonts-ttf-bitstream-vera`** (already exists)

#### **7. Avahi Packages**
- **`lib64avahi-client`** → **`lib64avahi-client-devel`** (already exists)
- **`lib64avahi-common`** → **`lib64avahi-common-devel`** (already exists)

#### **8. GTK4 Layer Shell**
- **`lib64gtk4-layer`** → **`lib64gtk4-layer-shell`** (if exists)

#### **9. GTK Source View**
- **`lib64gtksourceview`** → **`gtksourceview`** (already exists)

#### **10. GTK VNC**
- **`lib64gtk-vnc`** → **`gtk-vnc-common`** (already exists)

#### **11. Harfbuzz GIR**
- **`lib64harfbuzz-gir`** → **`lib64harfbuzz-gir0.0`** (if exists)

#### **12. JSON GLib**
- **`lib64json-glib`** → **`lib64json-glib-devel`** (if exists)

#### **13. LuaJIT**
- **`lib64luajit`** → **`luajit`** (if exists)

#### **14. Spice Client**
- **`lib64spice-client`** → **`lib64spice-client-gtk3.0_5`** (if exists)

#### **15. Virt GLib**
- **`lib64virt-glib`** → **`lib64virt-glib-devel`** (if exists)

#### **16. Perl XML**
- **`perl-XML`** → **`perl-XML-Parser`** (if exists)

#### **17. Python Packages**
- **`python-charset`** → **`python3-chardet`** (if exists)
- **`python-libcap`** → **`python3-libcap`** (if exists)
- **`python-pkg`** → **`python3-pkgconfig`** (if exists)

#### **18. QEMU Packages**
- **`qemu-audio`** → **`qemu-audio-alsa`** (if exists)
- **`qemu-block`** → **`qemu-block-iscsi`** (if exists)
- **`qemu-char`** → **`qemu-char-pty`** (if exists)
- **`qemu-device`** → **`qemu-device-usb`** (if exists)
- **`qemu-system`** → **`qemu-system-x86`** (if exists)
- **`qemu-ui`** → **`qemu-ui-gtk`** (if exists)

#### **19. Qt6 Packages**
- **`qt6-qtbase`** → **`qt6-qtbase-devel`** (if exists)
- **`qt-avif`** → **`qt6-qtimageformats`** (if exists)
- **`qt-jpegxl`** → **`qt6-qtimageformats`** (if exists)
- **`qt-theme`** → **`qt6-qtbase-theme-gtk3`** (if exists)

#### **20. Rust Standard Library**
- **`rust-std`** → **`rust-std-static`** (if exists)

#### **21. Shared MIME**
- **`shared-mime`** → **`shared-mime-info`** (if exists)

#### **22. VLC Plugin**
- **`vlc-plugin`** → **`vlc-plugin-qt`** (if exists)

#### **23. X11 Protocol**
- **`x11-proto`** → **`xorg-x11-proto-devel`** (if exists)

#### **24. XDG Packages**
- **`xdg-dbus`** → **`xdg-dbus-proxy`** (if exists)
- **`xdg-desktop`** → **`xdg-desktop-portal`** (if exists)
- **`xdg-user`** → **`xdg-user-dirs`** (if exists)

## **Recommended Solution**

### **1. Remove Non-Existent Packages**
Remove packages that don't exist in OpenMandriva repositories to avoid installation errors.

### **2. Replace with Correct Names**
Replace generic package names with OpenMandriva-specific package names.

### **3. Test Package Availability**
Before adding packages, verify they exist in OpenMandriva repositories.

## **Manual Fix Process**

### **Step 1: Remove Problematic Packages**
Remove these packages from packages.txt:
```bash
at-spi2
adwaita-icon
appstream-glib
bat-bash
bat-zsh
extra-cmake
fonts-ttf
lib64avahi-client
lib64avahi-common
lib64gtk4-layer
lib64gtksourceview
lib64gtk-vnc
lib64harfbuzz-gir
lib64json-glib
lib64luajit
lib64spice-client
lib64virt-glib
perl-XML
python-charset
python-libcap
python-pkg
qemu-audio
qemu-block
qemu-char
qemu-device
qemu-system
qemu-ui
qt6-qtbase
qt-avif
qt-jpegxl
qt-theme
rust-std
shared-mime
vlc-plugin
x11-proto
xdg-dbus
xdg-desktop
xdg-user
```

### **Step 2: Add Correct Packages (If Needed)**
Add these packages if they exist and are needed:
```bash
at-spi2-core.x86_64
adwaita-icon-theme.noarch
appstream-glib-i18n.noarch
bat-bash-completion.noarch
bat-zsh-completion.noarch
extra-cmake-modules.noarch
fonts-ttf-bitstream-vera.noarch
lib64avahi-client-devel.x86_64
lib64avahi-common-devel.x86_64
gtksourceview.x86_64
gtk-vnc-common.x86_64
perl-XML-Parser.noarch
python3-chardet.noarch
python3-libcap.x86_64
python3-pkgconfig.x86_64
shared-mime-info.x86_64
xorg-x11-proto-devel.x86_64
xdg-dbus-proxy.x86_64
xdg-desktop-portal.x86_64
xdg-user-dirs.x86_64
```

## **Benefits of the Fix**

### **✅ Reduced Installation Errors**
- **No more "No match for argument" errors**
- **Cleaner installation process**
- **Better user experience**

### **✅ Improved Reliability**
- **Only install packages that exist**
- **Consistent package naming**
- **OpenMandriva-specific compatibility**

### **✅ Faster Installation**
- **No failed package lookups**
- **Reduced installation time**
- **More efficient package resolution**

## **Testing Recommendations**

### **1. Test Package Installation**
```bash
# Test the corrected packages.txt
sudo dnf install --assumeno $(cat packages.txt | grep -v '^#' | grep -v '^$')
```

### **2. Verify Package Availability**
```bash
# Check if specific packages exist
dnf search package-name
```

### **3. Test Install Script**
```bash
# Test the full install script
./install_test_1.sh
```

## **Summary**

The package name issues can be resolved by:

1. **Removing non-existent packages** from packages.txt
2. **Replacing generic names** with OpenMandriva-specific names
3. **Testing package availability** before adding to the list
4. **Using only verified packages** that exist in OM repositories

This will eliminate the "No match for argument" errors and provide a smoother installation experience! 🎉 