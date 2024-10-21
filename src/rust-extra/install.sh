#!/usr/bin/env bash

set -e

# Set umask to 002 to ensure that files are created with group write permissions
# See: https://github.com/devcontainers/features/blob/125f6b0071597a59f3ccbefaf9145b5867528ae3/src/rust/install.sh#L163-L166
umask 002

echo "Installing Cargo B(inary)Install..."

curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

echo "Installing Cargo binaries..."

cargo binstall cargo-audit --locked -y
cargo binstall cargo-edit --locked -y
cargo binstall cargo-expand --locked -y
cargo binstall cargo-watch --locked -y

echo "Cleaning up build artifacts..."

rm -rf "${CARGO_HOME}/registry"

echo "Ensure CARGO_HOME permissions are correct. This may take a few moments..."

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
chown -R ${USERNAME}:rustlang "${CARGO_HOME}"
find "${CARGO_HOME}" -type d -exec chmod 2775 {} \;
find "${CARGO_HOME}" -type f -exec chmod 775 {} \;
