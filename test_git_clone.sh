#!/bin/bash

# Test script for git cloning functionality
set -e

# Function to print colored output
print_status() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

# Function to safely clone and build git repositories
clone_and_build() {
    local repo_url="$1"
    local project_name="$2"
    local build_dir="$3"
    local build_commands="$4"
    
    print_status "Installing $project_name..."
    
    # Create a temporary directory for cloning
    local temp_dir="/tmp/${project_name}-$(date +%s)"
    
    # Clone repository
    print_status "Cloning $project_name repository..."
    if git clone "$repo_url" "$temp_dir"; then
        print_success "Successfully cloned $project_name"
        
        # Change to the cloned directory
        cd "$temp_dir" || {
            print_error "Failed to change to $project_name directory"
            rm -rf "$temp_dir"
            return 1
        }
        
        # Execute build commands if provided
        if [[ -n "$build_commands" ]]; then
            print_status "Building $project_name..."
            eval "$build_commands" || {
                print_error "Failed to build $project_name, continuing..."
                cd - > /dev/null
                rm -rf "$temp_dir"
                return 1
            }
        fi
        
        # Move to final location if specified
        if [[ -n "$build_dir" ]]; then
            # Remove existing directory if it exists
            if [[ -d "$build_dir" ]]; then
                print_status "Removing existing $project_name directory..."
                rm -rf "$build_dir"
            fi
            
            # Create parent directory if it doesn't exist
            mkdir -p "$(dirname "$build_dir")"
            
            # Move to final location
            mv "$temp_dir" "$build_dir" || {
                print_error "Failed to move $project_name to final location"
                cd - > /dev/null
                rm -rf "$temp_dir"
                return 1
            }
            
            print_success "$project_name installed to $build_dir"
        else
            # Clean up temp directory if no final location specified
            cd - > /dev/null
            rm -rf "$temp_dir"
        fi
        
        return 0
    else
        print_error "Failed to clone $project_name repository"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Test variables
TEST_DIR="$HOME/test-git-clone"
DOTFILES_URL="https://github.com/schappellshow/stow.git"

print_status "Testing git cloning functionality..."

# Test 1: Clone a simple repository
print_status "Test 1: Cloning dotfiles repository..."
clone_and_build \
    "$DOTFILES_URL" \
    "test-dotfiles" \
    "$TEST_DIR" \
    "" || {
    print_error "Test 1 failed"
    exit 1
}

# Verify the clone worked
if [[ -d "$TEST_DIR" ]]; then
    print_success "Test 1 passed: Repository cloned successfully"
    ls -la "$TEST_DIR"
else
    print_error "Test 1 failed: Repository not found"
    exit 1
fi

# Clean up
rm -rf "$TEST_DIR"
print_success "Test completed successfully!" 