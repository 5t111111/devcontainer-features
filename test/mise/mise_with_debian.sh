#!/bin/bash

set -e

source dev-container-features-test-lib

POST_CREATE="/usr/local/share/mise-feature/post_create_command.sh"

check "mise is installed" command -v mise
check "mise binary is at /usr/local/bin/mise" test -x /usr/local/bin/mise
check "mise --version exits successfully" mise --version
check "mise --version output contains version" bash -c "mise --version 2>&1 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+'"
check "post-create script exists and is executable" test -x "$POST_CREATE"
check "post-create contains mise trust (trust=true by default)" bash -c "grep -q 'mise trust' $POST_CREATE"
check "post-create contains mise install (install=true by default)" bash -c "grep -q 'mise install' $POST_CREATE"

reportResults
