# Espanso AppImage Installation Fix

## **🐛 Problem Identified**

The original espanso AppImage installation was failing with this error:
```bash
[SUCCESS] Espanso AppImage downloaded successfully
[SUCCESS] Espanso AppImage installed successfully
[INFO] Registering espanso service...
/home/mike/.local/bin/espanso: line 1: Not: command not found
[ERROR] Failed to register espanso service
```

## **🔧 Root Cause**

The original script was using:
1. **Incorrect download URL** - Using a non-existent URL
2. **Wrong installation method** - Not following the official espanso installation process
3. **Incorrect file naming** - Using lowercase filename instead of proper case
4. **Missing env-path registration** - Not registering the command alias properly

## **✅ Solution Applied**

### **Updated to Official Installation Process:**

#### **1. Correct Installation Directory**
```bash
# Create the $HOME/opt destination folder (official method)
local espanso_dir="$HOME/opt"
mkdir -p "$espanso_dir"
```

#### **2. Correct Download URL**
```bash
# Download the AppImage inside it (official URL)
local appimage_url="https://github.com/espanso/espanso/releases/download/v2.2.1/Espanso-X11.AppImage"
local appimage_path="$espanso_dir/Espanso.AppImage"
```

#### **3. Correct Download Method**
```bash
# Use wget instead of curl (official method)
if wget -O "$appimage_path" "$appimage_url"; then
```

#### **4. Correct Permissions**
```bash
# Make it executable (official method)
chmod u+x "$appimage_path"
```

#### **5. Command Alias Registration**
```bash
# Create the "espanso" command alias (official method)
print_status "Registering espanso command alias..."
if sudo "$appimage_path" env-path register; then
    print_success "Espanso command alias registered successfully"
else
    print_warning "Failed to register espanso command alias, but continuing..."
fi
```

#### **6. Service Registration**
```bash
# Register espanso as a systemd service (official method)
if espanso service register; then
    print_success "Espanso service registered successfully"
    
    # Start espanso (official method)
    print_status "Starting espanso..."
    if espanso start; then
        print_success "Espanso started successfully"
    fi
fi
```

## **📋 Official Installation Process (Now Implemented)**

The script now follows the exact official process:

```bash
# Create the $HOME/opt destination folder
mkdir -p ~/opt

# Download the AppImage inside it
wget -O ~/opt/Espanso.AppImage 'https://github.com/espanso/espanso/releases/download/v2.2.1/Espanso-X11.AppImage'

# Make it executable
chmod u+x ~/opt/Espanso.AppImage

# Create the "espanso" command alias
sudo ~/opt/Espanso.AppImage env-path register

# Register espanso as a systemd service (required only once)
espanso service register

# Start espanso
espanso start
```

## **🎯 Expected Results After Fix**

### **Successful Installation Output:**
```bash
[INFO] Installing espanso using AppImage...
[INFO] Downloading espanso AppImage...
[SUCCESS] Espanso AppImage downloaded successfully
[INFO] Registering espanso command alias...
[SUCCESS] Espanso command alias registered successfully
[SUCCESS] Espanso AppImage installed successfully
[INFO] Registering espanso service...
[SUCCESS] Espanso service registered successfully
[INFO] Starting espanso...
[SUCCESS] Espanso started successfully
[INFO] Testing espanso installation...
[SUCCESS] Espanso is available: espanso 2.2.1
[SUCCESS] Espanso service is working
[SUCCESS] Espanso AppImage installation completed!
```

## **🧪 Testing the Fix**

### **1. Test Installation in VM**
```bash
# Run the updated script
./install_test_1.sh
```

### **2. Verify espanso is Working**
```bash
# Check if espanso is available
which espanso

# Check espanso version
espanso --version

# Check service status
espanso service status

# Test basic functionality
espanso match list
```

### **3. Test Text Expansion**
```bash
# Create a simple test expansion
espanso match create --trigger ":test" --replace "This is a test expansion"

# Type ":test" in any text field to test
```

## **🔍 Troubleshooting**

### **If env-path register fails:**
```bash
# Manual registration
sudo ~/opt/Espanso.AppImage env-path register

# Check if espanso is now available
which espanso
```

### **If service registration fails:**
```bash
# Manual service registration
espanso service register

# Start espanso manually
espanso start
```

### **If espanso still not found:**
```bash
# Check if the AppImage exists
ls -la ~/opt/Espanso.AppImage

# Try running the AppImage directly
~/opt/Espanso.AppImage --version

# Check PATH
echo $PATH
```

## **📝 Key Changes Made**

### **1. Installation Directory**
- **Before:** `~/.local/bin/espanso.AppImage`
- **After:** `~/opt/Espanso.AppImage`

### **2. Download URL**
- **Before:** `https://github.com/federico-terzi/espanso/releases/latest/download/espanso-linux-x86_64.AppImage`
- **After:** `https://github.com/espanso/espanso/releases/download/v2.2.1/Espanso-X11.AppImage`

### **3. Download Method**
- **Before:** `curl -L`
- **After:** `wget -O`

### **4. Command Registration**
- **Before:** Manual symlink creation
- **After:** Official `env-path register` method

### **5. Service Registration**
- **Before:** Direct service registration
- **After:** Proper command alias registration first, then service registration

## **🚀 Benefits of the Fix**

1. **Follows official process** - Uses espanso's recommended installation method
2. **Proper command registration** - Uses `env-path register` for system-wide availability
3. **Correct file naming** - Uses proper case-sensitive filename
4. **Better error handling** - Provides helpful error messages and fallback options
5. **Official URL** - Uses the correct, verified download source

The espanso AppImage installation should now work correctly! 🎉 