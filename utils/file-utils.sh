#!/bin/bash

# Check if directory exists and is accessible
validate_directory() {
    local dir_path="$1"
    [[ -n "$dir_path" && -d "$dir_path" && -r "$dir_path" ]]
}

# Check if any files with given extensions exist in directory
has_files_with_extensions() {
    local directory="$1"
    local extensions="$2"  # space-separated list
    
    [[ -d "$directory" ]] || return 1
    
    for ext in $extensions; do
        if find "$directory" -maxdepth 1 -name "*$ext" -type f | grep -q .; then
            return 0
        fi
    done
    
    return 1
}

# Check if specific file exists in directory
has_file() {
    local directory="$1"
    local filename="$2"
    
    [[ -f "$directory/$filename" ]]
}

# Clean path - remove quotes and trailing slashes
clean_path() {
    local path="$1"
    
    # Remove leading and trailing quotes first
    path="${path#\"}"
    path="${path%\"}"
    # Then remove trailing slash
    path="${path%/}"
    
    echo "$path"
}

# Get absolute path
get_absolute_path() {
    local path="$1"
    
    if [[ "$path" = /* ]]; then
        # Already absolute
        echo "$path"
    else
        # Make it absolute
        echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    fi
}