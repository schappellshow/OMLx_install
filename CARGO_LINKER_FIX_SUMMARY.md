# Cargo Linker Fix for OpenMandriva

## Problem Identified
The cargo linking error was caused by OpenMandriva using `ld.lld` (LLVM linker) by default, which has compatibility issues with some Rust crates and the specific linker flags being used.

## Error Analysis
```
ld.lld: warning: unknown -z value: ,nostart-stop-gc
ld.lld: error: cannot open Scrt1.o: No such file or directory
ld.lld: error: cannot open crti.o: No such file or directory
ld.lld: error: unable to find library -lutil
```

## Root Cause
- OpenMandriva uses `ld.lld` as the default linker
- `ld.lld` doesn't support all the same flags as GNU `ld.bfd`
- The linker can't find essential object files and libraries
- Cargo needs to be configured to use GNU linker instead

## Solution Applied

### 1. Install Essential Development Packages
```bash
gcc.x86_64
gcc-c++.x86_64
make.x86_64
cmake.x86_64
pkgconf.x86_64
binutils.x86_64
glibc-devel.x86_64
libstdc++-devel.x86_64
```

### 2. Configure Cargo to Use GNU Linker
Created `~/.cargo/config.toml`:
```toml
[target.x86_64-unknown-linux-gnu]
linker = "gcc"
rustflags = [
    "-C", "link-arg=-fuse-ld=bfd",
    "-C", "link-arg=-Wl,--as-needed",
    "-C", "link-arg=-Wl,-z,relro,-z,now"
]
```

### 3. Set Environment Variables
```bash
export RUSTFLAGS="-C link-arg=-fuse-ld=bfd"
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc
```

## Benefits
- ✅ **Fixed linking errors** for cargo applications
- ✅ **Improved compatibility** with Rust crates
- ✅ **Better build success rate** for Rust applications
- ✅ **Consistent linker behavior** across the system

## Testing
Run the test script to verify the fix:
```bash
./test_cargo_fix.sh
```

## Files Modified
1. `~/.cargo/config.toml` - Cargo configuration
2. `~/.bashrc` - Environment variables
3. `packages.txt` - Added development dependencies
4. `test_cargo_fix.sh` - Test script

## Verification Steps
1. Test cargo installation: `cargo install --dry-run ripgrep`
2. Check linker configuration: `echo $RUSTFLAGS`
3. Verify GNU linker: `which ld.bfd`
4. Test actual installation: `cargo install ripgrep`

