#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# This test verifies that existing .claude directory is migrated to persistent volume

# Feature-specific tests for migration
check "claude command exists" command -v claude
check "persistent volume directory exists" test -d "/var/lib/claude-config"

USER_HOME="/home/vscode"
CLAUDE_DIR="$USER_HOME/.claude"

# Create a test file in .claude directory BEFORE installation to simulate existing data
# Note: This test assumes the feature's install.sh has already run during container build
# We're verifying that if there was pre-existing data, it would have been migrated

if [ -d "$USER_HOME" ]; then
    # Check that .claude is now a symlink (migration happened)
    check ".claude is a symlink after migration" test -L "$CLAUDE_DIR"
    check ".claude points to persistent volume" bash -c "[ \"\$(readlink -f $CLAUDE_DIR)\" = \"/var/lib/claude-config\" ]"

    # Create a test file via symlink to verify it works (as root during test)
    check "can create file in persistent volume via symlink" bash -c "echo 'test' > $CLAUDE_DIR/test-migration.txt"
    check "file exists in persistent volume" test -f "/var/lib/claude-config/test-migration.txt"
    check "file accessible via symlink" test -f "$CLAUDE_DIR/test-migration.txt"

    # Verify content
    check "file content is correct" bash -c "cat $CLAUDE_DIR/test-migration.txt | grep -q 'test'"

    # Cleanup
    rm -f "$CLAUDE_DIR/test-migration.txt"

    # Verify ownership
    check "persistent volume owned by vscode" bash -c "stat -c '%U' /var/lib/claude-config | grep 'vscode'"

    # Verify permissions allow read/write (test as root)
    check "can read persistent volume" bash -c "ls /var/lib/claude-config >/dev/null"
    check "can write to persistent volume" bash -c "touch /var/lib/claude-config/.test && rm /var/lib/claude-config/.test"
fi

# Report result
reportResults
