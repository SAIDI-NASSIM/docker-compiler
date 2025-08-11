#!/bin/bash

validate_directory() {
    local dir_path="$1"
    [[ -n "$dir_path" && -d "$dir_path" && -r "$dir_path" ]]
}

search_files_in_directory() {
    local directory="$1"
    local file_patterns="$2"
    local max_depth="$3"
    local exclude_paths="$4"
    
    [[ -d "$directory" ]] || return 1
    
    max_depth="${max_depth:-5}"
    exclude_paths="${exclude_paths:-.git node_modules vendor build dist target obj bin out __pycache__ .vscode .idea}"
    
    # Build exclude conditions array
    local exclude_args=()
    for exclude_path in $exclude_paths; do
        exclude_args+=("-not" "-path" "*/${exclude_path}/*")
    done
    
    for pattern in $file_patterns; do
        # Use find with proper array expansion for safety
        if find "$directory" -maxdepth "$max_depth" -name "$pattern" -type f "${exclude_args[@]}" 2>/dev/null | grep -q .; then
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