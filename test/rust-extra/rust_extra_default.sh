#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for default scenario
check "cargo-binstall command exists" command -v cargo-binstall
check "cargo-audit command exists" command -v cargo-audit
check "cargo-edit (cargo-add) exists" command -v cargo-add
check "cargo-expand command exists" command -v cargo-expand
check "cargo-watch command exists" command -v cargo-watch

# Verify Cargo tools are functional
check "cargo-audit can show version" bash -c "cargo audit --version | grep 'cargo-audit'"
check "cargo-edit can show help" bash -c "cargo add --help | grep 'Add dependencies'"
check "cargo-expand can show version" bash -c "cargo expand --version | grep 'cargo-expand'"
check "cargo-watch can show version" bash -c "cargo watch --version | grep 'cargo-watch'"

# Verify build artifacts were cleaned up
check "no cargo registry cache" bash -c "[ ! -d /usr/local/cargo/registry ] || [ -z \"\$(ls -A /usr/local/cargo/registry 2>/dev/null)\" ]"

# Report result
reportResults
