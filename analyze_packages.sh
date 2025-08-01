#!/bin/bash

# Package list comparator for OpenMandriva
# This script compares your current package list (packages.txt) with a clean OMLx-ROME install
# (OM_clean_packages.txt) to identify packages you installed yourself

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_section() {
    echo -e "\n${CYAN}--- $1 ---${NC}"
}

# Check if required files exist
if [[ ! -f "packages.txt" ]]; then
    echo -e "${RED}Error: packages.txt not found!${NC}"
    echo "This should contain your current system's package list."
    exit 1
fi

if [[ ! -f "OM_clean_packages.txt" ]]; then
    echo -e "${RED}Error: OM_clean_packages.txt not found!${NC}"
    echo "This should contain the package list from a clean OMLx-ROME install."
    exit 1
fi

print_header "OpenMandriva Package List Comparator"

# Extract package names from current system (remove version info)
echo -e "${YELLOW}Processing current system packages (packages.txt)...${NC}"
grep -v '^[[:space:]]*$' packages.txt | \
awk '{print $1}' | \
sed 's/-[0-9].*//' | \
sort -u > /tmp/current_packages_clean.txt

current_count=$(wc -l < /tmp/current_packages_clean.txt)
echo -e "${GREEN}Found $current_count packages in current system${NC}"

# Extract package names from clean install (remove version info)
echo -e "${YELLOW}Processing clean install packages (OM_clean_packages.txt)...${NC}"
grep -v '^[[:space:]]*$' OM_clean_packages.txt | \
awk '{print $1}' | \
sed 's/-[0-9].*//' | \
sort -u > /tmp/clean_packages_clean.txt

clean_count=$(wc -l < /tmp/clean_packages_clean.txt)
echo -e "${GREEN}Found $clean_count packages in clean install${NC}"

print_section "Comparing Package Lists"

# Find packages that are only in the current system (not in clean install)
comm -23 /tmp/current_packages_clean.txt /tmp/clean_packages_clean.txt > /tmp/custom_packages.txt

# Find packages that are in both (will be removed)
comm -12 /tmp/current_packages_clean.txt /tmp/clean_packages_clean.txt > /tmp/common_packages.txt

custom_count=$(wc -l < /tmp/custom_packages.txt)
common_count=$(wc -l < /tmp/common_packages.txt)

# Display results
print_section "Packages from Clean Install (will be excluded)"
echo -e "${YELLOW}Count: $common_count${NC}"
if [[ $common_count -gt 0 ]]; then
    echo -e "${CYAN}These packages are present in clean OMLx-ROME install:${NC}"
    if [[ $common_count -le 20 ]]; then
        cat /tmp/common_packages.txt
    else
        head -20 /tmp/common_packages.txt
        echo "... and $((common_count - 20)) more"
    fi
fi

print_section "Custom Packages (your installations)"
echo -e "${GREEN}Count: $custom_count${NC}"
if [[ $custom_count -gt 0 ]]; then
    echo -e "${CYAN}These packages are only on your system:${NC}"
    sort /tmp/custom_packages.txt
else
    echo -e "${YELLOW}No custom packages found!${NC}"
fi

# Create custom package list
print_section "Creating Custom Package List"
{
    echo "# OpenMandriva Custom Package List"
    echo "# Generated by package comparator on $(date)"
    echo "# Contains only packages you installed yourself"
    echo "# (Packages present in clean OMLx-ROME install have been excluded)"
    echo ""
    echo "# Source files:"
    echo "#   Current system: packages.txt"
    echo "#   Clean install:  OM_clean_packages.txt"
    echo ""
    if [[ -s /tmp/custom_packages.txt ]]; then
        sort /tmp/custom_packages.txt
    else
        echo "# No custom packages found"
    fi
} > packages_custom.txt

print_header "Comparison Complete"
echo -e "${GREEN}Custom package list created: packages_custom.txt${NC}"
echo -e "${YELLOW}Current system packages: $current_count${NC}"
echo -e "${YELLOW}Clean install packages: $clean_count${NC}"
echo -e "${YELLOW}Common packages (excluded): $common_count${NC}"
echo -e "${GREEN}Custom packages (your installs): $custom_count${NC}"

if [[ $custom_count -gt 0 ]]; then
    reduction_percent=$(( (common_count * 100) / current_count ))
    echo -e "\n${CYAN}Reduction: $common_count packages excluded from install script${NC}"
    echo -e "${CYAN}Space saving: ~${reduction_percent}% reduction in package list${NC}"
else
    echo -e "\n${YELLOW}All your packages are already in the clean install!${NC}"
fi

# Cleanup
rm -f /tmp/current_packages_clean.txt /tmp/clean_packages_clean.txt /tmp/custom_packages.txt /tmp/common_packages.txt

echo -e "\n${GREEN}Review packages_custom.txt - these are the packages you need to install!${NC}"
