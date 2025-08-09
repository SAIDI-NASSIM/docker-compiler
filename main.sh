#!/bin/bash

set -e

# Get script directory for relative imports - this becomes global for all sourced files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# Import utilities in dependency order
# ui-helpers.sh has no dependencies
source "$SCRIPT_DIR/utils/ui-helpers.sh"

# file-utils.sh has no dependencies  
source "$SCRIPT_DIR/utils/file-utils.sh"

# config-loader.sh needs SCRIPT_DIR
source "$SCRIPT_DIR/utils/config-loader.sh"

# docker-checker.sh needs ui-helpers.sh (already loaded)
source "$SCRIPT_DIR/utils/docker-checker.sh"

# Global variables
SELECTED_LANGUAGE=""
PROJECT_PATH=""

# Main execution flow
main() {
    print_header
    
    # Step 1: Load configuration
    print_step "Loading language configuration..."
    if ! load_configurations; then
        print_error "Failed to load configuration"
        exit 1
    fi
    print_success "Configuration loaded"
    echo
    
    # Step 2: Check Docker
    check_docker_system
    
    # Step 3: Language selection
    select_language
    
    # Step 4: Get and validate project
    get_project_path
    validate_project
    
    # Step 5: Setup Docker image
    setup_docker_image
    
    # Step 6: Compile project
    compile_project
    
    print_success "Pipeline completed successfully!"
}

# Language selection with dynamic options
select_language() {
    print_step "Language Selection"
    echo "Available languages:"
    
    local i=1
    local -a available_languages
    
    # Build dynamic menu from config
    for lang in $(get_available_languages); do
        local lang_name=$(get_language_name "$lang")
        echo "  $i) $lang_name"
        available_languages[$i]="$lang"
        ((i++))
    done
    echo
    
    local choice
    while true; do
        echo -n -e "${YELLOW}Select language (1-$((i-1))): ${NC}"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -lt "$i" ]]; then
            SELECTED_LANGUAGE="${available_languages[$choice]}"
            local selected_name=$(get_language_name "$SELECTED_LANGUAGE")
            print_success "Selected: $selected_name"
            echo
            break
        else
            print_error "Invalid choice. Please enter a number between 1 and $((i-1))"
        fi
    done
}

# Project path input
get_project_path() {
    print_step "Project Location"
    
    # Ask if user wants to use file explorer to browse
    echo "How would you like to specify your project path?"
    echo "  1) Type the path manually"
    echo "  2) Open file explorer to browse and copy path"
    echo
    
    local choice
    while true; do
        echo -n -e "${YELLOW}Select option (1 or 2): ${NC}"
        read -r choice
        
        case $choice in
            1)
                echo
                echo -n -e "${YELLOW}Enter path to your project: ${NC}"
                read -r PROJECT_PATH
                break
                ;;
            2)
                echo
                print_info "Opening file explorer..."
                print_info "Instructions:"
                print_info "  1. Navigate to your project folder in the file explorer"
                print_info "  2. Press Ctrl+L to show the address bar"
                print_info "  3. Copy the path (Ctrl+C)"
                print_info "  4. Come back here and paste it"
                echo
                
                # Open file explorer in current directory
                if command -v open > /dev/null; then
                    open . 2>/dev/null &
                elif command -v xdg-open > /dev/null; then
                    xdg-open . 2>/dev/null &
                else
                    print_warn "Could not detect file manager. Please open your file explorer manually."
                fi
                
                echo -n -e "${YELLOW}Paste your project path here: ${NC}"
                read -r PROJECT_PATH
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1 or 2"
                ;;
        esac
    done
    
    # Clean up path
    PROJECT_PATH=$(clean_path "$PROJECT_PATH")
    PROJECT_PATH=$(get_absolute_path "$PROJECT_PATH")
    echo
}

# Project validation
validate_project() {
    print_step "Validating project at: $PROJECT_PATH"
    
    # Check if directory exists and is accessible
    if ! validate_directory "$PROJECT_PATH"; then
        print_error "Directory does not exist or is not accessible: $PROJECT_PATH"
        exit 1
    fi
    
    # Language-specific validation
    local extensions=$(get_language_extensions "$SELECTED_LANGUAGE")
    
    if ! has_files_with_extensions "$PROJECT_PATH" "$extensions"; then
        local lang_name=$(get_language_name "$SELECTED_LANGUAGE")
        print_error "No $lang_name source files found (extensions: $extensions)"
        exit 1
    fi
    
    print_success "Project validation passed"
    echo
}

# Docker image setup
setup_docker_image() {
    local docker_image=$(get_language_docker_image "$SELECTED_LANGUAGE")
    
    print_step "Setting up Docker image: $docker_image"
    
    if docker pull "$docker_image"; then
        print_success "Docker image ready"
    else
        print_error "Failed to pull Docker image: $docker_image"
        exit 1
    fi
    echo
}

# Compilation orchestrator
compile_project() {
    print_step "Starting compilation..."
    
    # Load language-specific compiler
    local compiler_script="$SCRIPT_DIR/compilers/${SELECTED_LANGUAGE}-compiler.sh"
    
    if [[ ! -f "$compiler_script" ]]; then
        print_error "Compiler not found for language: $SELECTED_LANGUAGE"
        exit 1
    fi
    
    source "$compiler_script"
    
    # Ask user what they want to do
    echo "What would you like to do?"
    echo "  1) Build only"
    echo "  2) Build and run"
    echo
    
    local choice
    while true; do
        echo -n -e "${YELLOW}Select option (1 or 2): ${NC}"
        read -r choice
        
        case $choice in
            1)
                if compile_only "$PROJECT_PATH"; then
                    print_success "Build completed successfully!"
                else
                    print_error "Build failed!"
                    exit 1
                fi
                break
                ;;
            2)
                if compile_and_run "$PROJECT_PATH"; then
                    print_success "Build and run completed successfully!"
                else
                    print_error "Build or run failed!"
                    exit 1
                fi
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1 or 2"
                ;;
        esac
    done
}

# Run the main pipeline
main "$@"