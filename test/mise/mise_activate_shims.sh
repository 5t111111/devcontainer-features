#!/bin/bash

set -e

source dev-container-features-test-lib

check "mise is installed" command -v mise
check "bash.bashrc contains mise activate with --shims" bash -c 'grep -q "mise activate bash --shims" /etc/bash.bashrc'
check "zsh profile contains mise activate with --shims" bash -c 'grep -q "mise activate zsh --shims" /etc/zsh/zshrc'

reportResults
