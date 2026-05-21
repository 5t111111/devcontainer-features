
# Aikido safe-chain

Installs safe-chain by Aikido Security — a lightweight supply-chain security proxy that intercepts npm, pip, yarn, and other package manager calls to block malicious packages in real time.

## Example Usage

```json
"features": {
    "ghcr.io/5t111111/devcontainer-features/safe-chain:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| ci | When true, runs `safe-chain setup-ci` on postCreateCommand, which creates shims under ~/.safe-chain/shims and prepends them to PATH. When false (default), runs `safe-chain setup`, which adds shell aliases to ~/.bashrc and ~/.zshrc. | boolean | false |

## Notes

### What it protects

safe-chain intercepts calls to the following package managers and routes them through a local security proxy:

- **JavaScript / Node.js**: npm, npx, yarn, pnpm, pnpx, bun, bunx, rush
- **Python**: pip, pip3, uv, uvx, poetry, pipx, pdm

Packages are checked in real time against [Aikido Intel](https://intel.aikido.dev) threat intelligence. A minimum package age (default: 48 hours) is also enforced to guard against newly published malicious packages.

### Activation modes

**`ci: false` (default)**

Runs `safe-chain setup` via `postCreateCommand`. Adds aliases (e.g. `alias npm='safe-chain npm'`) to `~/.bashrc` and `~/.zshrc`. Aliases are only active in interactive shells.

**`ci: true`**

Runs `safe-chain setup-ci` via `postCreateCommand` (as the container user). Creates executable shims for package managers under `~/.safe-chain/shims/` and prepends that directory to `PATH`. Works in interactive shells, scripts, and CI pipelines.

### Security measures

- HTTPS-only downloads with TLS 1.2+ enforcement
- SHA256 checksum verification using checksums embedded in the official release install script
- Automatic cleanup of all temporary files

---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
