#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/utils/ui-helpers.sh"

print_header
print_info "Testing UI helper functions..."
echo

print_step "Testing all print functions"
print_success "This is a success message"
print_error "This is an error message" 
print_warning "This is a warning message"
print_info "This is an info message"
echo

print_step "Testing output sections"
print_output_header
echo "Sample program output here"
print_output_footer
echo

print_step "Testing function availability"
functions_to_test="print_header print_step print_success print_error print_warning print_info print_output_header print_output_footer"

all_exist=true
for func in $functions_to_test; do
    if type "$func" >/dev/null 2>&1; then
        print_success "Function '$func' exists"
    else
        print_error "Function '$func' missing"
        all_exist=false
    fi
done

echo
if $all_exist; then
    print_success "All UI helper functions loaded successfully"
else
    print_error "Some UI helper functions are missing"
    exit 1
fi

print_step "Testing color variables"
color_vars="RED GREEN YELLOW BLUE CYAN PURPLE NC"
colors_exist=true
for var in $color_vars; do
    if [[ -n "${!var}" ]]; then
        print_success "Color variable $var is set"
    else
        print_error "Color variable $var is missing"
        colors_exist=false
    fi
done

if $colors_exist; then
    print_success "All color variables are defined"
else
    print_error "Some color variables are missing"
    exit 1
fi

print_success "UI helper tests completed successfully"
