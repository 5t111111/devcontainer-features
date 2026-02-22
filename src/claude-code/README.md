# Claude Code (claude-code)

Installs the latest **native version** of the Claude Code CLI with enhanced security measures including checksum verification.

## Why This Feature?

The [official Anthropic devcontainer-features](https://github.com/anthropics/devcontainer-features) repository only installs the older npm-based version of Claude Code. This feature installs the modern native binary version which is:

- ✅ Faster and more efficient
- ✅ Officially recommended installation method
- ✅ Automatically updated in the background
- ✅ Supports the latest features

## Security Features

This feature implements multiple security measures to protect against supply chain attacks:

- 🔒 **HTTPS-only downloads** with TLS 1.2+ enforcement
- 🔒 **Official source verification** - downloads only from Google Cloud Storage bucket
- 🔒 **SHA256 checksum verification** - validates binary integrity against manifest
- 🔒 **Automatic cleanup** - removes temporary files on success or failure
- 🔒 **Fail-safe installation** - aborts on any security validation failure

## Usage

```json
{
    "features": {
        "ghcr.io/5t111111/devcontainer-features/claude-code:0": {}
    }
}
```

### With Options

```json
{
    "features": {
        "ghcr.io/5t111111/devcontainer-features/claude-code:0": {
            "version": "stable",
            "persistAuth": true
        }
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | latest | Version channel to install. Options: `latest`, `stable` |
| persistAuth | boolean | true | Persist authentication across container rebuilds using named volume. Set to `false` to disable for security-sensitive environments. |

## What Does This Feature Do?

### Native Binary Installation

This feature installs the native Claude Code binary by:

1. Detecting your platform (Linux/macOS, x64/arm64, glibc/musl)
2. Downloading the latest or stable version from the official Google Cloud Storage bucket
3. Verifying the download against SHA256 checksums from the official manifest
4. Installing the binary and setting up shell integration

### Security Validation

Every installation:

- Downloads only over HTTPS with TLS 1.2+
- Verifies the binary checksum matches the official manifest
- Fails immediately if any security check fails
- Cleans up downloaded files automatically

## Requirements

- `curl` - Required for downloading (checked automatically)
- `sha256sum` or `shasum` - For checksum verification (usually pre-installed)

## Getting Started

After the feature is installed, start using Claude Code:

```bash
cd your-project
claude
```

You'll be prompted to log in on first use.

### Authentication Persistence

By default, Claude Code authentication **is persisted** across container rebuilds using Docker Named Volumes. This provides a seamless experience when frequently rebuilding containers.

To disable authentication persistence for security-sensitive environments, set `persistAuth: false`:

```json
{
    "features": {
        "ghcr.io/5t111111/devcontainer-features/claude-code:0": {
            "persistAuth": false
        }
    }
}
```

**How it works:**
- Uses Docker named volumes to store authentication data
- Volume names: 
  - `claude-config-${devcontainerId}` - for `~/.claude` and `~/.claude.json`
  - `claude-config-xdg-${devcontainerId}` - for `~/.config/claude`
- Creates symlinks for seamless access:
  - `~/.claude` → `/var/lib/claude-config`
  - `~/.claude.json` → `/var/lib/claude-config/config.json`
  - `~/.config/claude` → `/var/lib/claude-config-xdg`
- Survives container rebuilds and updates

**When to disable:**
- Working in security-sensitive or shared environments
- Company policies prohibit persistent authentication
- Compliance requirements mandate re-authentication

**Note:** The named volumes are always created regardless of the `persistAuth` setting due to Dev Container Features specification limitations. When disabled, the volumes simply remain empty and unused.

## OS Support

This feature supports:

- ✅ Linux (x86_64, arm64) - both glibc and musl
- ✅ macOS (Intel and Apple Silicon)
- ❌ Windows (not supported in container environments)

The feature automatically detects your platform and installs the appropriate binary.

## Comparison with Official Feature

| Feature | Official npm version | This native version |
|---------|---------------------|---------------------|
| Installation method | npm/npx | Native binary |
| Performance | Slower | Faster |
| Updates | Manual | Automatic |
| Status | Deprecated | Current |
| Security checks | Basic | Enhanced (checksum verification) |

## Documentation

For more information about Claude Code:

- [Official Documentation](https://code.claude.com/docs)
- [Quickstart Guide](https://code.claude.com/docs/en/quickstart)
- [Common Workflows](https://code.claude.com/docs/en/common-workflows)

## Notes

- This feature installs the native binary version of Claude Code, not the npm version
- The binary automatically updates in the background to keep you on the latest version
- A Claude subscription or Anthropic Console account is required to use Claude Code
- First use will prompt you to log in

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/5t111111/devcontainer-features/blob/main/src/claude-code/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
