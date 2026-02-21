#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for Debian base image
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"
check "claude binary has content" test -s "$(command -v claude)"
check "claude is in /usr/local/bin" test -f "/usr/local/bin/claude"

# Verify Debian-specific setup
check "running on debian-based system" test -f "/etc/debian_version"
check "curl is available" command -v curl

# Report result
reportResults
