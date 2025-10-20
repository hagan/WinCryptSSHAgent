# Build Documentation

This document explains the build system for WinCryptSSHAgent.

## Prerequisites

- **Go 1.23+** - [Download](https://go.dev/dl/)
- **Git** - For version info
- **Windows** - Required for building Windows executables
- **PowerShell 5.1+** - Built into Windows (for `build.ps1`)
- **Make** (optional) - For using Makefile commands (Git Bash/WSL)

## Quick Start

### Using PowerShell (Recommended for Windows)

```powershell
# Show all available commands
.\build.ps1 help

# Build both 32-bit and 64-bit binaries
.\build.ps1 build

# Build only 64-bit
.\build.ps1 build-64

# Build only 32-bit
.\build.ps1 build-32

# Run tests
.\build.ps1 test

# Format and check code
.\build.ps1 check

# Clean build artifacts
.\build.ps1 clean

# Create release archives with checksums
.\build.ps1 release

# Show version information
.\build.ps1 version
```

### Using Make (Git Bash/WSL)

If you have Git Bash or WSL with make installed:

```bash
# Show all available commands
make help

# Build both 32-bit and 64-bit binaries
make build

# Build only 64-bit
make build-64

# Build only 32-bit
make build-32

# Run tests
make test

# Format and check code
make check

# Clean build artifacts
make clean

# Create release archives with checksums
make release
```

### Using build.bat (Legacy)

```cmd
# Build both architectures
build.bat

# Build specific architecture
build.bat amd64
build.bat 386
```

## Build Outputs

The build produces the following files:

- `WinCryptSSHAgent.exe` - 64-bit Windows executable
- `WinCryptSSHAgent_32bit.exe` - 32-bit Windows executable

## Version Management

Version is managed through the `VERSION` file:

```bash
# Current version
cat VERSION

# To bump version, edit VERSION file (use printf to avoid trailing newline)
printf '1.2.0' > VERSION

# Or use echo -n (no trailing newline)
echo -n 1.2.0 > VERSION

# Build with new version
make build
```

The build automatically includes:
- Version from `VERSION` file
- Git commit hash
- Git dirty state (if uncommitted changes)

## GitHub Actions CI/CD

### Build Workflow

Triggered on:
- Push to `master`, `fork`, or `integrate/*` branches
- Pull requests to `master` or `fork`
- Changes to Go files, go.mod, go.sum, or workflow files

The workflow:
1. **Lints** code with `go fmt` and `go vet`
2. **Builds** both 32-bit and 64-bit Windows binaries
3. **Creates** ZIP archives with SHA256 checksums
4. **Uploads** artifacts for download

### Release Workflow

Triggered on:
- Push of version tags (e.g., `v1.2.0`)
- Manual dispatch via GitHub Actions UI

The workflow:
1. Builds both architectures
2. Creates ZIP archives with checksums
3. Creates GitHub release with:
   - Release notes
   - Binary downloads
   - SHA256 checksums
   - Installation instructions

## Creating a Release

### 1. Update Version

```bash
# Edit VERSION file (use printf to avoid trailing newline)
printf '1.2.0' > VERSION

# Update versioninfo.json to match
# (Edit FileVersion and ProductVersion)
```

### 2. Commit and Tag

```bash
# Commit version bump
git add VERSION versioninfo.json
git commit -m "Bump version to 1.2.0"

# Create and push tag
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

### 3. GitHub Actions Automation

The release workflow automatically:
- Builds both architectures
- Creates release on GitHub
- Attaches binaries and checksums

### 4. Manual Release (if needed)

```powershell
# Build release archives locally
.\build.ps1 release

# This creates:
# - WinCryptSSHAgent-v1.2.0-windows-amd64.zip
# - WinCryptSSHAgent-v1.2.0-windows-386.zip
# - SHA256 checksums for each
```

Or with make:

```bash
make release
```

## Build Flags

The build uses the following flags:

```bash
-trimpath              # Remove file system paths from binary
-ldflags="-w -s"       # Strip debug info and symbol table
-H=windowsgui          # Windows GUI application (no console)
-X main.Version=...    # Inject version
-X main.GitHash=...    # Inject git hash
```

## Development Workflow

### Local Development

```powershell
# Format code
.\build.ps1 fmt

# Run linter
.\build.ps1 vet

# Run all checks
.\build.ps1 check

# Build and test
.\build.ps1 build
.\build.ps1 test
```

Or with make (Git Bash/WSL):

```bash
make fmt
make vet
make check
make build
make test
```

### Pre-commit Checklist

Before committing changes:

1. ✅ Format code: `.\build.ps1 fmt` or `make fmt`
2. ✅ Run linter: `.\build.ps1 vet` or `make vet`
3. ✅ Run tests: `.\build.ps1 test` or `make test`
4. ✅ Build succeeds: `.\build.ps1 build` or `make build`

### CI Workflow

All pushes and PRs automatically:
1. Check formatting
2. Run go vet
3. Build both architectures
4. Generate build summaries

## Troubleshooting

### Go not found

```bash
# Check Go installation
go version

# Should show: go version go1.23.x windows/amd64
```

### Build fails with "command not found: goversioninfo"

```bash
# Install goversioninfo
go install github.com/josephspurrier/goversioninfo/cmd/goversioninfo@latest
```

### PowerShell execution policy error

If you get an error about execution policy when running `build.ps1`:

```powershell
# Allow script execution for current session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Then run the script
.\build.ps1 build
```

Or permanently for current user:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Makefile not working

On Windows, you may need:
- **Git Bash** - Included with Git for Windows
- **Make** - Install via chocolatey: `choco install make`

Alternatively, use `build.ps1` (PowerShell) or `build.bat` (legacy cmd) instead of Make.

### Version not updating

Make sure to:
1. Update `VERSION` file
2. Run `go generate` to update version info
3. Rebuild binaries

## Advanced

### Cross-compilation

While this project targets Windows only, you can build from other platforms:

```bash
# From Linux/macOS
GOOS=windows GOARCH=amd64 go build -o WinCryptSSHAgent.exe
GOOS=windows GOARCH=386 go build -o WinCryptSSHAgent_32bit.exe
```

Note: Windows-specific features may not work when cross-compiled.

### Custom LDFLAGS

```bash
# Build with custom flags
go build -ldflags "-X main.CustomVar=value" -o output.exe
```

### Debug Build

For development with debug symbols:

```bash
# Remove -w -s flags
go build -trimpath -ldflags "-H=windowsgui" -o WinCryptSSHAgent-debug.exe
```

## References

- [Go Build Documentation](https://pkg.go.dev/cmd/go#hdr-Compile_packages_and_dependencies)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Semantic Versioning](https://semver.org/)
