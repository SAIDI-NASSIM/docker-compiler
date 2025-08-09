#!/bin/bash

# Test script for config-loader.sh JSON parsing functionality

# Set up the script directory path (parent of tests directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SCRIPT_DIR

echo "Using SCRIPT_DIR: $SCRIPT_DIR"
echo "Expected config file: $SCRIPT_DIR/config/languages.json"
echo

# Check if config file exists before proceeding
if [[ ! -f "$SCRIPT_DIR/config/languages.json" ]]; then
    echo "ERROR: Configuration file not found at $SCRIPT_DIR/config/languages.json"
    echo "Please ensure the languages.json file exists in the config directory."
    exit 1
fi

# Source the config loader
if [[ -f "$SCRIPT_DIR/utils/config-loader.sh" ]]; then
    source "$SCRIPT_DIR/utils/config-loader.sh"
else
    echo "ERROR: config-loader.sh not found at $SCRIPT_DIR/utils/config-loader.sh"
    exit 1
fi

echo "=== Testing JSON Configuration Parsing ==="
echo

# Test 1: Check if jq is available
echo "1. Testing jq availability..."
if check_jq; then
    echo "✓ jq is available"
else
    echo "✗ jq is not available - test cannot continue"
    exit 1
fi
echo

# Test 2: Load configurations
echo "2. Loading configurations..."
if load_configurations; then
    echo "✓ Configurations loaded successfully"
else
    echo "✗ Failed to load configurations"
    exit 1
fi
echo

# Test 3: Test available languages
echo "3. Available languages:"
available_langs=$(get_available_languages)
if [[ -n "$available_langs" ]]; then
    echo "   Languages: $available_langs"
else
    echo "   ERROR: No languages found"
    exit 1
fi
echo

# Test 4: Test language details for each language
echo "4. Testing language details:"
for lang in $available_langs; do
    echo "   Language: $lang"
    name=$(get_language_name "$lang")
    extensions=$(get_language_extensions "$lang")
    docker_image=$(get_language_docker_image "$lang")
    run_cmd=$(get_run_command "$lang")
    
    echo "     Name: ${name:-'(empty)'}"
    echo "     Extensions: ${extensions:-'(empty)'}"
    echo "     Docker Image: ${docker_image:-'(empty)'}"
    echo "     Run Command: ${run_cmd:-'(empty)'}"
    echo
done

# Test 5: Test build systems
echo "5. Testing build systems:"
for lang in $available_langs; do
    echo "   Language: $lang"
    case "$lang" in
        "go")
            has_modules=$(has_build_system "$lang" "with_modules" && echo "yes" || echo "no")
            modules_cmd=$(get_build_command "$lang" "with_modules")
            has_no_modules=$(has_build_system "$lang" "without_modules" && echo "yes" || echo "no")
            no_modules_cmd=$(get_build_command "$lang" "without_modules")
            
            echo "     Has modules build: $has_modules"
            echo "     Modules build cmd: ${modules_cmd:-'(empty)'}"
            echo "     Has without modules build: $has_no_modules"
            echo "     Without modules cmd: ${no_modules_cmd:-'(empty)'}"
            ;;
        "rust")
            has_cargo=$(has_build_system "$lang" "with_cargo" && echo "yes" || echo "no")
            cargo_cmd=$(get_build_command "$lang" "with_cargo")
            has_no_cargo=$(has_build_system "$lang" "without_cargo" && echo "yes" || echo "no")
            no_cargo_cmd=$(get_build_command "$lang" "without_cargo")
            
            echo "     Has cargo build: $has_cargo"
            echo "     Cargo build cmd: ${cargo_cmd:-'(empty)'}"
            echo "     Has without cargo build: $has_no_cargo"
            echo "     Without cargo cmd: ${no_cargo_cmd:-'(empty)'}"
            ;;
        "c")
            has_makefile=$(has_build_system "$lang" "with_makefile" && echo "yes" || echo "no")
            makefile_cmd=$(get_build_command "$lang" "with_makefile")
            has_no_makefile=$(has_build_system "$lang" "without_makefile" && echo "yes" || echo "no")
            no_makefile_cmd=$(get_build_command "$lang" "without_makefile")
            
            echo "     Has makefile build: $has_makefile"
            echo "     Makefile build cmd: ${makefile_cmd:-'(empty)'}"
            echo "     Has without makefile build: $has_no_makefile"
            echo "     Without makefile cmd: ${no_makefile_cmd:-'(empty)'}"
            ;;
    esac
    echo
done

# Test 6: Test non-existent language/build system
echo "6. Testing error cases:"
nonexistent_name=$(get_language_name "nonexistent")
nonexistent_build=$(has_build_system "go" "nonexistent" && echo "yes" || echo "no")
nonexistent_cmd=$(get_build_command "go" "nonexistent")

echo "   Non-existent language name: ${nonexistent_name:-'(empty)'}"
echo "   Non-existent build system exists: $nonexistent_build"
echo "   Non-existent build command: ${nonexistent_cmd:-'(empty)'}"
echo

echo "=== All tests completed successfully ==="