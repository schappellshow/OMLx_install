# RPM Installation Fixes

## Problems Identified and Fixed

### **1. Warp Terminal Issues**
- **Problem**: Hardcoded URL was outdated and returned error pages (127 bytes)
- **Root Cause**: Warp release URLs change frequently and are version-specific
- **Fix**: 
  - Added multiple download methods (official API + GitHub releases)
  - Implemented file validation to detect error pages
  - Added fallback to GitHub releases if official API fails

### **2. Mailspring Issues**
- **Problem**: Download URL might be redirecting or returning error pages
- **Root Cause**: Mailspring's download system may have changed
- **Fix**: 
  - Added file validation before installation
  - Improved dependency installation with better error handling
  - Added comprehensive error checking

### **3. Proton Pass Issues**
- **Problem**: Similar download issues as Mailspring
- **Root Cause**: Proton's download URLs may have changed
- **Fix**: 
  - Added file validation
  - Improved dependency management
  - Better error handling

### **4. PDF Studio Viewer**
- **Status**: This one worked because it's a shell script, not an RPM
- **Improvement**: Added better validation and error handling

## Key Improvements Made

### **1. File Validation Function**
```bash
validate_download() {
    local file="$1"
    local min_size="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    if [[ $size -lt $min_size ]]; then
        print_error "Downloaded file is too small ($size bytes), likely an error page"
        return 1
    fi
    
    return 0
}
```

### **2. Safe RPM Installation Function**
```bash
install_rpm_safe() {
    local rpm_file="$1"
    local app_name="$2"
    
    # Validate RPM file
    if ! validate_download "$rpm_file" 1000000; then
        print_error "Invalid RPM file for $app_name"
        return 1
    fi
    
    # Try dnf first, then rpm
    if sudo dnf install -y "$rpm_file"; then
        print_success "$app_name installed successfully with dnf"
        return 0
    else
        print_warning "dnf installation failed, trying rpm..."
        if sudo rpm -ivh "$rpm_file"; then
            print_success "$app_name installed successfully with rpm"
            return 0
        else
            print_error "Failed to install $app_name with both dnf and rpm"
            return 1
        fi
    fi
}
```

### **3. Multiple Download Methods for Warp**
- **Method 1**: Official download API (`https://app.warp.dev/download?package=rpm`)
- **Method 2**: GitHub releases (fetches latest version automatically)
- **Validation**: Checks file size to ensure it's not an error page

### **4. Better Error Handling**
- File size validation before installation
- Multiple installation methods (dnf → rpm)
- Comprehensive error messages
- Graceful failure handling

## Benefits of the Fixes

### **1. Reliability**
- Multiple download sources for critical applications
- File validation prevents installation of corrupted downloads
- Better error detection and reporting

### **2. Maintainability**
- Centralized validation functions
- Consistent error handling across all RPM installations
- Easy to add new applications

### **3. User Experience**
- Clear error messages when downloads fail
- Automatic fallback to alternative installation methods
- Better progress reporting

### **4. OpenMandriva Compatibility**
- Uses both `dnf` and `rpm` installation methods
- Handles OpenMandriva-specific package naming
- Better dependency management

## Testing Recommendations

1. **Test each application individually** to identify specific issues
2. **Check network connectivity** for download URLs
3. **Verify dependencies** are available in OpenMandriva repositories
4. **Test in clean VM** to ensure all dependencies are properly resolved

## Future Improvements

1. **Add Flatpak alternatives** where available
2. **Implement AppImage support** for applications without RPMs
3. **Add source compilation** as fallback for critical applications
4. **Create dependency validation** before attempting installations 