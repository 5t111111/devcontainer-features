#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for persistence disabled
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"
check "claude binary has content" test -s "$(command -v claude)"

# Verify persistence is NOT enabled
check "persistent volume not mounted or empty" bash -c "[ ! -d /var/lib/claude-config ] || [ -z \"\$(ls -A /var/lib/claude-config 2>/dev/null)\" ]"

# USER_HOME should exist but not be a symlink
USER_HOME="/home/vscode"
if [ -d "$USER_HOME" ]; then
    check ".claude is NOT a symlink" bash -c "[ ! -L $USER_HOME/.claude ]"
fi

# Report result
reportResults
