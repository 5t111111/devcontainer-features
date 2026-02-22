#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for node user
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"
check "claude binary has content" test -s "$(command -v claude)"

# Verify persistence is enabled with node user
check "persistent volume directory exists" test -d "/var/lib/claude-config"

# Check that the feature correctly detected 'node' user
NODE_HOME="/home/node"
if [ -d "$NODE_HOME" ]; then
    check "node user home exists" test -d "$NODE_HOME"
    check ".claude exists in node home" test -e "$NODE_HOME/.claude"
    check ".claude is a symlink" test -L "$NODE_HOME/.claude"
    check ".claude points to persistent volume" bash -c "[ \"\$(readlink -f $NODE_HOME/.claude)\" = \"/var/lib/claude-config\" ]"

    # Check ownership - should be 'node' user
    check ".claude symlink owned by node" bash -c "stat -c '%U' $NODE_HOME/.claude | grep 'node'"
    check "persistent volume owned by node" bash -c "stat -c '%U' /var/lib/claude-config | grep 'node'"

    # Verify can write to persistent volume (as root during test)
    check "can write to persistent volume" bash -c "touch /var/lib/claude-config/.test-file && rm /var/lib/claude-config/.test-file"
else
    echo "Warning: /home/node does not exist, skipping node-specific tests"
fi

# Report result
reportResults
