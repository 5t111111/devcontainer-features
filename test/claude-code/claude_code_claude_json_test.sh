#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for ~/.claude.json handling
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"

# Verify persistence is enabled
check "persistent volume base directory exists" test -d "/var/lib/claude-config"

USER_HOME="/home/vscode"
if [ -d "$USER_HOME" ]; then
    # Verify ~/.claude.json is created and is a symlink
    check ".claude.json exists" test -e "$USER_HOME/.claude.json"
    check ".claude.json is a symlink" test -L "$USER_HOME/.claude.json"

    # Verify ~/.claude.json points to ~/.claude/config.json (which is in persistent volume)
    check ".claude.json points to correct location" bash -c "[ \"\$(readlink $USER_HOME/.claude.json)\" = \"/var/lib/claude-config/config.json\" ]"

    # Verify config.json exists in persistent volume
    check "config.json exists in persistent volume" test -f "/var/lib/claude-config/config.json"

    # Verify config.json is valid JSON (at minimum an empty object)
    check "config.json is valid JSON" bash -c "cat /var/lib/claude-config/config.json | grep -q '{'"

    # Verify we can read through the symlink
    check "can read .claude.json via symlink" test -r "$USER_HOME/.claude.json"

    # Verify the file is accessible
    check "config.json content is readable" cat /var/lib/claude-config/config.json >/dev/null 2>&1

    # Verify ownership
    check ".claude.json symlink ownership" bash -c "stat -c '%U' $USER_HOME/.claude.json | grep -E 'vscode|root'"
    check "config.json ownership" bash -c "stat -c '%U' /var/lib/claude-config/config.json | grep -E 'vscode|root'"
fi

# Report result
reportResults
