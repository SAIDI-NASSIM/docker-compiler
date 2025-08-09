#!/bin/bash

# Test script for config-loader.sh JSON parsing functionality
# Standardized sourcing pattern for tests

# Get script directory (parent of tests directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Testing Configuration Parsing ==="
echo "Using SCRIPT_DIR: $SCRIPT_DIR"
echo

# Check if config file exists and source config loader
config_file="$SCRIPT_DIR/config/languages.json"
if [[ ! -f "$config_file" ]]; then
    echo "ERROR: Configuration file not found at $config_file"
    echo "Please provide the languages.json file content so I can ensure proper testing"
    exit 1
fi

echo "✓ Configuration file found: $config_file"

# Source config loader (no need to export SCRIPT_DIR, it's already set)
if [[ -f "$SCRIPT_DIR/utils/config-loader.sh" ]]; then
    source "$SCRIPT_DIR/utils/config-loader.sh"
else
    echo "ERROR: config-loader.sh not found"
    exit 1
fi

# Display actual JSON structure for verification
echo
echo "JSON file structure preview:"
head -20 "$config_file" | sed 's/^/  /'
echo

# Test jq availability
echo "Testing jq availability..."
if check_jq; then
    echo "✓ jq is available"
    jq_version=$(jq --version 2>/dev/null)
    echo "  jq version: ${jq_version:-unknown}"
else
    echo "✗ jq is not available"
    exit 1
fi

# Test JSON validation
echo
echo "Testing JSON file validation..."
if jq empty "$config_file" 2>/dev/null; then
    echo "✓ JSON file is valid"
else
    echo "✗ JSON file is invalid"
    exit 1
fi

# Test loading configurations
echo
echo "Loading configurations..."
if load_configurations; then
    echo "✓ Configurations loaded successfully"
else
    echo "✗ Failed to load configurations"
    exit 1
fi

# Test available languages
echo
echo "Testing available languages..."
available_langs=$(get_available_languages)
if [[ -n "$available_langs" ]]; then
    echo "✓ Available languages: $available_langs"
    lang_count=$(echo $available_langs | wc -w)
    echo "  Language count: $lang_count"
else
    echo "✗ No languages found"
    exit 1
fi

# Test language details for each language
echo
echo "Testing language details..."
for lang in $available_langs; do
    echo "Language: $lang"
    
    name=$(get_language_name "$lang")
    extensions=$(get_language_extensions "$lang")
    docker_image=$(get_language_docker_image "$lang")
    run_cmd=$(get_run_command "$lang")
    
    echo "  Name: ${name:-'(missing)'}"
    echo "  Extensions: ${extensions:-'(missing)'}"
    echo "  Docker Image: ${docker_image:-'(missing)'}"
    echo "  Run Command: ${run_cmd:-'(missing)'}"
    
    # Validate required fields
    if [[ -z "$name" || -z "$extensions" || -z "$docker_image" ]]; then
        echo "✗ Missing required fields for $lang"
        exit 1
    fi
    echo
done

# Test build systems
echo "Testing build systems..."
for lang in $available_langs; do
    echo "Language: $lang"
    case "$lang" in
        "go")
            if has_build_system "$lang" "with_modules"; then
                cmd=$(get_build_command "$lang" "with_modules")
                echo "  ✓ Has modules build: $cmd"
            fi
            if has_build_system "$lang" "without_modules"; then
                cmd=$(get_build_command "$lang" "without_modules")
                echo "  ✓ Has without modules build: $cmd"
            fi
            ;;
        "rust")
            if has_build_system "$lang" "with_cargo"; then
                cmd=$(get_build_command "$lang" "with_cargo")
                echo "  ✓ Has cargo build: $cmd"
            fi
            if has_build_system "$lang" "without_cargo"; then
                cmd=$(get_build_command "$lang" "without_cargo")
                echo "  ✓ Has without cargo build: $cmd"
            fi
            ;;
        "c")
            if has_build_system "$lang" "with_makefile"; then
                cmd=$(get_build_command "$lang" "with_makefile")
                echo "  ✓ Has makefile build: $cmd"
            fi
            if has_build_system "$lang" "without_makefile"; then
                cmd=$(get_build_command "$lang" "without_makefile")
                echo "  ✓ Has without makefile build: $cmd"
            fi
            ;;
    esac
    echo
done

# Test error cases
echo "Testing error cases..."
nonexistent_name=$(get_language_name "nonexistent")
if [[ -z "$nonexistent_name" ]]; then
    echo "✓ Non-existent language returns empty"
else
    echo "✗ Non-existent language should return empty"
fi

if has_build_system "go" "nonexistent"; then
    echo "✗ Non-existent build system should return false"
else
    echo "✓ Non-existent build system returns false"
fi

# Add test to verify JSON structure matches expectations
echo "Testing JSON structure..."
if jq -e '.languages' "$config_file" >/dev/null 2>&1; then
    echo "✓ JSON has 'languages' key"
else
    echo "✗ JSON missing 'languages' key"
    exit 1
fi

# Test that each language has required fields
for lang in $available_langs; do
    echo "Validating structure for $lang..."
    
    if jq -e ".languages.${lang}.name" "$config_file" >/dev/null 2>&1; then
        echo "  ✓ Has name field"
    else
        echo "  ✗ Missing name field"
        exit 1
    fi
    
    if jq -e ".languages.${lang}.extensions" "$config_file" >/dev/null 2>&1; then
        echo "  ✓ Has extensions field"
    else
        echo "  ✗ Missing extensions field"
        exit 1
    fi
    
    if jq -e ".languages.${lang}.docker_image" "$config_file" >/dev/null 2>&1; then
        echo "  ✓ Has docker_image field"
    else
        echo "  ✗ Missing docker_image field"
        exit 1
    fi
done

echo
echo "✓ Configuration parsing tests completed successfully"