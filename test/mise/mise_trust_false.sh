#!/bin/bash

set -e

source dev-container-features-test-lib

POST_CREATE="/usr/local/share/mise-feature/post_create_command.sh"

check "post-create script exists and is executable" test -x "$POST_CREATE"
check "post-create does not contain mise trust (trust=false)" bash -c "! grep -q 'mise trust' $POST_CREATE"
check "post-create does not contain mise install (install=false)" bash -c "! grep -q 'mise install' $POST_CREATE"

reportResults
