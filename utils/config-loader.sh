#!/bin/bash

declare -A LANGUAGES
declare -A LANGUAGE_NAMES
declare -A LANGUAGE_EXTENSIONS
declare -A LANGUAGE_DOCKER_IMAGES

# Set SCRIPT_DIR if not already set (for when this script is sourced)
if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "ERROR: jq is required but not installed. Please install jq to continue." >&2
        return 1
    fi
}

# Load language configurations
load_configurations() {
    local config_dir="$SCRIPT_DIR/config"
    local languages_file="$config_dir/languages.json"
    
    if [[ ! -f "$languages_file" ]]; then
        echo "ERROR: Languages configuration file not found: $languages_file" >&2
        return 1
    fi
    
    if ! check_jq; then
        return 1
    fi
    
    if ! jq empty "$languages_file" 2>/dev/null; then
        echo "ERROR: Invalid JSON format in: $languages_file" >&2
        return 1
    fi
    
    extract_language_configs "$languages_file"
}

# Extract language configurations into arrays using jq
extract_language_configs() {
    local config_file="$1"
    
    local lang_keys
    lang_keys=$(jq -r '.languages | keys[]' "$config_file" 2>/dev/null)
    
    if [[ -z "$lang_keys" ]]; then
        echo "ERROR: No languages found in configuration file" >&2
        return 1
    fi
    
    while IFS= read -r lang_key; do
        [[ -z "$lang_key" ]] && continue
        
        LANGUAGES["$lang_key"]="true"
        
        LANGUAGE_NAMES["$lang_key"]=$(jq -r ".languages.${lang_key}.name" "$config_file")
        
        local extensions
        extensions=$(jq -r ".languages.${lang_key}.extensions[]" "$config_file" 2>/dev/null | tr '\n' ' ')
        LANGUAGE_EXTENSIONS["$lang_key"]="${extensions% }"  # Remove trailing space
        
        LANGUAGE_DOCKER_IMAGES["$lang_key"]=$(jq -r ".languages.${lang_key}.docker_image" "$config_file")
    done <<< "$lang_keys"
}

# Get list of available languages
get_available_languages() {
    echo "${!LANGUAGES[@]}"
}

# Get language display name
get_language_name() {
    local lang="$1"
    echo "${LANGUAGE_NAMES[$lang]}"
}

# Get language file extensions
get_language_extensions() {
    local lang="$1"
    echo "${LANGUAGE_EXTENSIONS[$lang]}"
}

# Get language Docker image
get_language_docker_image() {
    local lang="$1"
    echo "${LANGUAGE_DOCKER_IMAGES[$lang]}"
}

# Check if language has specific build system
has_build_system() {
    local lang="$1"
    local build_system="$2"
    local config_file="$SCRIPT_DIR/config/languages.json"
    
    local result
    result=$(jq -r ".languages.${lang}.build.${build_system} // empty" "$config_file" 2>/dev/null)
    [[ -n "$result" && "$result" != "null" ]]
}

# Get build command for specific build system
get_build_command() {
    local lang="$1"
    local build_system="$2"
    local config_file="$SCRIPT_DIR/config/languages.json"
    
    local result
    result=$(jq -r ".languages.${lang}.build.${build_system} // empty" "$config_file" 2>/dev/null)
    [[ "$result" != "null" ]] && echo "$result"
}

# Get run command for language
get_run_command() {
    local lang="$1"
    local config_file="$SCRIPT_DIR/config/languages.json"
    
    local result
    result=$(jq -r ".languages.${lang}.run // empty" "$config_file" 2>/dev/null)
    [[ "$result" != "null" ]] && echo "$result"
}