#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Feature-specific tests
check "mise is installed" bash -c "command -v mise"
check "mise binary is at /usr/local/bin/mise" test -x /usr/local/bin/mise
check "mise --version exits successfully" mise --version
check "mise --version output contains version" bash -c "mise --version 2>&1 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+'"

# Report results
reportResults
