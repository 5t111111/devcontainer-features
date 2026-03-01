
# mise-en-place (mise)

Installs the mise CLI (mise-en-place) with checksum verification. mise is a polyglot tool version manager and task runner.

## Example Usage

```json
"features": {
    "ghcr.io/5t111111/devcontainer-features/mise:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of mise to install (e.g. "v2026.2.23"). Use "latest" to install the latest release. | string | latest |
| activate | Shell activation method. 'path' appends 'eval $(mise activate)' to system bash/zsh profiles. 'shims' appends 'eval $(mise activate --shims)' instead. 'none' skips automatic activation. | string | path |
| trust | Run 'mise trust --all --yes' on postCreate to automatically trust the workspace mise.toml. | boolean | true |
| install | Run 'mise install --yes' on postCreate to install workspace tools. Automatically enables trust. | boolean | true |

## Customizations

### VS Code Extensions

- `hverlin.mise-vscode`

# Development Notes: mise feature

## Purpose

This feature installs [mise](https://mise.jdx.dev/) (mise-en-place), a polyglot tool version manager and task runner. It manages runtime versions (Node.js, Python, Ruby, etc.) and project-local tools via `mise.toml`, serving as a modern alternative to tools like `asdf` and `direnv`.

## Security

Rather than piping a remote shell script (`curl https://mise.run | sh`), this feature downloads the binary directly from [GitHub Releases](https://github.com/jdx/mise/releases) and verifies it using a two-step approach:

1. **GPG signature**: `SHASUMS256.asc` (a clearsign file) is verified against the official mise release key (`24853EC9F655CE80B48E6C3A8B81C9D17413A06D`, fetched from `hkps://keys.openpgp.org`) before any checksum is trusted.
2. **SHA256 checksum**: The downloaded binary is checked against the checksum extracted from the verified `SHASUMS256.asc`.

`gpg` is required and is installed automatically via `apt-get` on Debian/Ubuntu if not already present.

## OS Support

| OS                    | x64 | arm64 |
|-----------------------|-----|-------|
| Linux (Debian/Ubuntu) | ✅  | ✅    |

Alpine Linux is not supported: `gpg` cannot be installed automatically without `apt-get`.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
