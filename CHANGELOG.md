# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- [ ] CRITICAL: Secure PIN cache memory zeroing (capi/wincapi.go)
- [ ] CRITICAL: Integer overflow check in Pageant message parsing (utils/pageant.go)
- [ ] HIGH: Remove insecure math/rand fallback in random string generation (utils/misc.go)
- [ ] HIGH: Add bounds checking in XShell message parsing (app/xshell.go)
- [ ] MEDIUM: Fix file permissions on Cygwin socket (app/cygwin.go)

### Changed
- Updated README with fork maintenance information
- Added CHANGELOG.md for tracking changes

### Planned
- Structured logging implementation
- Deprecate SHA1 RSA signatures
- Update outdated dependencies (pkcs7, walk, virtsock)

## [1.2.0-fork.1] - 2025-12-05

### Added
- Fork maintenance notice in README
- Build from source instructions
- Acknowledgments section

### Changed
- Branch structure: `master` tracks upstream, `main` for fork releases
- Updated badges to point to fork repository

### Merged from Community Forks
- XShell 7/8 compatibility improvements (zzmark/tantra35)
- SSH certificate handling fixes
- Pageant window foreground behavior
- Build system improvements
- Go 1.23 compatibility updates

## [1.1.9] - 2024-03-19 (Upstream)

### Merged (Upstream)
- PR #62: Add ability to remove PIN cache (unreality)
- PR #68: Update wsl_tutorial.md (ksteckert)
- PR #86: Added disown to send socat command to background (PortalMario)

## [1.1.8] - 2023-10-24 (Upstream)

### Added
- Disown socat command for better .bashrc integration

## Previous Versions

See [upstream releases](https://github.com/buptczq/WinCryptSSHAgent/releases) for historical changelog.

---

## Version Numbering

This fork uses the following versioning scheme:
- `X.Y.Z` - Matches upstream version when synced
- `X.Y.Z-fork.N` - Fork-specific releases with improvements

## Links

- [Unreleased]: https://github.com/hagan/WinCryptSSHAgent/compare/v1.2.0-fork.1...HEAD
- [1.2.0-fork.1]: https://github.com/hagan/WinCryptSSHAgent/releases/tag/v1.2.0-fork.1
- [1.1.9]: https://github.com/buptczq/WinCryptSSHAgent/releases/tag/v1.1.9
