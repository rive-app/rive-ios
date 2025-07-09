#!/bin/bash

# Strip symbols from RiveRuntime.xcframework binaries
# This script iterates through all platform directories and strips symbols from each binary in-place
# See the Emerge Tools blog for more details: https://docs.emergetools.com/docs/strip-binary-symbols

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FRAMEWORK_DIR="$SCRIPT_DIR/../archive/RiveRuntime.xcframework"

# Check if the framework directory exists
if [ ! -d "$FRAMEWORK_DIR" ]; then
    echo "Error: RiveRuntime.xcframework not found at $FRAMEWORK_DIR"
    echo "Make sure the framework has been built and is in the archive directory."
    exit 1
fi

echo "Found RiveRuntime.xcframework at: $FRAMEWORK_DIR"
echo "Starting symbol stripping process..."

# Iterate through all platform directories
for platform_dir in "$FRAMEWORK_DIR"/*/; do
    if [ -d "$platform_dir" ]; then
        platform_name=$(basename "$platform_dir")
        echo "Processing platform: $platform_name"
        
        # Look for the framework directory within each platform
        framework_path="$platform_dir/RiveRuntime.framework"
        if [ -d "$framework_path" ]; then
            binary_path="$framework_path/RiveRuntime"
            
            if [ -f "$binary_path" ]; then
                echo "  Stripping symbols from: $binary_path"
                
                # Create a temporary file for the stripped binary
                temp_binary="$binary_path.tmp"
                
                # Strip symbols and save to temporary file
                strip -rSTx "$binary_path" -o "$temp_binary"
                
                # Replace the original binary with the stripped version
                mv "$temp_binary" "$binary_path"
                
                echo "  ✓ Successfully stripped symbols from $platform_name"
            else
                echo "  ⚠ Warning: Binary not found at $binary_path"
            fi
        else
            echo "  ⚠ Warning: Framework directory not found at $framework_path"
        fi
    fi
done

echo "Symbol stripping completed!" 