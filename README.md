# Dev Container Features

Custom [Dev Container Features](https://containers.dev/implementors/features/) for enhanced development container experiences.

## Features

This repository contains the following Dev Container Features:

- **[rust-extra](src/rust-extra)** - Enhanced Rust development tools and configurations
- **[claude-code](src/claude-code)** - Claude Code CLI installation with security features

For detailed information about each feature, please see the README in each feature's directory under `src/`.

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
