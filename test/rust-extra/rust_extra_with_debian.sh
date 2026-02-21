#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for Debian
check "running on debian-based system" test -f "/etc/debian_version"

# Verify Rust tools work on Debian
check "cargo-binstall command exists" command -v cargo-binstall
check "cargo-audit command exists" command -v cargo-audit
check "cargo-edit (cargo-add) exists" command -v cargo-add
check "cargo-expand command exists" command -v cargo-expand
check "cargo-watch command exists" command -v cargo-watch

# Verify Rust is installed
check "rustc is available" rustc --version
check "cargo is available" cargo --version

# Report result
reportResults
