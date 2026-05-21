#!/usr/bin/env bash

set -e

# safe-chain Installer
# Installs the safe-chain binary from Aikido Security with SHA256 checksum verification.
# Rather than piping the official install script to sh, this feature:
#   1. Downloads the official install script for the target release to extract its embedded checksums
#   2. Downloads the binary directly over HTTPS with TLS 1.2+ enforcement
#   3. Verifies the binary against those checksums before installing

echo "Installing safe-chain..."

GITHUB_API="https://api.github.com/repos/AikidoSec/safe-chain/releases"
GITHUB_RELEASES="https://github.com/AikidoSec/safe-chain/releases/download"
INSTALL_DIR="/usr/local/bin"
SAFE_CHAIN_FEATURE_DIR="/usr/local/share/safe-chain-feature"
DOWNLOAD_DIR=$(mktemp -d /tmp/safe-chain-install-XXXXXXXX)

cleanup() {
  rm -rf "$DOWNLOAD_DIR"
}
trap cleanup EXIT

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required but not installed." >&2
  exit 1
fi

# Download function with security: always use HTTPS and enforce minimum TLS version
download_file() {
  local url="$1"
  local output="$2"

  # Security: --proto '=https' enforces HTTPS-only
  # Security: --tlsv1.2 enforces minimum TLS version
  if [ -n "$output" ]; then
    curl -fsSL --proto '=https' --tlsv1.2 -o "$output" "$url"
  else
    curl -fsSL --proto '=https' --tlsv1.2 "$url"
  fi
}

# Detect OS
case "$(uname -s)" in
Linux) os="linux" ;;
Darwin) os="macos" ;;
*)
  echo "Error: Unsupported operating system: $(uname -s)" >&2
  exit 1
  ;;
esac

# Detect CPU architecture
case "$(uname -m)" in
x86_64 | amd64) arch="x64" ;;
aarch64 | arm64) arch="arm64" ;;
*)
  echo "Error: Unsupported architecture: $(uname -m)" >&2
  exit 1
  ;;
esac

# Use static Linux builds for maximum container compatibility (no glibc dependency)
if [ "$os" = "linux" ]; then
  platform="linuxstatic-${arch}"
else
  platform="${os}-${arch}"
fi

echo "Detected platform: ${platform}"

# Fetch latest release version tag
echo "Fetching latest release information..."
release_json=$(download_file "${GITHUB_API}/latest" "")
if [ -z "$release_json" ]; then
  echo "Error: Failed to fetch release information from GitHub API." >&2
  exit 1
fi

if [[ $release_json =~ \"tag_name\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  version_tag="${BASH_REMATCH[1]}"
else
  echo "Error: Could not determine latest version tag from GitHub API response." >&2
  exit 1
fi

# Security: validate version tag format (e.g. 1.5.3)
if ! [[ "$version_tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Unexpected version tag format: ${version_tag}" >&2
  exit 1
fi

echo "Version: ${version_tag}"

# Download the official install script to extract its embedded SHA256 checksums.
# The release install script has checksums baked in by the release pipeline for each
# platform binary. Extracting them avoids hardcoding version-specific hashes here.
echo "Downloading official install script to extract checksums..."
install_script_path="$DOWNLOAD_DIR/install-safe-chain.sh"
if ! download_file "$GITHUB_RELEASES/$version_tag/install-safe-chain.sh" "$install_script_path"; then
  echo "Error: Failed to download install script." >&2
  exit 1
fi

# Derive the checksum variable name from the platform string.
# e.g. "linuxstatic-x64" → "LINUXSTATIC_X64" → "SHA256_LINUXSTATIC_X64"
platform_upper=$(echo "$platform" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
checksum_var="SHA256_${platform_upper}"

# Extract the checksum value; format in install script: SHA256_LINUXSTATIC_X64="<hash>"
expected_checksum=$(grep "^${checksum_var}=" "$install_script_path" | cut -d'"' -f2)

if [ -z "$expected_checksum" ]; then
  echo "Error: Checksum for platform '${platform}' (${checksum_var}) not found in install script." >&2
  exit 1
fi

# Security: validate checksum format (SHA256 = 64 lowercase hex characters)
if ! [[ "$expected_checksum" =~ ^[a-f0-9]{64}$ ]]; then
  echo "Error: Invalid checksum format extracted for ${checksum_var}: '${expected_checksum}'" >&2
  exit 1
fi

echo "Expected SHA256: ${expected_checksum}"

# Download the platform binary directly from the release
binary_name="safe-chain-${platform}"
binary_path="$DOWNLOAD_DIR/$binary_name"
echo "Downloading safe-chain binary (${binary_name})..."
if ! download_file "$GITHUB_RELEASES/$version_tag/$binary_name" "$binary_path"; then
  echo "Error: Failed to download binary." >&2
  exit 1
fi

# Security: verify SHA256 checksum of the downloaded binary
echo "Verifying checksum..."
if [ "$os" = "darwin" ]; then
  actual_checksum=$(shasum -a 256 "$binary_path" | awk '{print $1}')
else
  actual_checksum=$(sha256sum "$binary_path" | awk '{print $1}')
fi

if [ "$actual_checksum" != "$expected_checksum" ]; then
  echo "Error: Checksum verification failed!" >&2
  echo "Expected: ${expected_checksum}" >&2
  echo "Actual:   ${actual_checksum}" >&2
  exit 1
fi

echo "Checksum verified successfully."

# Install the binary to the system PATH
mkdir -p "$INSTALL_DIR"
install -m 0755 "$binary_path" "$INSTALL_DIR/safe-chain"

echo "safe-chain installed to ${INSTALL_DIR}/safe-chain"

# TODO: Workaround for https://github.com/AikidoSec/safe-chain/issues/450 (regression in v1.5.0+):
# safe-chain v1.5.0+ crashes with EACCES when a non-root user runs 'safe-chain setup'
# because it tries to create /usr/local/certs and /usr/local/scripts. Running setup here
# as root creates those system directories and files.
echo "Running safe-chain setup..."
safe-chain setup

# Add shell integration to system-wide shell profiles so all users get it automatically,
# without needing a postCreateCommand or knowing the container user's home directory.
# (Part of the workaround for https://github.com/AikidoSec/safe-chain/issues/450 —
# we do this here as root instead of letting the user run 'safe-chain setup' themselves.)
BASH_INIT_LINE='source /usr/local/scripts/init-posix.sh # Safe-chain bash initialization script'
ZSH_INIT_LINE='source /usr/local/scripts/init-posix.sh # Safe-chain Zsh initialization script'

if [ -f /etc/bash.bashrc ] && ! grep -qF 'init-posix.sh' /etc/bash.bashrc; then
  echo "$BASH_INIT_LINE" >>/etc/bash.bashrc
  echo "Added safe-chain shell integration to /etc/bash.bashrc"
fi

if [ -f /etc/zsh/zshrc ] && ! grep -qF 'init-posix.sh' /etc/zsh/zshrc; then
  echo "$ZSH_INIT_LINE" >>/etc/zsh/zshrc
  echo "Added safe-chain shell integration to /etc/zsh/zshrc"
fi

echo ""
echo "safe-chain ${version_tag} installed successfully!"
