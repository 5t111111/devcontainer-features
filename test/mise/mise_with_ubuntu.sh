#!/bin/bash

set -e

source dev-container-features-test-lib

# Ubuntu compatibility smoke test
check "mise is installed on Ubuntu" command -v mise
check "mise --version exits successfully" mise --version

reportResults
