# WinCryptSSHAgent Makefile
# Windows-focused build configuration (bash/POSIX compatible for Git Bash)

# Configuration
BINARY_NAME = WinCryptSSHAgent
BINARY_32BIT = $(BINARY_NAME)_32bit.exe
BINARY_64BIT = $(BINARY_NAME).exe

# Version information
VERSION := $(shell cat VERSION 2>/dev/null || echo 1.1.9)
GIT_HASH := $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
GIT_TAG := $(shell git describe --tags --always 2>/dev/null || echo v$(VERSION))
GIT_DIRTY := $(shell git status --porcelain 2>/dev/null | grep -q . && echo "-dirty" || echo "")

# Build settings
GO = go
GOFLAGS = -trimpath
LDFLAGS = -w -s -H=windowsgui
BUILD_LDFLAGS = $(LDFLAGS) -X main.Version=$(VERSION) -X main.GitHash=$(GIT_HASH)

# Default target
.PHONY: all
all: help

# Help target
.PHONY: help
help:
	@echo "WinCryptSSHAgent Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  make build         - Build both 32-bit and 64-bit binaries"
	@echo "  make build-32      - Build 32-bit binary only"
	@echo "  make build-64      - Build 64-bit binary only"
	@echo "  make clean         - Remove build artifacts"
	@echo "  make test          - Run tests"
	@echo "  make fmt           - Format code with gofmt"
	@echo "  make vet           - Run go vet"
	@echo "  make check         - Run fmt and vet"
	@echo "  make version       - Show version information"
	@echo "  make release       - Create release archives with checksums"
	@echo "  make help          - Show this help message"
	@echo ""
	@echo "Build outputs:"
	@echo "  32-bit: $(BINARY_32BIT)"
	@echo "  64-bit: $(BINARY_64BIT)"
	@echo ""
	@echo "Version: v$(VERSION) ($(GIT_HASH)$(GIT_DIRTY))"

# Check build environment
.PHONY: check-env
check-env:
	@echo "Checking build environment..."
	@command -v go >/dev/null 2>&1 || (echo "Error: Go not found. Please install Go 1.23+" && exit 1)
	@echo "Go found:"
	@go version
	@echo "Build environment ready"

# Generate version info
.PHONY: generate
generate: check-env
	@echo "Generating version info..."
	@$(GO) generate
	@echo "Version info generated"

# Build both architectures
.PHONY: build
build: build-32 build-64
	@echo ""
	@echo "Build complete!"
	@echo "  32-bit: $(BINARY_32BIT)"
	@echo "  64-bit: $(BINARY_64BIT)"

# Build 32-bit
.PHONY: build-32
build-32: check-env generate
	@echo "Building 32-bit Windows binary..."
	@GOARCH=386 $(GO) build $(GOFLAGS) -ldflags "$(BUILD_LDFLAGS)" -o $(BINARY_32BIT)
	@echo "32-bit binary built: $(BINARY_32BIT)"

# Build 64-bit
.PHONY: build-64
build-64: check-env generate
	@echo "Building 64-bit Windows binary..."
	@GOARCH=amd64 $(GO) build $(GOFLAGS) -ldflags "$(BUILD_LDFLAGS)" -o $(BINARY_64BIT)
	@echo "64-bit binary built: $(BINARY_64BIT)"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -f $(BINARY_32BIT) $(BINARY_64BIT) resource.syso
	@echo "Build artifacts removed"

# Run tests
.PHONY: test
test: check-env
	@echo "Running tests..."
	@$(GO) test -v ./...

# Format code
.PHONY: fmt
fmt:
	@echo "Formatting code..."
	@$(GO) fmt ./...
	@echo "Code formatted"

# Run go vet
.PHONY: vet
vet:
	@echo "Running go vet..."
	@$(GO) vet ./...
	@echo "Vet check passed"

# Run all checks
.PHONY: check
check: fmt vet
	@echo "All checks passed"

# Show version information
.PHONY: version
version:
	@echo "Version Information:"
	@echo "  Version:    v$(VERSION)"
	@echo "  Git Hash:   $(GIT_HASH)$(GIT_DIRTY)"
	@echo "  Git Tag:    $(GIT_TAG)"
	@if [ -f "$(BINARY_64BIT)" ]; then echo ""; echo "Binary exists: $(BINARY_64BIT)"; fi

# Create release archives with checksums
.PHONY: release
release: clean build
	@echo "Creating release archives..."
	@powershell.exe -Command "Compress-Archive -Path $(BINARY_32BIT) -DestinationPath $(BINARY_NAME)-v$(VERSION)-windows-386.zip -Force"
	@powershell.exe -Command "Compress-Archive -Path $(BINARY_64BIT) -DestinationPath $(BINARY_NAME)-v$(VERSION)-windows-amd64.zip -Force"
	@powershell.exe -Command "Get-FileHash $(BINARY_NAME)-v$(VERSION)-windows-386.zip -Algorithm SHA256 | Select-Object -ExpandProperty Hash | Out-File -Encoding ASCII $(BINARY_NAME)-v$(VERSION)-windows-386.zip.sha256"
	@powershell.exe -Command "Get-FileHash $(BINARY_NAME)-v$(VERSION)-windows-amd64.zip -Algorithm SHA256 | Select-Object -ExpandProperty Hash | Out-File -Encoding ASCII $(BINARY_NAME)-v$(VERSION)-windows-amd64.zip.sha256"
	@echo ""
	@echo "Release archives created:"
	@echo "  $(BINARY_NAME)-v$(VERSION)-windows-386.zip"
	@echo "  $(BINARY_NAME)-v$(VERSION)-windows-amd64.zip"
	@echo "  SHA256 checksums included"

.DEFAULT_GOAL := help
