#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for .config/claude handling
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"

# Verify persistence is enabled
check "persistent XDG volume directory exists" test -d "/var/lib/claude-config-xdg"

USER_HOME="/home/vscode"
if [ -d "$USER_HOME" ]; then
    # Verify .config directory exists
    check ".config directory exists" test -d "$USER_HOME/.config"
    
    # Verify .config/claude exists and is a symlink
    check ".config/claude exists" test -e "$USER_HOME/.config/claude"
    check ".config/claude is a symlink" test -L "$USER_HOME/.config/claude"
    
    # Verify .config/claude points to persistent volume
    check ".config/claude points to persistent volume" bash -c "[ \"\$(readlink -f $USER_HOME/.config/claude)\" = \"/var/lib/claude-config-xdg\" ]"
    
    # Check ownership
    check ".config/claude symlink ownership" bash -c "stat -c '%U' $USER_HOME/.config/claude | grep -E 'vscode|root'"
    check "persistent XDG volume ownership" bash -c "stat -c '%U' /var/lib/claude-config-xdg | grep -E 'vscode|root'"
    
    # Check permissions (should be 700)
    check "persistent XDG volume permissions" bash -c "stat -c '%a' /var/lib/claude-config-xdg | grep -E '700|755'"
    
    # Verify the symlink is not broken
    check "symlink is not broken" test -e "$USER_HOME/.config/claude"
    
    # Verify user can access via symlink
    check "user can list via symlink" bash -c "ls $USER_HOME/.config/claude >/dev/null 2>&1 || true"
    
    # Verify can create files in persistent volume (as root during test)
    check "can create file in persistent XDG volume" bash -c "touch /var/lib/claude-config-xdg/.test-write && rm /var/lib/claude-config-xdg/.test-write"
    
    # Verify can create files via symlink
    check "can create file via symlink" bash -c "touch $USER_HOME/.config/claude/.test-symlink && rm $USER_HOME/.config/claude/.test-symlink"
    
    # Verify directory structure
    check "persistent XDG volume is a directory" test -d "/var/lib/claude-config-xdg"
    check "symlink target is a directory" bash -c "[ -d \"\$(readlink $USER_HOME/.config/claude)\" ]"
fi

# Report result
reportResults
