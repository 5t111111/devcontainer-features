#!/bin/bash

set -e

source dev-container-features-test-lib

check "mise is installed" command -v mise
check "bash.bashrc does not contain mise activate" bash -c '! grep -q "mise activate bash" /etc/bash.bashrc'
check "zsh profile does not contain mise activate" bash -c '! grep -q "mise activate zsh" /etc/zsh/zshrc'

reportResults
