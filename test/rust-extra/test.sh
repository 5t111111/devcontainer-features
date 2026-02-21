#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "cargo-binstall version" cargo-binstall --version
check "cargo-audit version" cargo audit --version
check "cargo-edit installed" cargo add --help
check "cargo-expand version" cargo expand --version
check "cargo-watch version" cargo watch --version

# Report result
reportResults
