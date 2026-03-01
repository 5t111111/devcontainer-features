#!/bin/bash

set -e

source dev-container-features-test-lib

EXPECTED_VERSION="2026.2.19"

check "mise --version exits successfully" mise --version
check "installed version matches requested version" bash -c "mise --version 2>&1 | grep -F '${EXPECTED_VERSION}'"

reportResults
