# Dev Container Features

Custom [Dev Container Features](https://containers.dev/implementors/features/) for enhanced development container experiences.

## Features

This repository contains the following Dev Container Features:

### [rust-extra](src/rust-extra)

Enhances the official Rust feature with additional tools and configurations:
- Installs cargo-binstall for faster binary installations
- Adds commonly used Cargo tools: cargo-audit, cargo-edit, cargo-expand, cargo-watch
- Configures VS Code settings for Rust development
- Handles file permissions correctly for container environments

```json
{
    "features": {
        "ghcr.io/5t111111/devcontainer-features/rust-extra:0": {}
    }
}
```

### [claude-code](src/claude-code)

Installs the latest **native version** of the Claude Code CLI with enhanced security measures:
- Native binary installation (not the deprecated npm version)
- HTTPS-only downloads with TLS 1.2+ enforcement
- SHA256 checksum verification for supply chain attack protection
- Automatic platform detection (Linux/macOS, x64/arm64, glibc/musl)
- Fail-safe installation with automatic cleanup

```json
{
    "features": {
        "ghcr.io/5t111111/devcontainer-features/claude-code:0": {}
    }
}
```

## Usage

Features are automatically published to GitHub Container Registry. Reference them in your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/5t111111/devcontainer-features/<feature-id>:0": {}
    }
}
```

## Development

See [AGENTS.md](AGENTS.md) for comprehensive guidance on developing features in this repository.

## License

MIT - See [LICENSE](LICENSE) for details.
