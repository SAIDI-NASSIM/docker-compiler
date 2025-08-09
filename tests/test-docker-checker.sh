#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/utils/ui-helpers.sh"
source "$SCRIPT_DIR/utils/docker-checker.sh"

print_header
print_info "Testing Docker checker functions..."
echo

print_step "Testing function availability"
functions_to_test="check_docker_system check_docker_installation check_docker_daemon"

all_exist=true
for func in $functions_to_test; do
    if type "$func" >/dev/null 2>&1; then
        print_success "Function '$func' exists"
    else
        print_error "Function '$func' missing"
        all_exist=false
    fi
done

if ! $all_exist; then
    print_error "Docker functions missing - cannot continue tests"
    exit 1
fi

print_success "All Docker checker functions loaded"
echo

print_step "Testing Docker command availability"
if command -v docker &> /dev/null; then
    print_success "Docker command is available"
    
    docker_version=$(docker --version 2>/dev/null)
    if [[ -n "$docker_version" ]]; then
        print_info "Docker version: $docker_version"
    fi
    
    print_step "Testing Docker daemon status"
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
        print_info "Docker system info:"
        docker system info --format "  Server Version: {{.ServerVersion}}" 2>/dev/null || print_warning "Could not get server info"
    else
        print_warning "Docker daemon is not running"
        print_info "Start Docker with: sudo systemctl start docker"
    fi
    
    print_step "Testing Docker permissions"
    if docker ps &> /dev/null; then
        print_success "Docker permissions are correct"
    else
        print_warning "Docker permission issues detected"
        print_info "You may need to add user to docker group"
    fi
    
else
    print_warning "Docker is not installed"
    print_info "Install Docker from: https://docs.docker.com/get-docker/"
fi

echo
print_step "Testing error handling"
print_info "Docker checker functions will exit on errors (cannot test without breaking script)"
print_info "Manual test: Run 'check_docker_system' when Docker is not available"

print_success "Docker checker tests completed successfully"
    print_warning "Docker is not installed"
    print_info "Install Docker from: https://docs.docker.com/get-docker/"
fi

echo
print_step "Testing error handling"
# Test that functions would exit on error (we can't actually test exit)
print_info "Docker checker functions will exit on errors (cannot test without breaking script)"
print_info "Manual test: Run 'check_docker_system' when Docker is not available"

print_success "Docker checker tests completed successfully"
