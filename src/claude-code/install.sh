#!/usr/bin/env bash

set -e

# Claude Code Installer
# This script installs the latest native version of Claude Code CLI
# with enhanced security measures including checksum verification

VERSION="${VERSION:-"latest"}"

echo "Installing Claude Code (${VERSION})..."

# Security: Use only official GCS bucket over HTTPS
GCS_BUCKET="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
DOWNLOAD_DIR="/tmp/claude-install-$$"

# Create temporary download directory
mkdir -p "$DOWNLOAD_DIR"

# Cleanup function to remove temporary files
cleanup() {
    rm -rf "$DOWNLOAD_DIR"
}
trap cleanup EXIT

# Check for curl (required)
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed" >&2
    exit 1
fi

# Download function with security: always use HTTPS and verify SSL
download_file() {
    local url="$1"
    local output="$2"

    # Security: Use --proto '=https' to enforce HTTPS only
    # Security: Use --tlsv1.2 to enforce minimum TLS version
    if [ -n "$output" ]; then
        curl -fsSL --proto '=https' --tlsv1.2 -o "$output" "$url"
    else
        curl -fsSL --proto '=https' --tlsv1.2 "$url"
    fi
}

# Detect platform
case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux) os="linux" ;;
    *)
        echo "Error: Windows is not supported in this container environment" >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    x86_64|amd64) arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
        echo "Error: Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

# Detect Rosetta 2 on macOS: prefer native arm64 binary
if [ "$os" = "darwin" ] && [ "$arch" = "x64" ]; then
    if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = "1" ]; then
        arch="arm64"
    fi
fi

# Check for musl on Linux
if [ "$os" = "linux" ]; then
    if [ -f /lib/libc.musl-x86_64.so.1 ] || [ -f /lib/libc.musl-aarch64.so.1 ] || ldd /bin/ls 2>&1 | grep -q musl; then
        platform="linux-${arch}-musl"
    else
        platform="linux-${arch}"
    fi
else
    platform="${os}-${arch}"
fi

echo "Detected platform: ${platform}"

# Download version information
echo "Fetching version information..."
version_tag=$(download_file "$GCS_BUCKET/${VERSION}")

if [ -z "$version_tag" ]; then
    echo "Error: Failed to fetch version information" >&2
    exit 1
fi

echo "Version: ${version_tag}"

# Download and parse manifest for checksum
echo "Downloading manifest for checksum verification..."
manifest_json=$(download_file "$GCS_BUCKET/$version_tag/manifest.json")

if [ -z "$manifest_json" ]; then
    echo "Error: Failed to download manifest" >&2
    exit 1
fi

# Extract checksum from manifest using bash regex (same approach as official bootstrap.sh)
# Security: Validate checksum format (SHA256 = 64 hex characters)
if [[ $manifest_json =~ \"$platform\"[^}]*\"checksum\"[[:space:]]*:[[:space:]]*\"([a-f0-9]{64})\" ]]; then
    checksum="${BASH_REMATCH[1]}"
else
    echo "Error: Platform $platform not found in manifest or invalid checksum" >&2
    echo "DEBUG: Looking for platform key: $platform" >&2
    echo "DEBUG: Available platforms:" >&2
    echo "$manifest_json" | grep -o '"darwin-[^"]*"\|"linux-[^"]*"' | tr -d '"' >&2
    exit 1
fi

if [ -z "$checksum" ] || [ ${#checksum} -ne 64 ]; then
    echo "Error: Invalid checksum format" >&2
    exit 1
fi

echo "Expected checksum: ${checksum}"

# Download binary
binary_path="$DOWNLOAD_DIR/claude-${version_tag}-${platform}"
echo "Downloading Claude Code binary..."

if ! download_file "$GCS_BUCKET/$version_tag/$platform/claude" "$binary_path"; then
    echo "Error: Download failed" >&2
    exit 1
fi

# Security: Verify checksum
echo "Verifying checksum..."
if [ "$os" = "darwin" ]; then
    actual_checksum=$(shasum -a 256 "$binary_path" | cut -d' ' -f1)
else
    actual_checksum=$(sha256sum "$binary_path" | cut -d' ' -f1)
fi

if [ "$actual_checksum" != "$checksum" ]; then
    echo "Error: Checksum verification failed!" >&2
    echo "Expected: $checksum" >&2
    echo "Actual:   $actual_checksum" >&2
    exit 1
fi

echo "Checksum verified successfully!"

# Make binary executable
chmod +x "$binary_path"

# Install to system-wide location for immediate availability
# This ensures the binary is available in PATH without shell restart
INSTALL_DIR="/usr/local/bin"
mkdir -p "$INSTALL_DIR"

echo "Installing Claude Code to ${INSTALL_DIR}..."
cp "$binary_path" "$INSTALL_DIR/claude"
chmod +x "$INSTALL_DIR/claude"

# Run claude install to set up additional configuration (optional)
# Note: This may create config files in user directory, but the binary is already in PATH
if command -v claude >/dev/null 2>&1; then
    echo "Setting up Claude Code configuration..."
    claude install ${VERSION} 2>/dev/null || true
fi

# Setup user configuration persistence if requested
PERSIST_USER_CONFIG="${PERSISTUSERCONFIG:-false}"

if [ "$PERSIST_USER_CONFIG" = "true" ]; then
    echo ""
    echo "Setting up user configuration persistence..."

    # Determine the user
    USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
    if [ "$USERNAME" = "automatic" ]; then
        # Try common non-root users
        if id -u vscode >/dev/null 2>&1; then
            USERNAME="vscode"
        elif id -u node >/dev/null 2>&1; then
            USERNAME="node"
        elif id -u codespace >/dev/null 2>&1; then
            USERNAME="codespace"
        else
            USERNAME="root"
        fi
    fi

    USER_HOME=$(eval echo ~$USERNAME)
    CLAUDE_CONFIG_DIR="$USER_HOME/.claude"
    CLAUDE_JSON_FILE="$USER_HOME/.claude.json"
    PERSISTENT_DIR="/var/lib/claude-config"

    # Ensure persistent directory exists with proper permissions
    mkdir -p "$PERSISTENT_DIR"

    # If .claude directory already exists and is not a symlink, migrate it
    if [ -d "$CLAUDE_CONFIG_DIR" ] && [ ! -L "$CLAUDE_CONFIG_DIR" ]; then
        echo "Migrating existing .claude directory to persistent volume..."
        # Copy contents if any
        if [ "$(ls -A $CLAUDE_CONFIG_DIR 2>/dev/null)" ]; then
            cp -rp "$CLAUDE_CONFIG_DIR/"* "$PERSISTENT_DIR/" 2>/dev/null || true
        fi
        rm -rf "$CLAUDE_CONFIG_DIR"
    fi

    # Create symlink if it doesn't exist
    if [ ! -e "$CLAUDE_CONFIG_DIR" ]; then
        ln -s "$PERSISTENT_DIR" "$CLAUDE_CONFIG_DIR"
        echo "Created symlink: $CLAUDE_CONFIG_DIR -> $PERSISTENT_DIR"
    fi

    # Handle ~/.claude.json file
    # This file needs to be persisted and symlinked according to the article
    if [ -f "$CLAUDE_JSON_FILE" ] && [ ! -L "$CLAUDE_JSON_FILE" ]; then
        echo "Migrating existing .claude.json to persistent volume..."
        cp "$CLAUDE_JSON_FILE" "$PERSISTENT_DIR/config.json"
        rm -f "$CLAUDE_JSON_FILE"
    fi

    # Create config.json in persistent directory if it doesn't exist
    if [ ! -f "$PERSISTENT_DIR/config.json" ]; then
        echo "Creating empty config.json in persistent volume..."
        echo "{}" > "$PERSISTENT_DIR/config.json"
    fi

    # Create symlink from ~/.claude.json to ~/.claude/config.json
    if [ ! -e "$CLAUDE_JSON_FILE" ]; then
        ln -s "$PERSISTENT_DIR/config.json" "$CLAUDE_JSON_FILE"
        echo "Created symlink: $CLAUDE_JSON_FILE -> $PERSISTENT_DIR/config.json"
    fi

    # Set proper ownership and permissions
    chown -R "$USERNAME:$USERNAME" "$PERSISTENT_DIR" 2>/dev/null || chown -R "$USERNAME" "$PERSISTENT_DIR"
    chmod -R 700 "$PERSISTENT_DIR"

    # Ensure symlink ownership (use -h to not follow symlink)
    chown -h "$USERNAME:$USERNAME" "$CLAUDE_CONFIG_DIR" 2>/dev/null || chown -h "$USERNAME" "$CLAUDE_CONFIG_DIR"
    chown -h "$USERNAME:$USERNAME" "$CLAUDE_JSON_FILE" 2>/dev/null || chown -h "$USERNAME" "$CLAUDE_JSON_FILE"

    echo "✅ User configuration persistence enabled."
    echo "   Config data (including authentication) will be stored in: $PERSISTENT_DIR"
    echo "   Accessible via:"
    echo "     - $CLAUDE_CONFIG_DIR"
    echo "     - $CLAUDE_JSON_FILE"
else
    echo ""
    echo "ℹ️  User configuration persistence is disabled."
    echo "   You will need to log in again after container rebuilds."
    echo "   To enable persistence (default behavior), remove:"
    echo "   \"persistUserConfig\": false"
fi

echo ""
echo "✅ Claude Code ${version_tag} installed successfully!"
echo ""
echo "Run 'claude' to get started."
