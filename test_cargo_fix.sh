#!/bin/bash

# Test script for cargo linking fix
echo "Testing cargo linking fix..."

# Test 1: Check if cargo works
echo "1. Testing cargo version..."
cargo --version

# Test 2: Check if rustc works
echo "2. Testing rustc version..."
rustc --version

# Test 3: Test cargo install with dry-run
echo "3. Testing cargo install (dry-run)..."
cargo install --dry-run ripgrep

# Test 4: Check linker configuration
echo "4. Checking linker configuration..."
echo "RUSTFLAGS: $RUSTFLAGS"
echo "CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER: $CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER"

# Test 5: Check if GNU linker is available
echo "5. Checking available linkers..."
which ld.bfd
which ld.lld
which gcc

echo "Test complete!"
