# Dev Container Features - Agent Guide

This document provides comprehensive guidance for AI agents and developers working on this Dev Container Features repository.

## Project Overview

This repository contains custom [Dev Container Features](https://containers.dev/implementors/features/) that can be used to enhance development containers. Features are self-contained, shareable units of installation code and configuration that can be added to a devcontainer.json file.

**Purpose**: Publish and maintain reusable Dev Container Features for various development tools and environments.

**Repository**: https://github.com/5t111111/devcontainer-features

## What are Dev Container Features?

Dev Container Features are installable units that extend development containers with additional tools, runtimes, and configurations. They follow the [Dev Container Feature specification](https://containers.dev/implementors/features-distribution/) and can be:

- Published to OCI registries (like GitHub Container Registry)
- Referenced in `devcontainer.json` files
- Composed together to build custom development environments
- Tested using the Dev Container CLI

## Repository Structure

```
/
├── src/                          # Feature source code
│   └── <feature-id>/             # Individual feature directory
│       ├── devcontainer-feature.json  # Feature metadata and configuration
│       ├── install.sh            # Installation script
│       ├── README.md             # Feature documentation
│       └── NOTES.md              # Development notes (optional)
├── test/                         # Feature tests
│   └── <feature-id>/             # Test directory for each feature
│       ├── scenarios.json        # Test scenarios (optional)
│       └── test.sh               # Test script
├── AGENTS.md                     # This file
├── LICENSE                       # License file
└── README.md                     # Repository documentation
```

## Current Features

### rust-extra

Enhances the official Rust feature with additional tools and configurations:
- Installs cargo-binstall for faster binary installations
- Adds commonly used Cargo tools: cargo-audit, cargo-edit, cargo-expand, cargo-watch
- Configures VS Code settings for Rust development
- Handles file permissions correctly for container environments

### mise

Installs the [mise](https://mise.jdx.dev/) CLI (mise-en-place), a polyglot tool version manager and task runner:
- Direct binary download from GitHub Releases with GPG clearsign signature verification
- SHA256 checksum verification against the GPG-verified `SHASUMS256.asc`
- Version pinning support (e.g. `v2026.2.23`) or `latest`
- Shell activation configuration for bash/zsh system profiles (`path`, `shims`, or `none`)
- `postCreateCommand` integration: auto-runs `mise trust` and `mise install` on container creation
- Input validation: version tag format, checksum format, `activate` option, and duplicate checksum detection

### claude-code

Installs the latest native version of Claude Code CLI with enhanced security:
- Native binary installation (not the deprecated npm version)
- HTTPS-only downloads with TLS 1.2+ enforcement
- SHA256 checksum verification against official manifest
- Automatic platform detection (Linux/macOS, x64/arm64, glibc/musl)
- Fail-safe installation with automatic cleanup on error

## Creating a New Feature

### 1. Create Feature Directory Structure

```bash
# Create feature directories
mkdir -p src/<feature-id>
mkdir -p test/<feature-id>
```

### 2. Create `devcontainer-feature.json`

This is the feature manifest that defines metadata and configuration:

```json
{
    "id": "<feature-id>",
    "version": "0.1.0",
    "name": "Feature Display Name",
    "documentationURL": "https://github.com/5t111111/devcontainer-features/tree/main/src/<feature-id>",
    "description": "Brief description of what this feature does",
    "options": {
        "version": {
            "type": "string",
            "default": "latest",
            "description": "Version to install"
        }
    },
    "installsAfter": [
        "ghcr.io/devcontainers/features/common-utils"
    ]
}
```

**Key fields**:
- `id`: Unique identifier (lowercase, hyphens allowed)
- `version`: Semantic version (x.y.z)
- `name`: Human-readable name
- `description`: What the feature does
- `options`: User-configurable parameters
- `installsAfter`: Dependencies (other features that must install first)
- `customizations`: IDE-specific settings (VS Code, etc.)
- `onCreateCommand`, `postCreateCommand`, etc.: Lifecycle hooks

### 3. Create `install.sh`

The installation script that runs when the feature is added:

```bash
#!/usr/bin/env bash

set -e  # Exit on error

# Access options from devcontainer-feature.json
VERSION="${VERSION:-"latest"}"

echo "Installing <feature-name> ${VERSION}..."

# Installation logic here

echo "Installation complete!"
```

**Best practices**:
- Use `set -e` to exit on errors
- Set appropriate `umask` for file permissions
- Handle user/group permissions correctly
- Clean up temporary files and caches
- Validate required dependencies
- Provide clear error messages

### 4. Create `README.md`

Document the feature for users:

```markdown
# Feature Name

## Description

What this feature does and why it's useful.

## Usage

```json
{
    "features": {
        "ghcr.io/5t111111/devcontainer-features/<feature-id>:0": {
            "version": "latest"
        }
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | latest | Version to install |

## Notes

Any important information users should know.
```

### 5. Create Test Script

Create `test/<feature-id>/test.sh`:

```bash
#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Test that the feature installed correctly
check "verify installation" <command-to-verify>

# Report results
reportResults
```

### 6. Optional: Test Scenarios

Create `test/<feature-id>/scenarios.json` for multiple test configurations:

```json
{
    "scenario_name": {
        "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
        "features": {
            "<feature-id>": {
                "version": "1.0.0"
            }
        }
    }
}
```

## Testing Features

### Run Tests Locally

```bash
# Test a specific feature
devcontainer features test -f <feature-id> .

# Test with specific remote user
devcontainer features test -f <feature-id> --remote-user vscode .

# Test specific scenario
devcontainer features test -f <feature-id> --scenarios scenario_name .
```

### Test Commands Reference

```bash
# Skip auto-generated tests
devcontainer features test -f <feature-id> --skip-autogenerated .

# Skip duplicate tests
devcontainer features test -f <feature-id> --skip-duplicated .

# Test against specific base image
devcontainer features test -f <feature-id> --base-image ubuntu:22.04 .
```

## Development Workflow

### 1. Plan the Feature

- Identify what tools/configuration the feature should provide
- Check if similar features exist in the [official collection](https://github.com/devcontainers/features)
- Define options and dependencies
- Consider compatibility with different base images

### 2. Implement

- Create directory structure
- Write `devcontainer-feature.json`
- Implement `install.sh` with proper error handling
- Add documentation

### 3. Test

- Write comprehensive test script
- Test with different scenarios and base images
- Verify permissions and file ownership
- Check that cleanup is performed correctly

### 4. Document

- Update feature README.md
- Add usage examples
- Document any gotchas or requirements
- Update repository README.md if needed

### 5. Publish

Features are automatically published to GitHub Container Registry when pushed to the main branch (assuming GitHub Actions is configured).

## Common Patterns and Best Practices

### Permission Handling

```bash
# Get the non-root user
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

# Fix ownership
chown -R ${USERNAME}:groupname /path/to/files

# Set directory permissions
find /path -type d -exec chmod 2775 {} \;

# Set file permissions
find /path -type f -exec chmod 775 {} \;
```

### Installing Binary Tools

Avoid `curl ... | bash` patterns. Download binaries directly and verify with GPG + checksum, following the mise feature as a reference:

```bash
DOWNLOAD_DIR=$(mktemp -d /tmp/tool-install-XXXXXXXX)
GNUPGHOME=$(mktemp -d /tmp/tool-gnupg-XXXXXXXX)
export GNUPGHOME
chmod 700 "$GNUPGHOME"

cleanup() { rm -rf "$DOWNLOAD_DIR" "$GNUPGHOME"; }
trap cleanup EXIT

# Enforce HTTPS and minimum TLS version
download_file() {
    curl -fsSL --proto '=https' --tlsv1.2 -o "$1" "$2"
}

# Import the tool's release signing key
gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "<FINGERPRINT>"

# Download checksum file and verify GPG signature
download_file "$DOWNLOAD_DIR/checksums.asc" "https://example.com/v${VERSION}/checksums.asc"
gpg --batch --verify "$DOWNLOAD_DIR/checksums.asc"

# Extract and validate checksum
expected=$(awk -v t="./tool-${VERSION}" '$2 == t { print $1 }' "$DOWNLOAD_DIR/checksums.asc")
[[ "$expected" =~ ^[a-f0-9]{64}$ ]] || { echo "Invalid checksum format" >&2; exit 1; }

# Download binary and verify
download_file "$DOWNLOAD_DIR/tool" "https://example.com/v${VERSION}/tool"
actual=$(sha256sum "$DOWNLOAD_DIR/tool" | awk '{print $1}')
[ "$actual" = "$expected" ] || { echo "Checksum mismatch" >&2; exit 1; }

install -m 0755 "$DOWNLOAD_DIR/tool" /usr/local/bin/tool
```

### Cleanup

```bash
# Remove build dependencies
apt-get autoremove -y

# Clear package cache
apt-get clean -y
rm -rf /var/lib/apt/lists/*

# Remove temporary files
rm -rf /tmp/*
```

### Environment Variables

```bash
# Check if variable is set, provide default
VERSION="${VERSION:-"latest"}"

# Export for subsequent scripts
export TOOL_HOME=/usr/local/tool
```

## References

- [Dev Container Features Specification](https://containers.dev/implementors/features/)
- [Dev Container CLI](https://github.com/devcontainers/cli)
- [Feature Distribution](https://containers.dev/implementors/features-distribution/)
- [Official Features Repository](https://github.com/devcontainers/features)
- [Feature Test Library](https://github.com/devcontainers/cli/blob/main/docs/features/test.md)

## Troubleshooting

### Tests Fail with Permission Errors

- Check that ownership is set correctly in install.sh
- Verify that the feature runs with the expected user
- Use `--remote-user` flag to test with different users

### Feature Doesn't Install in Order

- Check `installsAfter` in devcontainer-feature.json
- Verify dependency features are available

### Installation Script Fails Silently

- Ensure `set -e` is at the top of install.sh
- Add error handling for critical sections
- Use `|| true` carefully, only when failures are acceptable

## Example Feature Ideas

Here are some ideas for new features to develop:

- **golang-extra**: Additional Go tools (golangci-lint, air, wire, etc.)
- **python-extra**: Python development tools (poetry, ruff, mypy, etc.)
- **node-extra**: Node.js utilities (pnpm, turbo, nx, etc.)
- **docker-compose-extra**: Enhanced Docker Compose with plugins
- **terraform-extra**: Terraform with tflint, terragrunt, etc.
- **kubernetes-extra**: kubectl with useful plugins and tools

---

**Note for AI Agents**: When creating or modifying features, always:
1. Follow the security patterns established in the mise feature (GPG + checksum verification, HTTPS enforcement, input validation)
2. Test thoroughly with multiple scenarios, including negative cases
3. Document all options and behavior clearly
4. Consider security implications (don't run as root unless necessary)
5. Clean up after installation to keep images small
