#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for root user
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"
check "claude binary has content" test -s "$(command -v claude)"

# Verify persistence works with root user
check "persistent volume base directory exists" test -d "/var/lib/claude-config"
check "persistent home directory exists" test -d "/var/lib/claude-config/home"

# Check that feature correctly set up for root user
ROOT_HOME="/root"
check "root home exists" test -d "$ROOT_HOME"

if [ -d "$ROOT_HOME" ]; then
    check ".claude exists in root home" test -e "$ROOT_HOME/.claude"
    check ".claude is a symlink" test -L "$ROOT_HOME/.claude"
    check ".claude points to persistent volume" bash -c "[ \"\$(readlink -f $ROOT_HOME/.claude)\" = \"/var/lib/claude-config/home\" ]"

    # Check ownership - should be 'root' user
    check ".claude symlink owned by root" bash -c "stat -c '%U' $ROOT_HOME/.claude | grep 'root'"
    check "persistent volume owned by root" bash -c "stat -c '%U' /var/lib/claude-config/home | grep 'root'"

    # Check permissions
    check "persistent volume permissions" bash -c "stat -c '%a' /var/lib/claude-config | grep '700'"

    # Verify root can write to persistent volume
    check "root can write to persistent volume" bash -c "touch /var/lib/claude-config/home/test-root-file && rm /var/lib/claude-config/home/test-root-file"

    # Verify via symlink
    check "root can write via symlink" bash -c "echo 'test' > $ROOT_HOME/.claude/.test-root && rm $ROOT_HOME/.claude/.test-root"
fi

# Report result
reportResults
