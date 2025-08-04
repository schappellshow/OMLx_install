# Git Cloning Issues and Fixes

## Issues Identified in the Original Script

The original install script had several problems with the git cloning operations in lines 325-520:

### 1. **Hardcoded Paths**
- **Problem**: Used hardcoded paths like `/home/mike/` which won't work for other users
- **Fix**: Changed to use `$HOME` variable for dynamic user paths

### 2. **Missing Error Handling**
- **Problem**: Git clone operations had minimal error handling
- **Fix**: Added comprehensive error handling with proper cleanup

### 3. **Directory Conflicts**
- **Problem**: Script didn't check if directories already existed
- **Fix**: Added checks and cleanup for existing directories

### 4. **Permission Issues**
- **Problem**: Some operations might fail due to permission problems
- **Fix**: Added proper directory creation and permission handling

### 5. **Inconsistent Error Recovery**
- **Problem**: Failed operations didn't clean up properly
- **Fix**: Added proper cleanup in all error cases

## Key Fixes Applied

### 1. **Created `clone_and_build()` Function**
This centralized function handles:
- Safe temporary directory creation
- Proper error handling and cleanup
- Dynamic path resolution using `$HOME`
- Build command execution
- Final directory placement

### 2. **Updated All Git Operations**
- **conky-manager2**: Now uses `$HOME/conky-manager2`
- **espanso**: Now uses `$HOME/espanso`
- **kwin-forceblur**: Now uses `$HOME/kwin-effects-forceblur-*`
- **dotfiles**: Now uses `$HOME/stow`

### 3. **Improved Error Handling**
- Each git operation now has proper error checking
- Failed operations clean up temporary files
- Script continues with other installations even if one fails

### 4. **Better Directory Management**
- Checks for existing directories before cloning
- Creates parent directories as needed
- Uses temporary directories to avoid conflicts

## Testing

The git cloning functionality has been tested and works correctly:
- Git is available (version 2.49.0)
- Repository cloning works properly
- Directory creation and file operations function as expected

## Usage

The updated script now:
1. Uses dynamic paths based on `$HOME`
2. Handles errors gracefully
3. Cleans up properly on failures
4. Provides better feedback to the user
5. Continues installation even if some git operations fail

## Files Modified

- `install_test_1.sh`: Main script with all fixes applied
- `test_git_clone.sh`: Test script to verify functionality
- `GIT_CLONE_FIXES.md`: This documentation

The script should now work reliably across different users and environments. 