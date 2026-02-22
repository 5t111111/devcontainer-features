## Why This Feature?

The [official Anthropic devcontainer-features](https://github.com/anthropics/devcontainer-features) repository only installs the older npm-based version of Claude Code. This feature installs the modern native binary version which is faster, more efficient, and officially recommended.

## What does this feature do?

### Installing Native Claude Code Binary

This feature installs the native Claude Code CLI by:

- Detecting your platform (Linux/macOS, x64/arm64, glibc/musl)
- Downloading the latest or stable version from the official Google Cloud Storage bucket
- Installing the binary and setting up shell integration

### Security Measures

This feature implements security measures to protect against supply chain attacks:

- HTTPS-only downloads with TLS 1.2+ enforcement
- SHA256 checksum verification against official manifest
- Automatic cleanup of temporary files

All installations verify binary integrity before use. If any security check fails, the installation aborts immediately.

## Requirements

- `curl` - Required for downloading (checked automatically)
- `sha256sum` or `shasum` - For checksum verification (usually pre-installed)

## Getting Started

After the feature is installed, start using Claude Code:

```bash
cd your-project
claude
```

You'll be prompted to log in on first use. A Claude subscription or Anthropic Console account is required.

For more information:
- [Official Documentation](https://code.claude.com/docs)
- [Quickstart Guide](https://code.claude.com/docs/en/quickstart)

## Authentication Persistence

By default, authentication **is persisted** across container rebuilds using Docker Named Volumes. To disable for security-sensitive environments:

```json
{
  "features": {
    "ghcr.io/5t111111/devcontainer-features/claude-code:0": {
      "persistAuth": false
    }
  }
}
```

### How it works:

**When enabled (default)**:
- Authentication data is stored in Docker named volumes
- Volume names: 
  - `claude-config-${devcontainerId}` - for `~/.claude` directory and `~/.claude.json` file
  - `claude-config-xdg-${devcontainerId}` - for `~/.config/claude` directory
- Data locations:
  - `/var/lib/claude-config` (symlinked to `~/.claude`)
  - `/var/lib/claude-config/config.json` (symlinked to `~/.claude.json`)
  - `/var/lib/claude-config-xdg` (symlinked to `~/.config/claude`)
- Survives container rebuilds and updates

**When disabled**:
- Authentication data stored in container filesystem
- Lost on container rebuild
- You'll need to log in again after each rebuild

### Important Notes:

⚠️ **Named Volumes are always created** even when `persistAuth: false`. The volumes are mounted at `/var/lib/claude-config` and `/var/lib/claude-config-xdg` regardless of the setting, but will not be used (remain empty) when persistence is disabled.

This is a limitation of the Dev Container Features specification where `mounts` cannot be conditional.

When to disable:
- Working in security-sensitive or shared environments
- Company policies prohibit persistent authentication
- Compliance requirements mandate re-authentication

## OS Support

This feature should work on recent versions of Linux-based distributions including:

- Debian/Ubuntu (glibc-based)
- Alpine Linux (musl-based)

The feature automatically detects your platform (x86_64/arm64, glibc/musl) and installs the appropriate binary.

`bash` and `curl` are required to execute the installation script.
