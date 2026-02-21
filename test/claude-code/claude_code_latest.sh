#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for latest version
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"
check "claude binary has content" test -s "$(command -v claude)"
check "claude is in /usr/local/bin" test -f "/usr/local/bin/claude"

# Verify it's the latest version (binary should be relatively recent)
check "claude binary is recent" bash -c "find /usr/local/bin/claude -mtime -1 | grep -q claude"

# Report result
reportResults
