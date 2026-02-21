#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for file permissions
check "cargo-binstall command exists" command -v cargo-binstall

# Verify CARGO_HOME directory permissions
check "CARGO_HOME binstall directory permissions" bash -c "stat -c '%G:%a' ${CARGO_HOME}/binstall | grep 'rustlang:2775'"
check "CARGO_HOME bin directory permissions" bash -c "stat -c '%a' ${CARGO_HOME}/bin | grep '2775'"

# Verify individual binary permissions
check "cargo-audit binary permissions" bash -c "stat -c '%G:%a' ${CARGO_HOME}/bin/cargo-audit | grep 'rustlang:775'"
check "cargo-binstall binary permissions" bash -c "stat -c '%a' ${CARGO_HOME}/bin/cargo-binstall | grep '775'"

# Verify CARGO_HOME ownership
check "CARGO_HOME ownership" bash -c "stat -c '%G' ${CARGO_HOME} | grep 'rustlang'"

# Verify no leftover build artifacts
check "no cargo registry cache" bash -c "[ ! -d /usr/local/cargo/registry ] || [ -z \"\$(ls -A /usr/local/cargo/registry 2>/dev/null)\" ]"

# Report result
reportResults
