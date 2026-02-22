#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests for Alpine Linux (musl)
check "claude command exists" command -v claude
check "claude is executable" test -x "$(command -v claude)"
check "claude binary has content" test -s "$(command -v claude)"

# Verify musl libc is detected
check "running on musl libc" bash -c "ldd /bin/ls 2>&1 | grep -q musl"

# Verify the correct musl binary was installed
check "claude binary is musl" bash -c "ldd /usr/local/bin/claude 2>&1 | grep -q musl || file /usr/local/bin/claude | grep -q 'statically linked'"

# Verify persistence works on Alpine
check "persistent volume base directory exists" test -d "/var/lib/claude-config"
check "persistent home directory exists" test -d "/var/lib/claude-config/home"

USER_HOME="/home/vscode"
if [ -d "$USER_HOME" ]; then
    check ".claude exists" test -e "$USER_HOME/.claude"
    check ".claude is a symlink" test -L "$USER_HOME/.claude"
    check ".claude points to persistent volume" bash -c "[ \"\$(readlink -f $USER_HOME/.claude)\" = \"/var/lib/claude-config/home\" ]"

    # Check permissions on Alpine
    check "persistent volume permissions" bash -c "stat -c '%a' /var/lib/claude-config | grep '700'"
fi

# Report result
reportResults
