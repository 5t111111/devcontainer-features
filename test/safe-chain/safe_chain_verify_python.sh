#!/bin/bash

set -e

source dev-container-features-test-lib

check "safe-chain is installed" command -v safe-chain
check "pip exists in image" command -v pip
check "safe-chain wraps pip correctly" bash -c "safe-chain pip safe-chain-verify 2>&1 | grep -qi 'OK'"

reportResults
