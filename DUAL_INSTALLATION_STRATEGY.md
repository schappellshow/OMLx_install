# 🚀 Dual Installation Strategy for OpenMandriva LX

## **Overview**

This strategy is designed for systems with **separate `/home` and root partitions** (like btrfs setups) to enable **fast reinstalls without losing personal data**.

## **📁 Scripts Overview**

### **1. `install_root_only.sh` - System-Level Installation**
- **Purpose**: Installs only system packages and applications
- **Target**: Root filesystem (`/usr`, `/etc`, `/opt`, etc.)
- **Preserves**: Your entire `/home` directory
- **Use Case**: Fresh installs, system updates, new hardware

### **2. `OMLx_install.sh` - Full Installation (Including Dotfiles)**
- **Purpose**: Installs everything + your personal configurations
- **Target**: Both system and user directories
- **Preserves**: Nothing (overwrites user configs)
- **Use Case**: First-time setup, restoring dotfiles, complete configuration

## **🔄 Installation Workflow**

### **Scenario 1: Fresh Install on New Hardware**
```bash
# Step 1: Install system packages only
bash install_root_only.sh

# Step 2: Restore your personal configurations
bash OMLx_install.sh
```

### **Scenario 2: System Reinstall (Preserving /home)**
```bash
# Step 1: Wipe only root partition, keep /home
# (Do this from live USB or installer)

# Step 2: Install system packages
bash install_root_only.sh

# Step 3: Your /home is already there, just run:
bash OMLx_install.sh
```

### **Scenario 3: Quick System Update**
```bash
# Just update system packages
bash install_root_only.sh
```

## **📋 What Each Script Installs**

### **`install_root_only.sh` (System Only)**
✅ **System Packages**
- Native packages from `packages.txt`
- Flatpak applications from `flatpak.txt`
- Build tools and development dependencies
- System-wide Python applications

✅ **Applications**
- Warp terminal
- Mailspring email client
- PDF Studio Viewer
- Cursor code editor
- KDE plugins and enhancements

✅ **Development Tools**
- Git, build tools, cmake
- Oh My Zsh (system-wide)
- Cargo applications (optional)

❌ **NOT Installed**
- Your personal dotfiles
- User-specific configurations
- Personal data and documents
- User-installed applications in `/home`

### **`OMLx_install.sh` (Complete Installation)**
✅ **Everything from root-only script PLUS:**
- Your personal dotfiles via stow
- Zsh plugins and configurations
- User-specific application settings
- Personal aliases and customizations

## **💾 Partition Strategy Benefits**

### **Btrfs with Separate Partitions**
```
/dev/sda1  /boot/efi    (EFI partition)
/dev/sda2  /            (Root filesystem - gets wiped on reinstall)
/dev/sda3  /home        (Home directory - preserved during reinstall)
```

### **Why This Works**
1. **Root Partition**: Contains system files, packages, applications
2. **Home Partition**: Contains your data, configs, documents
3. **Reinstall Process**: Only wipe root, preserve home
4. **Result**: Fresh system + all your personal data intact

## **⚡ Time Savings**

### **Traditional Reinstall**
- **Full backup**: 1-2 hours
- **Reinstall OS**: 30-60 minutes
- **Restore data**: 1-2 hours
- **Reconfigure**: 2-4 hours
- **Total**: 4.5-9 hours

### **Dual Script Strategy**
- **Wipe root partition**: 5 minutes
- **Run root-only script**: 30-60 minutes
- **Run full script (dotfiles)**: 10-15 minutes
- **Total**: 45-80 minutes

### **Time Saved**: **3-7 hours per reinstall!** 🎉

## **🛠️ Usage Examples**

### **Quick System Refresh**
```bash
# Just update system packages and applications
bash install_root_only.sh
```

### **New User Setup**
```bash
# Install system first
bash install_root_only.sh

# Then add user configurations
bash OMLx_install.sh
```

### **Development Environment**
```bash
# Install system tools
bash install_root_only.sh

# Install cargo applications
bash install_cargo_apps.sh
```

## **🔧 Customization Options**

### **Modify Root-Only Script**
- Add/remove system packages
- Change application versions
- Modify build configurations
- Add system-wide services

### **Modify Full Script**
- Update dotfiles repository
- Add new zsh plugins
- Modify user configurations
- Add user-specific applications

## **⚠️ Important Notes**

### **Before Running Root-Only Script**
1. **Backup important system configs** (if any)
2. **Ensure `/home` is on separate partition**
3. **Have live USB ready** (just in case)
4. **Check disk space** on root partition

### **After Running Root-Only Script**
1. **Reboot system** to ensure all changes take effect
2. **Verify applications** are working correctly
3. **Check system stability** before proceeding
4. **Run full script** only when ready for dotfiles

### **Troubleshooting**
- **Package conflicts**: Check `dnf history` for issues
- **Missing dependencies**: Run `sudo dnf check` to identify problems
- **Application issues**: Check logs in `/var/log/`
- **Permission problems**: Verify `/home` ownership is correct

## **🚀 Pro Tips**

### **Automation**
```bash
# Create a master script that runs both
#!/bin/bash
echo "Starting dual installation..."
bash install_root_only.sh
echo "System installation complete. Reboot recommended."
read -p "Reboot now? (y/N): " -r reboot_now
if [[ $reboot_now =~ ^[Yy]$ ]]; then
    sudo reboot
fi
```

### **Version Control**
- **Keep scripts in git repository**
- **Tag versions** for different OpenMandriva releases
- **Branch for different hardware configurations**
- **Document customizations** in commit messages

### **Backup Strategy**
- **System configs**: `/etc/` directory
- **Package lists**: `dnf list installed > system_packages.txt`
- **Service configs**: `systemctl list-unit-files`
- **User data**: Already safe in `/home`

## **🎯 When to Use Each Script**

### **Use `install_root_only.sh` When:**
- Setting up new hardware
- Reinstalling system (preserving /home)
- Updating system packages
- Adding new system applications
- Troubleshooting system issues

### **Use `OMLx_install.sh` When:**
- First-time complete setup
- Restoring personal configurations
- Setting up new user account
- Migrating to new system
- Complete system restoration

## **💡 Future Enhancements**

### **Potential Improvements**
- **Automated partition detection**
- **Smart backup of system configs**
- **Rollback functionality**
- **Configuration validation**
- **Performance benchmarking**

### **Integration Ideas**
- **Ansible playbooks** for enterprise use
- **Docker containers** for development
- **CI/CD pipelines** for testing
- **Monitoring and alerting**

---

## **🎉 Summary**

This dual installation strategy gives you the **best of both worlds**:
- **Fast reinstalls** (45-80 minutes vs 4.5-9 hours)
- **Data preservation** (your /home is always safe)
- **Flexibility** (system-only or complete installation)
- **Maintainability** (easy to update and customize)

**Perfect for developers, power users, and anyone who values their time and data!** 🚀
