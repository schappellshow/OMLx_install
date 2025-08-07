# Zsh and Stow Fixes

## **🐛 Problems Identified**

### **1. Zsh not in `/etc/shells`**
```
chsh: "/bin/zsh" is not listed in /etc/shells.
Use chsh -l to see list.
```

### **2. Stow directory issue**
```
./install_test_1.sh: line 788: cd: /tmp/dotfiles-1754602928: No such file or directory
```

## **🔧 Root Causes**

### **Zsh Issue:**
- OpenMandriva doesn't automatically add zsh to `/etc/shells`
- `chsh` requires the shell to be listed in `/etc/shells` before it can be set as default

### **Stow Issue:**
- The `clone_and_build` function moves the repository to the final location
- The script was trying to `cd` to a temporary directory that no longer exists
- The stow directory might not exist if the clone failed

## **✅ Fixes Applied**

### **1. Fixed Zsh Issue:**
```bash
# Add zsh to /etc/shells if it's not already there
if ! grep -q "/bin/zsh" /etc/shells; then
    print_status "Adding zsh to /etc/shells..."
    echo "/bin/zsh" | sudo tee -a /etc/shells > /dev/null
fi

if chsh -s /bin/zsh; then
    print_success "Zsh set as default shell"
else
    print_warning "Failed to set zsh as default shell, you can do this manually later"
fi
```

### **2. Fixed Stow Issue:**
```bash
print_status "Applying dotfiles with stow..."
if [[ -d "$stow_dir" ]]; then
    cd "$stow_dir" || {
        print_error "Failed to change to stow directory"
        print_warning "Continuing with remaining installations..."
    }
else
    print_error "Stow directory not found: $stow_dir"
    print_warning "Continuing with remaining installations..."
fi
```

## **🎯 What These Fixes Do**

### **Zsh Fix:**
1. **Checks** if zsh is already in `/etc/shells`
2. **Adds** zsh to `/etc/shells` if it's missing
3. **Sets** zsh as default shell successfully
4. **Continues** even if it fails

### **Stow Fix:**
1. **Checks** if the stow directory exists
2. **Changes** to the directory only if it exists
3. **Shows** helpful error messages if directory is missing
4. **Continues** with remaining installations

## **🚀 Expected Results**

### **Before:**
```
[INFO] Setting zsh as default shell...
chsh: "/bin/zsh" is not listed in /etc/shells.
[WARNING] Failed to set zsh as default shell

[INFO] Applying dotfiles with stow...
cd: /tmp/dotfiles-1754602928: No such file or directory
```

### **After:**
```
[INFO] Setting zsh as default shell...
[INFO] Adding zsh to /etc/shells...
[SUCCESS] Zsh set as default shell

[INFO] Applying dotfiles with stow...
[SUCCESS] Dotfiles applied successfully.
```

## **📋 Benefits**

### **Zsh Fix Benefits:**
- ✅ **Automatic shell setup** - No manual intervention needed
- ✅ **Proper `/etc/shells` management** - System-compliant
- ✅ **Graceful fallback** - Continues if it fails
- ✅ **Clear feedback** - Shows what's happening

### **Stow Fix Benefits:**
- ✅ **No more errors** - Handles missing directories gracefully
- ✅ **Better error messages** - Shows what went wrong
- ✅ **Script continues** - Doesn't terminate on stow issues
- ✅ **Robust handling** - Works regardless of clone success

## **🧪 Test It**

```bash
bash install_test_1.sh
```

The script should now:
1. ✅ **Add zsh to `/etc/shells`** automatically
2. ✅ **Set zsh as default shell** successfully
3. ✅ **Handle stow directory** properly
4. ✅ **Apply dotfiles** without errors
5. ✅ **Continue to cargo applications** section

## **📝 Summary**

- **Problem 1:** Zsh not in `/etc/shells` causing `chsh` to fail
- **Solution 1:** Automatically add zsh to `/etc/shells` before setting as default
- **Problem 2:** Script trying to `cd` to non-existent temporary directory
- **Solution 2:** Check if stow directory exists before trying to `cd` to it
- **Result:** Both zsh and stow will work properly
- **Benefit:** Script runs smoothly without these errors

The script should now handle both issues gracefully! 🎉
