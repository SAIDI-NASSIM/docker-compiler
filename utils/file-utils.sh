#!/bin/bash

validate_directory() {
    local dir_path="$1"
    [[ -n "$dir_path" && -d "$dir_path" && -r "$dir_path" ]]
}

has_files_with_extensions() {
    local directory="$1"
    local extensions="$2"
    
    [[ -d "$directory" ]] || return 1
    
    for ext in $extensions; do
        if find "$directory" -maxdepth 1 -name "*$ext" -type f | grep -q .; then
            return 0
        fi
    done
    
    return 1
}

has_file() {
    local directory="$1"
    local filename="$2"
    
    [[ -f "$directory/$filename" ]]
}

clean_path() {
    local path="$1"
    
    path="${path#\"}"
    path="${path%\"}"
    path="${path%/}"
    
    echo "$path"
}

get_absolute_path() {
    local path="$1"
    
    if [[ "$path" = /* ]]; then
        echo "$path"
    else
        echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    fi
}