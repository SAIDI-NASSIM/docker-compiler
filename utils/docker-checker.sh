#!/bin/bash

# Note: ui-helpers.sh is sourced by main.sh before this file
# No need to source it again here

# Main Docker system check
check_docker_system() {
    print_step "Checking Docker system..."
    
    check_docker_installation
    check_docker_daemon
    
    print_success "Docker system ready"
    echo
}

# Check if Docker is installed
check_docker_installation() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        echo
        echo "Docker is required for containerized compilation."
        echo "Please visit: https://docs.docker.com/get-docker/"
        echo "After installation, restart this script."
        exit 1
    fi
    
    print_success "Docker is installed"
}

# Check if Docker daemon is running
check_docker_daemon() {
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running!"
        echo
        echo "Please start Docker Desktop or run: sudo systemctl start docker"
        echo "Then restart this script."
        exit 1
    fi
    
    print_success "Docker daemon is running"
}