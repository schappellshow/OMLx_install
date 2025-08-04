# Testing Guide for OpenMandriva Install Script

## Overview

This guide provides multiple ways to test your install script without needing a clean OpenMandriva VM. The testing framework includes both comprehensive and targeted testing options.

## Testing Options

### **1. Comprehensive Testing**
Run all tests at once to get a complete picture of your script's readiness:

```bash
./test_install_script.sh
```

This will test:
- ✅ System requirements (sudo, curl, git, dnf, rpm, cargo, flatpak)
- ✅ Network connectivity to all required URLs
- ✅ Package dependencies from packages.txt
- ✅ RPM downloads (Warp, Mailspring, Proton Pass)
- ✅ Cargo application installations
- ✅ Git repository cloning
- ✅ Flatpak application installations

### **2. Targeted Testing**
Test specific components individually:

```bash
# Test system requirements only
./test_install_script.sh system

# Test network connectivity only
./test_install_script.sh network

# Test package dependencies only
./test_install_script.sh packages

# Test RPM downloads only
./test_install_script.sh rpms

# Test cargo applications only
./test_install_script.sh cargo

# Test git repositories only
./test_install_script.sh git

# Test flatpak applications only
./test_install_script.sh flatpak
```

### **3. Script Validation**
Validate the install script structure and syntax:

```bash
./validate_install_script.sh
```

This checks:
- ✅ Script syntax
- ✅ File structure
- ✅ Common issues (hardcoded paths, missing error handling)
- ✅ Dependencies availability
- ✅ Required files presence
- ✅ Script sections analysis

## What Each Test Does

### **System Requirements Test**
- Checks if all required commands are available
- Verifies sudo, curl, git, dnf, rpm, cargo, flatpak are installed
- Reports missing dependencies

### **Network Connectivity Test**
- Tests connectivity to GitHub, Crates.io, Flathub
- Verifies RPM download URLs are accessible
- Checks all external service URLs

### **Package Dependencies Test**
- Reads packages from packages.txt
- Tests first 10 packages with `dnf install --assumeno`
- Identifies packages that may have dependency issues

### **RPM Download Test**
- Downloads RPMs without installing them
- Validates file size (prevents error page downloads)
- Checks if files are valid RPMs
- Tests DNF installation compatibility

### **Cargo Applications Test**
- Checks if cargo is available
- Tests if applications are already installed
- Uses `cargo install --dry-run` to test installation

### **Git Repository Test**
- Tests repository accessibility
- Clones repositories to temporary directories
- Validates repository structure
- Cleans up after testing

### **Flatpak Applications Test**
- Checks if flatpak is available
- Tests if applications are already installed
- Uses dry-run installation to test compatibility

## Understanding Test Results

### **Success Indicators**
- ✅ Green success messages
- ✅ "would install successfully" messages
- ✅ "accessible" and "successful" status

### **Warning Indicators**
- ⚠️ Yellow warning messages
- ⚠️ "may have issues" messages
- ⚠️ Missing dependencies or tools

### **Error Indicators**
- ❌ Red error messages
- ❌ "failed" or "not accessible" messages
- ❌ Network connectivity issues

## Interpreting Results

### **All Tests Pass**
If all tests show green success messages, your script is likely ready for a clean VM test.

### **Some Warnings**
Yellow warnings indicate potential issues but don't necessarily mean failure:
- Missing optional dependencies
- Network timeouts
- Already installed applications

### **Errors Found**
Red errors indicate issues that need fixing:
- Network connectivity problems
- Invalid URLs
- Missing required dependencies
- Script syntax errors

## Common Issues and Solutions

### **Network Connectivity Issues**
```bash
# Test specific URL
curl -I https://app.warp.dev

# Check DNS resolution
nslookup github.com
```

### **Missing Dependencies**
```bash
# Install missing tools
sudo dnf install curl git cargo flatpak

# Check if tools are in PATH
which curl git cargo flatpak
```

### **Package Issues**
```bash
# Check specific package
dnf info package-name

# Test package installation
sudo dnf install --assumeno package-name
```

## Testing Best Practices

### **1. Run Tests Regularly**
- Test after each major change
- Test before committing to version control
- Test in different network conditions

### **2. Start with Validation**
```bash
./validate_install_script.sh
```
This catches syntax errors and structural issues first.

### **3. Test Components Individually**
If comprehensive testing fails, test components individually to isolate issues.

### **4. Check Network First**
```bash
./test_install_script.sh network
```
Network issues will affect most other tests.

### **5. Monitor System Resources**
- Tests download files to /tmp
- Large RPMs may use significant bandwidth
- Some tests may take time to complete

## Troubleshooting

### **Permission Issues**
```bash
chmod +x test_install_script.sh validate_install_script.sh
```

### **Missing Files**
```bash
ls -la *.sh *.txt
```

### **Network Timeouts**
- Check internet connection
- Try again later
- Use VPN if needed

### **DNF Issues**
```bash
sudo dnf clean all
sudo dnf makecache
```

## Next Steps After Testing

### **If All Tests Pass**
1. Create a clean VM for final testing
2. Run the full install script
3. Verify all applications work correctly

### **If Issues Found**
1. Fix identified problems
2. Re-run relevant tests
3. Repeat until all tests pass

### **For Production Use**
1. Test in multiple environments
2. Document any manual steps needed
3. Create backup/rollback procedures

## Example Test Session

```bash
# 1. Validate script structure
./validate_install_script.sh

# 2. Test system requirements
./test_install_script.sh system

# 3. Test network connectivity
./test_install_script.sh network

# 4. Test package dependencies
./test_install_script.sh packages

# 5. Test RPM downloads
./test_install_script.sh rpms

# 6. Run comprehensive test
./test_install_script.sh
```

This testing framework allows you to thoroughly validate your install script without needing a clean VM, saving time and resources while ensuring reliability. 