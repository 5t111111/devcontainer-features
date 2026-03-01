#!/usr/bin/env bash

set -e

# mise (mise-en-place) Installer
# Installs the latest mise CLI binary with GPG signature verification
# and SHA256 checksum verification.

# mise release signing key fingerprint (https://mise.jdx.dev/installing-mise.html)
MISE_GPG_KEY="24853EC9F655CE80B48E6C3A8B81C9D17413A06D"
MISE_GPG_KEYSERVER="hkps://keys.openpgp.org"

# Feature option: VERSION is set by the devcontainer feature runtime
REQUESTED_VERSION="${VERSION:-"latest"}"

echo "Installing mise-en-place (${REQUESTED_VERSION})..."

INSTALL_DIR="/usr/local/bin"
GITHUB_API="https://api.github.com/repos/jdx/mise/releases"
GITHUB_RELEASES="https://github.com/jdx/mise/releases/download"
DOWNLOAD_DIR=$(mktemp -d /tmp/mise-install-XXXXXXXX)
GNUPGHOME=$(mktemp -d /tmp/mise-gnupg-XXXXXXXX)
export GNUPGHOME
chmod 700 "$GNUPGHOME"

# Cleanup function to remove temporary files on exit
cleanup() {
    rm -rf "$DOWNLOAD_DIR" "$GNUPGHOME"
}
trap cleanup EXIT

# Resolve and validate version tag for explicit versions as early as possible
# so invalid input fails fast without requiring network/GPG dependencies.
if [ "$REQUESTED_VERSION" = "latest" ]; then
    version_tag=""
else
    # Normalize: accept both "v2026.2.23" and "2026.2.23"
    if [[ "$REQUESTED_VERSION" =~ ^[0-9] ]]; then
        version_tag="v${REQUESTED_VERSION}"
    else
        version_tag="$REQUESTED_VERSION"
    fi

    if ! [[ "$version_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Unexpected version tag format: ${version_tag}" >&2
        exit 1
    fi
fi

# Check for required tools
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed." >&2
    exit 1
fi

# Ensure gpg is available; install via apt on Debian/Ubuntu if needed
if ! command -v gpg >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        echo "gpg not found; installing via apt-get..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y -q
        apt-get install -y -q --no-install-recommends gnupg
    else
        echo "Error: gpg is required but not installed, and apt-get is not available." >&2
        echo "Please install gnupg and retry." >&2
        exit 1
    fi
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
    Darwin) os="macos" ;;
    Linux)  os="linux" ;;
    *)
        echo "Error: Unsupported operating system: $(uname -s)" >&2
        exit 1
        ;;
esac

# Detect CPU architecture
case "$(uname -m)" in
    x86_64|amd64)  arch="x64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
        echo "Error: Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

platform="${os}-${arch}"

echo "Detected platform: ${platform}"

# Import mise release signing key
echo "Importing mise GPG signing key (${MISE_GPG_KEY})..."
if ! gpg_output=$(gpg --batch --keyserver "$MISE_GPG_KEYSERVER" --recv-keys "$MISE_GPG_KEY" 2>&1); then
    echo "Error: Failed to import GPG key from ${MISE_GPG_KEYSERVER}." >&2
    echo "$gpg_output" >&2
    exit 1
fi

# Resolve version tag
if [ "$REQUESTED_VERSION" = "latest" ]; then
    echo "Fetching latest release information..."
    release_json=$(download_file "${GITHUB_API}/latest" "")
    if [ -z "$release_json" ]; then
        echo "Error: Failed to fetch release information from GitHub API." >&2
        exit 1
    fi
    # Extract tag_name using bash regex (avoids dependency on jq)
    if [[ $release_json =~ \"tag_name\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
        version_tag="${BASH_REMATCH[1]}"
    else
        echo "Error: Could not determine latest version tag from GitHub API response." >&2
        exit 1
    fi
fi

# Security: validate version tag format (e.g. v2026.2.23)
if ! [[ "$version_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Unexpected version tag format: ${version_tag}" >&2
    exit 1
fi

echo "Version: ${version_tag}"

# Construct asset names
binary_name="mise-${version_tag}-${platform}"
# SHASUMS256.asc is a GPG clearsign file: checksum data + inline PGP signature
checksums_asc_name="SHASUMS256.asc"

# Download the GPG clearsign checksum file
echo "Downloading checksum file (${checksums_asc_name})..."
checksums_asc_path="$DOWNLOAD_DIR/$checksums_asc_name"
if ! download_file "$GITHUB_RELEASES/$version_tag/$checksums_asc_name" "$checksums_asc_path"; then
    echo "Error: Failed to download checksum file." >&2
    exit 1
fi

# Security: Verify GPG clearsign signature
# For clearsign format, gpg --verify takes only the .asc file (no separate data file)
echo "Verifying GPG signature of checksum file..."
if ! gpg_output=$(gpg --batch --verify "$checksums_asc_path" 2>&1); then
    echo "Error: GPG signature verification of ${checksums_asc_name} failed!" >&2
    echo "The checksum file may have been tampered with." >&2
    echo "$gpg_output" >&2
    exit 1
fi
echo "GPG signature verified successfully."

# Extract expected SHA256 checksum for this platform binary
# SHASUMS256.asc content lines format: "<sha256>  ./mise-<version>-<platform>"
target_entry="./${binary_name}"
expected_matches=$(awk -v target="$target_entry" '$2 == target { print $1 }' "$checksums_asc_path")
match_count=$(printf '%s\n' "$expected_matches" | awk 'NF { c++ } END { print c+0 }')

if [ "$match_count" -eq 0 ]; then
    echo "Error: Checksum for ${binary_name} not found in ${checksums_asc_name}." >&2
    echo "Available entries:" >&2
    grep "mise-.*-${platform}" "$checksums_asc_path" >&2 || true
    exit 1
fi

if [ "$match_count" -gt 1 ]; then
    echo "Error: Multiple checksum entries found for ${binary_name} in ${checksums_asc_name}." >&2
    echo "Potential tampering or malformed checksum file detected." >&2
    printf '%s\n' "$expected_matches" >&2
    exit 1
fi

expected_checksum="$expected_matches"

# Security: validate checksum format (SHA256 = 64 hex lowercase characters)
if ! [[ "$expected_checksum" =~ ^[a-f0-9]{64}$ ]]; then
    echo "Error: Invalid checksum format: ${expected_checksum}" >&2
    exit 1
fi

echo "Expected SHA256: ${expected_checksum}"

# Download the mise binary
echo "Downloading mise binary: ${binary_name}..."
binary_path="$DOWNLOAD_DIR/$binary_name"
if ! download_file "$GITHUB_RELEASES/$version_tag/$binary_name" "$binary_path"; then
    echo "Error: Failed to download mise binary." >&2
    exit 1
fi

# Security: Verify SHA256 checksum of the binary
echo "Verifying binary checksum..."
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

# Install the binary
mkdir -p "$INSTALL_DIR"
install -m 0755 "$binary_path" "$INSTALL_DIR/mise"

echo ""
echo "mise ${version_tag} installed successfully to ${INSTALL_DIR}/mise"

# Feature options for post-install configuration
ACTIVATE="${ACTIVATE:-"path"}"
TRUST="${TRUST:-"true"}"
INSTALL_TOOLS="${INSTALL:-"true"}"

# Security: validate activate option value
case "$ACTIVATE" in
    path|shims|none) ;;
    *)
        echo "Error: Invalid activate option: '${ACTIVATE}'. Must be 'path', 'shims', or 'none'." >&2
        exit 1
        ;;
esac

# install implies trust
if [ "$INSTALL_TOOLS" = "true" ]; then
    TRUST="true"
fi

# Configure shell activation by appending to system-wide shell profiles
activate_in_shell() {
    local shell_name="$1"
    local rc_file="$2"

    if ! command -v "$shell_name" >/dev/null 2>&1; then
        echo "  (${shell_name} not found, skipping)"
        return
    fi
    if [ ! -f "$rc_file" ]; then
        echo "  (${rc_file} not found, skipping)"
        return
    fi

    local activate_expr
    case "$ACTIVATE" in
        path)  activate_expr="eval \"\$(mise activate ${shell_name})\"" ;;
        shims) activate_expr="eval \"\$(mise activate ${shell_name} --shims)\"" ;;
    esac

    printf '\n%s\n' "$activate_expr" >> "$rc_file"
    echo "  Added mise ${ACTIVATE} activation to ${rc_file}"
}

if [ "$ACTIVATE" != "none" ]; then
    echo "Configuring mise shell activation (${ACTIVATE})..."
    activate_in_shell bash /etc/bash.bashrc
    activate_in_shell zsh /etc/zsh/zshrc
else
    echo ""
    echo "To activate mise, add one of the following to your shell profile:"
    echo "  bash: eval \"\$(mise activate bash)\""
    echo "  zsh:  eval \"\$(mise activate zsh)\""
    echo "  fish: mise activate fish | source"
fi

# Create the postCreateCommand script (runs after container creation, in workspace context)
MISE_FEATURE_DIR="/usr/local/share/mise-feature"
POST_CREATE_SCRIPT="${MISE_FEATURE_DIR}/post_create_command.sh"
mkdir -p "$MISE_FEATURE_DIR"

printf '#!/usr/bin/env bash\nset -e\n' > "$POST_CREATE_SCRIPT"

if [ "$TRUST" = "true" ]; then
    cat >> "$POST_CREATE_SCRIPT" << 'SCRIPT_EOF'
# Trust the workspace mise.toml
if command -v mise >/dev/null 2>&1; then
    echo "Running: mise trust --all --yes"
    mise trust --all --yes
fi
SCRIPT_EOF
fi

if [ "$INSTALL_TOOLS" = "true" ]; then
    cat >> "$POST_CREATE_SCRIPT" << 'SCRIPT_EOF'
# Install workspace tools defined in mise.toml
if command -v mise >/dev/null 2>&1; then
    echo "Running: mise install --yes"
    mise install --yes
fi
SCRIPT_EOF
fi

chmod +x "$POST_CREATE_SCRIPT"
