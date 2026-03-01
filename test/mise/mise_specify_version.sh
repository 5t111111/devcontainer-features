#!/bin/bash

set -e

source dev-container-features-test-lib

EXPECTED_VERSION="2026.2.19"

check "mise is installed" command -v mise
check "mise binary is at /usr/local/bin/mise" test -x /usr/local/bin/mise
check "mise --version exits successfully" mise --version
check "mise --version output contains version" bash -c "mise --version 2>&1 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+'"
check "installed version matches requested version" bash -c "mise --version 2>&1 | grep -F '${EXPECTED_VERSION}'"

reportResults
