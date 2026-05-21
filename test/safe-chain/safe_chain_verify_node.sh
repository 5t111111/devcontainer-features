#!/bin/bash

set -e

source dev-container-features-test-lib

check "safe-chain is installed" command -v safe-chain
check "npm exists in image" command -v npm
check "safe-chain wraps npm correctly" bash -c "safe-chain npm safe-chain-verify 2>&1 | grep -qi 'OK'"

reportResults
