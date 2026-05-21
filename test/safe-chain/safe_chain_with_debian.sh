#!/bin/bash

set -e

source dev-container-features-test-lib

check "safe-chain is installed" command -v safe-chain
check "safe-chain binary is at /usr/local/bin/safe-chain" test -x /usr/local/bin/safe-chain
check "safe-chain -v exits successfully" safe-chain -v
check "safe-chain -v output contains version" bash -c "safe-chain -v 2>&1 | grep -E 'safe-chain version'"
check "safe-chain system certs directory exists" test -d /usr/local/certs
check "safe-chain init script exists" test -f /usr/local/scripts/init-posix.sh
check "system bash profile contains safe-chain integration" bash -c "grep -q 'init-posix.sh' /etc/bash.bashrc"

reportResults
