#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}========================================"
    echo -e "    Multi-Language Docker Compiler"
    echo -e "========================================"
    echo -e "  Supports: Go | Rust | C"
    echo -e "========================================${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

print_output_header() {
    echo -e "${CYAN}--- Program Output ---${NC}"
}

print_output_footer() {
    echo -e "${CYAN}--- End Output ---${NC}"
}