#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/utils/ui-helpers.sh"
source "$SCRIPT_DIR/utils/file-utils.sh"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

print_header
print_info "Testing file utility functions..."
print_info "Test directory: $TEST_DIR"
echo

mkdir -p "$TEST_DIR/testdir"
mkdir -p "$TEST_DIR/empty"
touch "$TEST_DIR/testdir/test.go"
touch "$TEST_DIR/testdir/test.rs"
touch "$TEST_DIR/testdir/test.c"
touch "$TEST_DIR/testdir/Makefile"
touch "$TEST_DIR/testdir/main.py"

print_step "Testing validate_directory"
if validate_directory "$SCRIPT_DIR"; then
    print_success "validate_directory with existing directory works"
else
    print_error "validate_directory failed with existing directory"
fi

if validate_directory "/non/existent/path"; then
    print_error "validate_directory should fail with non-existent directory"
else
    print_success "validate_directory correctly fails with non-existent directory"
fi

if validate_directory ""; then
    print_error "validate_directory should fail with empty path"
else
    print_success "validate_directory correctly fails with empty path"
fi
echo

print_step "Testing clean_path"
test_cases=(
    '"/test/path/":/test/path'
    '"/test/path":/test/path'
    'test/path/:test/path'
    '"test/path":test/path'
    '/root/:/root'
)

for case in "${test_cases[@]}"; do
    input="${case%:*}"
    expected="${case#*:}"
    result=$(clean_path "$input")
    if [[ "$result" == "$expected" ]]; then
        print_success "clean_path('$input') = '$result'"
    else
        print_error "clean_path('$input') = '$result', expected '$expected'"
    fi
done
echo

print_step "Testing get_absolute_path"
abs_path=$(get_absolute_path "/usr/bin")
if [[ "$abs_path" == "/usr/bin" ]]; then
    print_success "get_absolute_path works with absolute paths"
else
    print_error "get_absolute_path failed with absolute path"
fi

rel_path=$(get_absolute_path ".")
expected_rel="$(pwd)/."
if [[ "$rel_path" == "$expected_rel" ]]; then
    print_success "get_absolute_path works with relative paths"
else
    print_error "get_absolute_path failed: got '$rel_path', expected '$expected_rel'"
fi
echo

print_step "Testing has_file"
if has_file "$TEST_DIR/testdir" "test.go"; then
    print_success "has_file correctly finds existing file"
else
    print_error "has_file failed to find existing file"
fi

if has_file "$TEST_DIR/testdir" "nonexistent.txt"; then
    print_error "has_file should not find non-existent file"
else
    print_success "has_file correctly doesn't find non-existent file"
fi

if has_file "$TEST_DIR/nonexistent" "test.go"; then
    print_error "has_file should fail with non-existent directory"
else
    print_success "has_file correctly fails with non-existent directory"
fi

if has_file "" "test.go"; then
    print_error "has_file should fail with empty directory"
else
    print_success "has_file correctly fails with empty directory"
fi
echo

print_success "File utility tests completed successfully"