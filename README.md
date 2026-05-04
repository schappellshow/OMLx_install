# OMLx_install
Install script and setup for OM Lx ROME/ROCK

Clone this repo to your system first.
```bash
git clone https://github.com/schappellshow/OMLx_install.git
cd OMLx_install
```

## **📋 Installation Workflow**

### **Step 1: Generate Your Package List**
Create a list of packages you want to install on your fresh system:
```bash
# Option A: Generate from current system (if you have one)
dnf list --installed > packages_original.txt

# Option B: Create manually
# Edit packages_original.txt and add packages you want, one per line
# Example:
# firefox
# vim
# git
# python3-pip
```

### **Step 2: Analyze and Clean Package List**
Run the package analyzer to remove packages already in clean OMLx-ROME:
```bash
bash analyze_packages.sh
```

This script will:
- **Compare** your `packages_original.txt` with `OM_clean_packages.txt`
- **Remove duplicates** that are already in clean OMLx-ROME
- **Generate** a clean `packages.txt` file ready for installation
- **Show statistics** about how many packages were optimized out

### **Step 3: Generate Your Flatpak List**
`flatpak.txt` is **not included in this repo** — you provide your own. Generate it from your current system or create it manually:
```bash
# Option A: Export installed flatpaks from current system
flatpak list --app --columns=application > flatpak.txt

# Option B: Create manually — one app ID per line
# Example:
# com.spotify.Client
# org.videolan.VLC
# com.discordapp.Discord
```
Place `flatpak.txt` in the repo directory before running the install script.

### **Step 4: Run the Installation Script**
Install all packages and configure your system:
```bash
bash OMLx_install.sh
```

This script will:
- **Install packages** from the generated `packages.txt`
- **Install flatpaks** from `flatpak.txt`
- **Install additional applications** (Warp, Mailspring, Zed, etc.)
- **Set up your dotfiles** via stow
- **Configure zsh** with Oh My Zsh and plugins
- **Install cargo applications** (optional)

## **📁 File Structure**

- **`packages_original.txt`** - Your original package list (create this)
- **`OM_clean_packages.txt`** - Clean OMLx-ROME package list (provided)
- **`packages.txt`** - Generated clean package list (output of analyzer)
- **`flatpak.txt`** - Flatpak applications to install (**not tracked in repo — provide your own**)
- **`OMLx_install.sh`** - Main installation script
- **`analyze_packages.sh`** - Package list analyzer

## **🎯 Benefits of This Workflow**

1. **🔄 No file renaming** - Clear, logical file names
2. **⚡ Efficient installation** - Only installs what you actually need
3. **🛡️ Avoids conflicts** - Removes packages already in clean install
4. **📊 Clear visibility** - See exactly what will be installed
5. **🚀 Ready to run** - Generated `packages.txt` works immediately with install script

## **💡 Tips**

- **Review** the generated `packages.txt` before running the install script
- **Customize** `packages_original.txt` to include only packages you actually want
- **Backup** your original package list if needed
- **Test** on a fresh VM first if you're unsure about the process 
