#!/bin/bash

# Colors for better UX
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# Header display
print_header() {
    echo -e "${CYAN}========================================"
    echo -e "    Multi-Language Docker Compiler"
    echo -e "========================================"
    echo -e "  Supports: Go | Rust | C"
    echo -e "========================================${NC}"
    echo
}
# Step indicator
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Success message
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Error message
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Warning message
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Info message
print_info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

# Yes/No question helper
ask_yes_no() {
    local question="$1"
    local response
    while true; do
        echo -n -e "${YELLOW}$question (y/n): ${NC}"
        read -r response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Program output section
print_output_header() {
    echo -e "${CYAN}--- Program Output ---${NC}"
}

print_output_footer() {
    echo -e "${CYAN}--- End Output ---${NC}"
}