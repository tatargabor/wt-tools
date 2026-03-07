#!/usr/bin/env bash
# Self-test for unit test helpers
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

test_assert_equals_pass() {
    assert_equals "hello" "hello" "equal strings"
}

test_assert_equals_fail() {
    local result
    set +e
    (assert_equals "hello" "world" "should fail" 2>/dev/null)
    result=$?
    set -e
    [[ $result -ne 0 ]]
}

test_assert_contains_pass() {
    assert_contains "hello world" "world" "contains substring"
}

test_assert_not_contains_pass() {
    assert_not_contains "hello world" "xyz" "does not contain"
}

test_assert_file_exists_pass() {
    assert_file_exists "$SCRIPT_DIR/helpers.sh" "helpers exists"
}

test_assert_exit_code_pass() {
    assert_exit_code 0 "true succeeds" true
}

run_tests
