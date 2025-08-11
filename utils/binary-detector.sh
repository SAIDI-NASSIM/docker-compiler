#!/bin/bash

# Binary detection utilities for different build systems

# Find the most likely executable binary in a project directory
# This is designed to be flexible and work with various build systems
find_project_binary() {
    local project_path="$1"
    local language="$2"
    local build_system="${3:-unknown}"
    
    if [[ ! -d "$project_path" ]]; then
        echo ""
        return 1
    fi
    
    cd "$project_path" || return 1
    
    # Strategy 1: Look for recently created executables (built in last 5 minutes)
    local recent_executables
    recent_executables=$(find . -maxdepth 3 -type f -executable -newermt "5 minutes ago" 2>/dev/null | grep -v -E "\.(sh|py|pl|rb)$" | head -5)
    
    if [[ -n "$recent_executables" ]]; then
        # Prefer binaries in common output directories or root
        local preferred_binary
        preferred_binary=$(echo "$recent_executables" | grep -E "^(\./app$|\./bin/|\./build/|\./target/release/)" | head -1)
        if [[ -n "$preferred_binary" ]]; then
            echo "$preferred_binary"
            return 0
        fi
        
        # Fallback to first recent executable
        echo "$recent_executables" | head -1
        return 0
    fi
    
    # Strategy 2: Look for common binary names
    local common_names=("app" "main" "server" "client" "program")
    for name in "${common_names[@]}"; do
        if [[ -f "$name" && -x "$name" ]]; then
            echo "./$name"
            return 0
        fi
        # Also check in common directories
        for dir in "bin" "build" "target/release" "target/debug"; do
            if [[ -f "$dir/$name" && -x "$dir/$name" ]]; then
                echo "./$dir/$name"
                return 0
            fi
        done
    done
    
    # Strategy 3: Parse Makefile for target information
    if [[ "$build_system" == "with_makefile" && -f "Makefile" ]]; then
        local makefile_target
        makefile_target=$(grep -E "^[A-Za-z][A-Za-z0-9_-]*\s*=" Makefile | grep -i target | head -1 | cut -d'=' -f2 | tr -d ' ')
        if [[ -n "$makefile_target" && -f "$makefile_target" && -x "$makefile_target" ]]; then
            echo "./$makefile_target"
            return 0
        fi
    fi
    
    # Strategy 4: Find any executable that looks like it was built (not a script)
    local any_executable
    any_executable=$(find . -maxdepth 2 -type f -executable 2>/dev/null | grep -v -E "\.(sh|py|pl|rb|js)$" | grep -v -E "/(configure|config\.guess|config\.sub|install-sh|test)" | head -1)
    
    if [[ -n "$any_executable" ]]; then
        echo "$any_executable"
        return 0
    fi
    
    # No binary found
    echo ""
    return 1
}

# Create a standardized app binary by copying the detected binary
create_standard_app_binary() {
    local project_path="$1"
    local detected_binary="$2"
    
    if [[ -z "$detected_binary" || ! -f "$project_path/$detected_binary" ]]; then
        return 1
    fi
    
    cd "$project_path" || return 1
    
    # If it's already named 'app' in the root, we're good
    if [[ "$detected_binary" == "./app" ]]; then
        return 0
    fi
    
    # Copy to standard location
    if cp "$detected_binary" "./app" 2>/dev/null; then
        chmod +x "./app"
        return 0
    fi
    
    return 1
}

# Verify that a binary exists and is executable
verify_binary() {
    local binary_path="$1"
    [[ -f "$binary_path" && -x "$binary_path" ]]
}
