#!/bin/bash

declare -A LANGUAGES
declare -A LANGUAGE_NAMES
declare -A LANGUAGE_DOCKER_IMAGES

check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "ERROR: jq is required but not installed. Please install jq to continue." >&2
        return 1
    fi
}

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
    
    local lang_keys
    lang_keys=$(jq -r '.languages | keys[]' "$languages_file" 2>/dev/null)
    
    if [[ -z "$lang_keys" ]]; then
        echo "ERROR: No languages found in configuration file" >&2
        return 1
    fi
    
    while IFS= read -r lang_key; do
        [[ -z "$lang_key" ]] && continue
        
        LANGUAGES["$lang_key"]="true"
        LANGUAGE_NAMES["$lang_key"]=$(jq -r ".languages.${lang_key}.name" "$languages_file")
        LANGUAGE_DOCKER_IMAGES["$lang_key"]=$(jq -r ".languages.${lang_key}.docker_image" "$languages_file")
    done <<< "$lang_keys"
}

get_available_languages() {
    echo "${!LANGUAGES[@]}"
}

get_language_name() {
    local lang="$1"
    echo "${LANGUAGE_NAMES[$lang]}"
}

get_language_docker_image() {
    local lang="$1"
    echo "${LANGUAGE_DOCKER_IMAGES[$lang]}"
}

has_build_system() {
    local lang="$1"
    local build_system="$2"
    local config_file="$SCRIPT_DIR/config/languages.json"
    
    local result
    result=$(jq -r ".languages.${lang}.build.${build_system} // empty" "$config_file" 2>/dev/null)
    [[ -n "$result" && "$result" != "null" ]]
}

get_build_command() {
    local lang="$1"
    local build_system="$2"
    local config_file="$SCRIPT_DIR/config/languages.json"
    
    local result
    result=$(jq -r ".languages.${lang}.build.${build_system} // empty" "$config_file" 2>/dev/null)
    [[ "$result" != "null" ]] && echo "$result"
}

get_run_command() {
    local lang="$1"
    local config_file="$SCRIPT_DIR/config/languages.json"
    
    local result
    result=$(jq -r ".languages.${lang}.run // empty" "$config_file" 2>/dev/null)
    [[ "$result" != "null" ]] && echo "$result"
}

get_language_required_files() {
    local lang="$1"
    local config_file="$SCRIPT_DIR/config/languages.json"
    
    jq -r ".languages.${lang}.detection.required_files[]? // empty" "$config_file" 2>/dev/null | tr '\n' ' '
}

get_language_search_depth() {
    local lang="$1"
    local config_file="$SCRIPT_DIR/config/languages.json"
    
    jq -r ".languages.${lang}.detection.search_depth // 5" "$config_file" 2>/dev/null
}

get_language_exclude_paths() {
    local lang="$1"
    local config_file="$SCRIPT_DIR/config/languages.json"
    
    jq -r ".languages.${lang}.detection.exclude_paths[]? // empty" "$config_file" 2>/dev/null | tr '\n' ' '
}