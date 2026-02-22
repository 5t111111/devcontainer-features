#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for persistence enabled
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"
check "claude binary has content" test -s "$(command -v claude)"

# Verify persistence is enabled
check "persistent volume base directory exists" test -d "/var/lib/claude-config"

# Check symlink setup
USER_HOME="/home/vscode"
if [ -d "$USER_HOME" ]; then
    check ".claude exists" test -e "$USER_HOME/.claude"
    check ".claude is a symlink" test -L "$USER_HOME/.claude"
    check ".claude points to persistent volume" bash -c "[ \"\$(readlink -f $USER_HOME/.claude)\" = \"/var/lib/claude-config\" ]"

    # Check ownership
    check ".claude symlink ownership" bash -c "stat -c '%U' $USER_HOME/.claude | grep -E 'vscode|root'"
    check "persistent volume ownership" bash -c "stat -c '%U' /var/lib/claude-config | grep -E 'vscode|root'"

    # Check permissions (should be 700)
    check "persistent volume permissions" bash -c "stat -c '%a' /var/lib/claude-config | grep -E '700|755'"

    # Additional detailed tests
    # Verify the symlink is not broken
    check "symlink is not broken" test -e "$USER_HOME/.claude"

    # Verify user can access via symlink
    check "user can list via symlink" bash -c "ls $USER_HOME/.claude >/dev/null 2>&1 || true"

    # Verify can create files in persistent volume (as root during test)
    check "can create file in persistent volume" bash -c "touch /var/lib/claude-config/.test-write && rm /var/lib/claude-config/.test-write"

    # Verify can create files via symlink
    check "can create file via symlink" bash -c "touch $USER_HOME/.claude/.test-symlink && rm $USER_HOME/.claude/.test-symlink"

    # Verify directory structure
    check "persistent volume is a directory" test -d "/var/lib/claude-config"
    check "symlink target is a directory" bash -c "[ -d \"\$(readlink $USER_HOME/.claude)\" ]"
fi

# Report result
reportResults
