#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

source "$SCRIPT_DIR/utils/ui-helpers.sh"
source "$SCRIPT_DIR/utils/file-utils.sh"
source "$SCRIPT_DIR/utils/config-loader.sh"
source "$SCRIPT_DIR/utils/docker-checker.sh"

SELECTED_LANGUAGE=""
PROJECT_PATH=""

main() {
    print_header
    
    print_step "Loading language configuration..."
    if ! load_configurations; then
        print_error "Failed to load configuration"
        exit 1
    fi
    print_success "Configuration loaded"
    echo
    
    check_docker_system
    select_language
    get_project_path
    validate_project
    setup_docker_image
    compile_project
    
    print_success "Pipeline completed successfully!"
}

select_language() {
    print_step "Language Selection"
    echo "Available languages:"
    
    local i=1
    local -a available_languages
    
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

get_project_path() {
    print_step "Project Location"
    
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
                
                if command -v open > /dev/null; then
                    open . 2>/dev/null &
                elif command -v xdg-open > /dev/null; then
                    xdg-open . 2>/dev/null &
                else
                    print_warning "Could not detect file manager. Please open your file explorer manually."
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
    
    PROJECT_PATH=$(clean_path "$PROJECT_PATH")
    PROJECT_PATH=$(get_absolute_path "$PROJECT_PATH")
    echo
}

validate_project() {
    print_step "Validating project at: $PROJECT_PATH"
    
    if ! validate_directory "$PROJECT_PATH"; then
        print_error "Directory does not exist or is not accessible: $PROJECT_PATH"
        exit 1
    fi
    
    local required_files=$(get_language_required_files "$SELECTED_LANGUAGE")
    local search_depth=$(get_language_search_depth "$SELECTED_LANGUAGE")
    local exclude_paths=$(get_language_exclude_paths "$SELECTED_LANGUAGE")
    
    if ! search_files_in_directory "$PROJECT_PATH" "$required_files" "$search_depth" "$exclude_paths"; then
        local lang_name=$(get_language_name "$SELECTED_LANGUAGE")
        print_error "No $lang_name source files found (patterns: $required_files)"
        print_info "Searched recursively (depth: $search_depth) excluding: $exclude_paths"
        exit 1
    fi
    
    print_success "Project validation passed"
    echo
}

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

compile_project() {
    print_step "Starting compilation..."
    
    local compiler_script="$SCRIPT_DIR/compilers/${SELECTED_LANGUAGE}-compiler.sh"
    
    if [[ ! -f "$compiler_script" ]]; then
        print_error "Compiler not found for language: $SELECTED_LANGUAGE"
        exit 1
    fi
    
    source "$compiler_script"
    
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

main "$@"