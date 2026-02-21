#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for stable version
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"
check "claude binary has content" test -s "$(command -v claude)"
check "claude is in /usr/local/bin" test -f "/usr/local/bin/claude"

# Verify binary was installed successfully
check "claude binary size is reasonable" bash -c "[ \$(stat -c%s /usr/local/bin/claude 2>/dev/null || stat -f%z /usr/local/bin/claude) -gt 100000000 ]"

# Report result
reportResults
