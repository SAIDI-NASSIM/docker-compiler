#!/bin/bash

# Note: This file is sourced by main.sh after all utilities are loaded
# All utility functions and variables are available

# Compile Go project
compile_only() {
    local project_path="$1"
    local docker_image=$(get_language_docker_image "go")
    
    print_step "Building Go project..."
    
    # Validate project path
    if [[ ! -d "$project_path" ]]; then
        print_error "Project path does not exist: $project_path"
        return 1
    fi
    
    # Determine build strategy
    local build_cmd
    if has_file "$project_path" "go.mod"; then
        print_info "Detected go.mod - using module mode"
        build_cmd=$(get_build_command "go" "with_modules")
    else
        print_info "No go.mod found - using simple mode"
        build_cmd=$(get_build_command "go" "without_modules")
    fi
    
    # Check if build command exists
    if [[ -z "$build_cmd" ]]; then
        print_error "No build command found for Go language"
        return 1
    fi
    
    print_info "Build command: $build_cmd"
    
    # Execute build in Docker
    print_step "Executing Docker build..."
    if docker run --rm \
        -v "$project_path:/workspace" \
        -w /workspace \
        "$docker_image" \
        sh -c "$build_cmd"; then
        
        # Verify binary was created
        if [[ -f "$project_path/app" ]]; then
            print_success "Go build successful - binary created at: $project_path/app"
            return 0
        else
            print_error "Build completed but binary not found at: $project_path/app"
            return 1
        fi
    else
        print_error "Go build failed"
        return 1
    fi
}

# Compile and run Go project
compile_and_run() {
    local project_path="$1"
    
    if compile_only "$project_path"; then
        echo
        print_step "Running Go application..."
        
        local run_cmd=$(get_run_command "go")
        
        if [[ -z "$run_cmd" ]]; then
            print_error "No run command found for Go language"
            return 1
        fi
        
        print_info "Run command: $run_cmd"
        
        # Change to project directory for execution
        local current_dir=$(pwd)
        cd "$project_path" || {
            print_error "Failed to change to project directory: $project_path"
            return 1
        }
        
        print_output_header
        
        # Execute the application
        local exit_code=0
        if ! eval "$run_cmd"; then
            exit_code=1
        fi
        
        print_output_footer
        
        # Return to original directory
        cd "$current_dir" || true
        
        if [[ $exit_code -eq 0 ]]; then
            print_success "Go application executed successfully"
            return 0
        else
            print_error "Go application execution failed"
            return 1
        fi
    else
        return 1
    fi
}