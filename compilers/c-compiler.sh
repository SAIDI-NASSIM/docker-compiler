#!/bin/bash

# Compile C project
compile_only() {
    local project_path="$1"
    local docker_image=$(get_language_docker_image "c")
    
    print_step "Building C project..."
    
    # Validate project path
    if [[ ! -d "$project_path" ]]; then
        print_error "Project path does not exist: $project_path"
        return 1
    fi
    
    # Determine build strategy
    local build_cmd
    if has_file "$project_path" "Makefile" || has_file "$project_path" "makefile"; then
        print_info "Detected Makefile - using make mode"
        build_cmd=$(get_build_command "c" "with_makefile")
    else
        print_info "No Makefile found - using simple mode"
        build_cmd=$(get_build_command "c" "without_makefile")
    fi
    
    # Check if build command exists
    if [[ -z "$build_cmd" ]]; then
        print_error "No build command found for C language"
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
            print_success "C build successful - binary created at: $project_path/app"
            return 0
        else
            print_error "Build completed but binary not found at: $project_path/app"
            return 1
        fi
    else
        print_error "C build failed"
        return 1
    fi
}

# Compile and run C project
compile_and_run() {
    local project_path="$1"
    
    if compile_only "$project_path"; then
        echo
        print_step "Running C application..."
        
        local run_cmd=$(get_run_command "c")
        
        if [[ -z "$run_cmd" ]]; then
            print_error "No run command found for C language"
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
            print_success "C application executed successfully"
            return 0
        else
            print_error "C application execution failed"
            return 1
        fi
    else
        return 1
    fi
}
