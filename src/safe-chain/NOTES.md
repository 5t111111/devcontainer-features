## Why This Feature?

[safe-chain](https://github.com/AikidoSec/safe-chain) by Aikido Security is a lightweight proxy that intercepts package manager calls (npm, pip, yarn, pnpm, uv, poetry, and more) and blocks malicious packages in real time using Aikido's threat intelligence. It also enforces a minimum package age (default 48 hours) to guard against newly published malicious packages.

This feature installs safe-chain into a Dev Container and configures it so that the interception is active from the moment the container starts, with no manual setup required.

## Security

Rather than piping the official install script directly to sh (`curl ... | sh`), this feature takes a more controlled approach:

1. **Direct binary download**: The safe-chain binary is downloaded directly from the GitHub release over HTTPS (TLS 1.2+ enforced via `--proto '=https' --tlsv1.2`).
2. **Checksum extraction**: The official release install script is also downloaded. The release pipeline bakes SHA256 checksums for each platform binary into that script. The feature extracts the relevant checksum from the script before trusting it.
3. **SHA256 verification**: The downloaded binary is verified against the extracted checksum before installation. The install is aborted if verification fails.
4. **Temporary file cleanup**: All downloaded files are removed via a `trap cleanup EXIT` handler regardless of success or failure.

> **Note**: safe-chain does not publish GPG-signed checksums (unlike mise, which provides a `SHASUMS256.asc` signed with the official release key). The SHA256 checksums embedded in the release install script are the strongest verification available from this project.

## Shell Integration

`safe-chain setup` runs during the feature install (as root) to create the necessary system-level directories and files (`/usr/local/certs`, `/usr/local/scripts`). Shell integration is then written directly to the system-wide profiles `/etc/bash.bashrc` and `/etc/zsh/zshrc`, so all users in the container get the aliases without any `postCreateCommand`.

> **Note**: This approach is a workaround for [AikidoSec/safe-chain#450](https://github.com/AikidoSec/safe-chain/issues/450), a regression introduced in v1.5.0 where non-root users cannot run `safe-chain setup` because the binary unconditionally tries to create directories under `/usr/local`.

## OS Support

| OS    | x64 | arm64 |
|-------|-----|-------|
| Linux | ✅  | ✅    |

Linux uses the `linuxstatic` builds (no glibc dependency), providing maximum compatibility across Debian, Ubuntu, Alpine, and other distributions.

macOS builds are available in the asset list but devcontainer features typically target Linux containers; macOS support is present for completeness.
