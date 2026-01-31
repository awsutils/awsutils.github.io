#!/bin/sh

# Gum Installation Script
# Installs gum - A tool for beautiful interactive shell scripts

set -e

# Detect system architecture
uname_out=$(uname -m)
case "${uname_out}" in
  x86_64*)    arch="x86_64";;
  aarch64*)   arch="arm64";;
  arm64*)     arch="arm64";;
  *)          echo "Unknown architecture: ${uname_out}"; exit 1;;
esac

# Detect OS
os=$(uname -s | tr '[:upper:]' '[:lower:]')

echo "Installing gum for $os ($arch)..."

# Create temp directory
mkdir -p ~/.tmp
cd ~/.tmp

# Download gum
GUM_VERSION="0.14.3"
wget "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${os}_${arch}.tar.gz" -O gum.tar.gz

# Extract
tar -xzf gum.tar.gz

# Install
sudo install -o root -g root -m 0755 gum /usr/local/bin/gum

# Verify
if command -v gum &> /dev/null; then
    echo "✓ gum installed successfully!"
    gum --version
else
    echo "✗ Failed to install gum"
    exit 1
fi

# Cleanup
rm -rf ~/.tmp/gum*

echo ""
echo "You can now use gum to create beautiful shell scripts!"
echo "Try: gum choose \"Option 1\" \"Option 2\" \"Option 3\""
