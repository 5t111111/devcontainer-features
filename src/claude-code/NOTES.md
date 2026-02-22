## Why This Feature?

The [official Anthropic devcontainer-features](https://github.com/anthropics/devcontainer-features) repository only installs the older npm-based version of Claude Code. This feature installs the modern native binary version which is faster, more efficient, and officially recommended.

When using Dev Containers, Claude Code authentication is stored in the container's non-persistent filesystem. This means you need to log in again after each container rebuild. This feature uses Docker Named Volumes to persist authentication state, allowing you to maintain your login session even after container rebuilds.

> [!NOTE]
> Why not use bind mounting of host's `~/.claude`?
> - Directly accessing the host filesystem undermines the sandboxing benefits of Dev Containers and introduces security risks
> - Sharing mounted filesystems between host and container with concurrent access can cause file locking issues or corruption
> - The bind mount approach makes it difficult to use different accounts with Claude Code across projects

## Example Usage

Add this feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/5t111111/devcontainer-features/claude-code:0": {}
  }
}
```

## 1. Native Claude Code CLI Installation

### What it installs

- The native Claude Code CLI binary (not the deprecated npm version)
- Automatically detects your platform (Linux/macOS, x64/arm64, glibc/musl)
- Downloads the latest or stable version from the official Google Cloud Storage bucket
- Sets up shell integration for seamless usage

### Security measures

- HTTPS-only downloads with TLS 1.2+ enforcement
- SHA256 checksum verification against official manifest
- Automatic cleanup of temporary files
- Installation aborts immediately if any security check fails

## 2. Authentication Persistence Across Container Rebuilds

### The problem

Without persistence, Claude Code authentication is stored in the container's ephemeral filesystem. This means you need to log in again after each container rebuild.

### The solution

This feature uses Docker Named Volumes to persist authentication state, allowing you to maintain your login session across container rebuilds and updates.

### Configuration

By default, authentication **is persisted**. To disable for security-sensitive environments:

```json
{
  "features": {
    "ghcr.io/5t111111/devcontainer-features/claude-code:0": {
      "persistAuth": false
    }
  }
}
```

### How it works

When persistence is **enabled (default)**:
- Authentication data is stored in a Docker named volume
- Volume name: `claude-config-${devcontainerId}` (project-specific)
- Volume mount: `/var/lib/claude-config`
- Symlinks created:
  - `~/.claude` → `/var/lib/claude-config`
  - `~/.claude.json` → `/var/lib/claude-config/config.json`
- Survives container rebuilds and updates

When persistence is **disabled**:
- Authentication data stored in container filesystem
- Lost on container rebuild
- You'll need to log in again after each rebuild

### Important notes

⚠️ **Named Volume is always created** even when `persistAuth: false`. The volume is mounted at `/var/lib/claude-config` regardless of the setting, but will not be used (remains empty) when persistence is disabled. This is a limitation of the Dev Container Features specification where `mounts` cannot be conditional.

### When to disable persistence

- Working in security-sensitive or shared environments
- Company policies prohibit persistent authentication
- Compliance requirements mandate re-authentication

## OS Support

- Debian/Ubuntu (glibc-based)
- Alpine Linux (musl-based)
- Automatically detects platform and installs the appropriate binary

## Requirements

- `curl` - For downloading (checked automatically)
- `sha256sum` or `shasum` - For checksum verification (usually pre-installed)
- `bash` - To execute the installation script
