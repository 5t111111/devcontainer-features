#!/bin/bash

set -e

source dev-container-features-test-lib

check "bash.bashrc contains mise activate (path)" bash -c 'grep -q "mise activate bash" /etc/bash.bashrc'
check "bash.bashrc does not use --shims" bash -c '! grep -q "mise activate bash --shims" /etc/bash.bashrc'
check "zsh profile contains mise activate (path)" bash -c 'grep -q "mise activate zsh" /etc/zsh/zshrc'
check "zsh profile does not use --shims" bash -c '! grep -q "mise activate zsh --shims" /etc/zsh/zshrc'

reportResults
