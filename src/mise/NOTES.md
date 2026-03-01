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
