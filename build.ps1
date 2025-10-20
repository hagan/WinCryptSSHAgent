#!/usr/bin/env pwsh
# WinCryptSSHAgent PowerShell Build Script
# Native Windows PowerShell build automation

param(
    [Parameter(Position=0)]
    [ValidateSet('help', 'build', 'build-32', 'build-64', 'clean', 'test', 'fmt', 'vet', 'check', 'version', 'release')]
    [string]$Command = 'help'
)

# Configuration
$BinaryName = "WinCryptSSHAgent"
$Binary32 = "${BinaryName}_32bit.exe"
$Binary64 = "${BinaryName}.exe"

# Version information
function Get-VersionInfo {
    $version = if (Test-Path "VERSION") {
        (Get-Content "VERSION" -Raw).Trim()
    } else {
        "1.1.9"
    }

    $gitHash = try {
        git rev-parse --short HEAD 2>$null
    } catch {
        "unknown"
    }

    $gitTag = try {
        git describe --tags --always 2>$null
    } catch {
        "v$version"
    }

    $gitDirty = if ((git status --porcelain 2>$null | Measure-Object).Count -gt 0) {
        "-dirty"
    } else {
        ""
    }

    return @{
        Version = $version
        GitHash = $gitHash
        GitTag = $gitTag
        GitDirty = $gitDirty
    }
}

# Colors
function Write-Header { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host "✓" -ForegroundColor Green -NoNewline; Write-Host " $args" }
function Write-Error { Write-Host "✗" -ForegroundColor Red -NoNewline; Write-Host " $args" }
function Write-Info { Write-Host "→" -ForegroundColor Blue -NoNewline; Write-Host " $args" }

# Check build environment
function Test-BuildEnvironment {
    Write-Header "Checking build environment..."

    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Write-Error "Go not found. Please install Go 1.23+"
        Write-Host "  Download: https://go.dev/dl/"
        exit 1
    }

    $goVersion = go version
    Write-Success "Go found: $goVersion"

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "  Warning: Git not found (version info will be limited)" -ForegroundColor Yellow
    }

    Write-Success "Build environment ready"
}

# Generate version info
function Invoke-Generate {
    Write-Info "Generating version info..."
    go generate
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Version info generated"
    } else {
        Write-Error "Failed to generate version info"
        exit 1
    }
}

# Build functions
function Invoke-Build32 {
    Test-BuildEnvironment
    Invoke-Generate

    $ver = Get-VersionInfo
    Write-Header "Building 32-bit Windows binary..."
    Write-Info "Version: v$($ver.Version) ($($ver.GitHash)$($ver.GitDirty))"

    $env:GOARCH = "386"
    $ldflags = "-w -s -H=windowsgui -X main.Version=$($ver.Version) -X main.GitHash=$($ver.GitHash)"

    go build -trimpath -ldflags $ldflags -o $Binary32

    if ($LASTEXITCODE -eq 0 -and (Test-Path $Binary32)) {
        $size = (Get-Item $Binary32).Length / 1MB
        Write-Success "32-bit binary built: $Binary32 ($([math]::Round($size, 2)) MB)"
    } else {
        Write-Error "Build failed"
        exit 1
    }
}

function Invoke-Build64 {
    Test-BuildEnvironment
    Invoke-Generate

    $ver = Get-VersionInfo
    Write-Header "Building 64-bit Windows binary..."
    Write-Info "Version: v$($ver.Version) ($($ver.GitHash)$($ver.GitDirty))"

    $env:GOARCH = "amd64"
    $ldflags = "-w -s -H=windowsgui -X main.Version=$($ver.Version) -X main.GitHash=$($ver.GitHash)"

    go build -trimpath -ldflags $ldflags -o $Binary64

    if ($LASTEXITCODE -eq 0 -and (Test-Path $Binary64)) {
        $size = (Get-Item $Binary64).Length / 1MB
        Write-Success "64-bit binary built: $Binary64 ($([math]::Round($size, 2)) MB)"
    } else {
        Write-Error "Build failed"
        exit 1
    }
}

function Invoke-Build {
    Invoke-Build32
    Write-Host ""
    Invoke-Build64
    Write-Host ""
    Write-Success "Build complete!"
    Write-Host "  32-bit: $Binary32" -ForegroundColor Gray
    Write-Host "  64-bit: $Binary64" -ForegroundColor Gray
}

# Clean
function Invoke-Clean {
    Write-Header "Cleaning build artifacts..."

    $cleaned = @()
    if (Test-Path $Binary32) { Remove-Item $Binary32; $cleaned += $Binary32 }
    if (Test-Path $Binary64) { Remove-Item $Binary64; $cleaned += $Binary64 }
    if (Test-Path "resource.syso") { Remove-Item "resource.syso"; $cleaned += "resource.syso" }

    # Clean release archives
    Get-ChildItem -Filter "${BinaryName}-v*.zip*" | Remove-Item

    if ($cleaned.Count -gt 0) {
        Write-Success "Removed: $($cleaned -join ', ')"
    } else {
        Write-Info "Nothing to clean"
    }
}

# Test
function Invoke-Test {
    Test-BuildEnvironment
    Write-Header "Running tests..."
    go test -v ./...

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Tests passed"
    } else {
        Write-Error "Tests failed"
        exit 1
    }
}

# Format
function Invoke-Format {
    Write-Header "Formatting code..."
    $result = go fmt ./...

    if ($result) {
        Write-Info "Formatted files:"
        $result | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Success "All files already formatted"
    }
}

# Vet
function Invoke-Vet {
    Write-Header "Running go vet..."
    go vet ./...

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Vet check passed"
    } else {
        Write-Error "Vet check failed"
        exit 1
    }
}

# Check (fmt + vet)
function Invoke-Check {
    Invoke-Format
    Write-Host ""
    Invoke-Vet
    Write-Host ""
    Write-Success "All checks passed"
}

# Version
function Show-Version {
    $ver = Get-VersionInfo

    Write-Header "Version Information:"
    Write-Host "  Version:    v$($ver.Version)"
    Write-Host "  Git Hash:   $($ver.GitHash)$($ver.GitDirty)"
    Write-Host "  Git Tag:    $($ver.GitTag)"

    if (Test-Path $Binary64) {
        $size = (Get-Item $Binary64).Length / 1MB
        Write-Host ""
        Write-Host "  Binary:     $Binary64 ($([math]::Round($size, 2)) MB)" -ForegroundColor Gray
    }
}

# Release
function Invoke-Release {
    Invoke-Clean
    Invoke-Build

    $ver = Get-VersionInfo
    Write-Header "Creating release archives..."

    $zip32 = "${BinaryName}-v$($ver.Version)-windows-386.zip"
    $zip64 = "${BinaryName}-v$($ver.Version)-windows-amd64.zip"

    # Create archives
    Compress-Archive -Path $Binary32 -DestinationPath $zip32 -Force
    Compress-Archive -Path $Binary64 -DestinationPath $zip64 -Force

    # Generate checksums
    $hash32 = (Get-FileHash $zip32 -Algorithm SHA256).Hash
    $hash64 = (Get-FileHash $zip64 -Algorithm SHA256).Hash

    $hash32 | Out-File -Encoding ASCII "${zip32}.sha256"
    $hash64 | Out-File -Encoding ASCII "${zip64}.sha256"

    Write-Host ""
    Write-Success "Release archives created:"
    Write-Host "  $zip32" -ForegroundColor Gray
    Write-Host "    SHA256: $hash32" -ForegroundColor DarkGray
    Write-Host "  $zip64" -ForegroundColor Gray
    Write-Host "    SHA256: $hash64" -ForegroundColor DarkGray
}

# Help
function Show-Help {
    $ver = Get-VersionInfo

    Write-Header "WinCryptSSHAgent Build System"
    Write-Host "Version: v$($ver.Version) ($($ver.GitHash)$($ver.GitDirty))" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Usage: " -NoNewline
    Write-Host ".\build.ps1 " -NoNewline -ForegroundColor Yellow
    Write-Host "[command]"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Green
    Write-Host "  help          " -ForegroundColor Yellow -NoNewline; Write-Host "  Show this help message"
    Write-Host "  build         " -ForegroundColor Yellow -NoNewline; Write-Host "  Build both 32-bit and 64-bit binaries"
    Write-Host "  build-32      " -ForegroundColor Yellow -NoNewline; Write-Host "  Build 32-bit binary only"
    Write-Host "  build-64      " -ForegroundColor Yellow -NoNewline; Write-Host "  Build 64-bit binary only"
    Write-Host "  clean         " -ForegroundColor Yellow -NoNewline; Write-Host "  Remove build artifacts"
    Write-Host "  test          " -ForegroundColor Yellow -NoNewline; Write-Host "  Run tests"
    Write-Host "  fmt           " -ForegroundColor Yellow -NoNewline; Write-Host "  Format code with gofmt"
    Write-Host "  vet           " -ForegroundColor Yellow -NoNewline; Write-Host "  Run go vet"
    Write-Host "  check         " -ForegroundColor Yellow -NoNewline; Write-Host "  Run fmt and vet"
    Write-Host "  version       " -ForegroundColor Yellow -NoNewline; Write-Host "  Show version information"
    Write-Host "  release       " -ForegroundColor Yellow -NoNewline; Write-Host "  Create release archives with checksums"
    Write-Host ""
    Write-Host "Build outputs:" -ForegroundColor Green
    Write-Host "  32-bit: $Binary32" -ForegroundColor Gray
    Write-Host "  64-bit: $Binary64" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  .\build.ps1 build" -ForegroundColor Gray
    Write-Host "  .\build.ps1 check" -ForegroundColor Gray
    Write-Host "  .\build.ps1 release" -ForegroundColor Gray
}

# Main command dispatcher
switch ($Command) {
    'help'      { Show-Help }
    'build'     { Invoke-Build }
    'build-32'  { Invoke-Build32 }
    'build-64'  { Invoke-Build64 }
    'clean'     { Invoke-Clean }
    'test'      { Invoke-Test }
    'fmt'       { Invoke-Format }
    'vet'       { Invoke-Vet }
    'check'     { Invoke-Check }
    'version'   { Show-Version }
    'release'   { Invoke-Release }
    default     { Show-Help }
}
