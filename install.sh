#!/bin/bash

# Detect architecture
ARCH=$(uname -m)
LIBC_TYPE=$(ldd --version 2>&1 | grep -o musl || echo glibc)

# Determine the correct binary URL based on architecture and libc
if [ "$ARCH" == "x86_64" ]; then
  if [ "$LIBC_TYPE" == "musl" ]; then
    BIN_URL="https://github.com/w3K-co/shpool/releases/latest/download/shpool-x86_64-unknown-linux-musl"
  else
    BIN_URL="https://github.com/w3K-co/shpool/releases/latest/download/shpool-x86_64-unknown-linux-gnu"
  fi
elif [ "$ARCH" == "i686" ]; then
  if [ "$LIBC_TYPE" == "musl" ]; then
    BIN_URL="https://github.com/w3K-co/shpool/releases/latest/download/shpool-i686-unknown-linux-musl"
  else
    BIN_URL="https://github.com/w3K-co/shpool/releases/latest/download/shpool-i686-unknown-linux-gnu"
  fi
elif [ "$ARCH" == "aarch64" ]; then
  if [ "$LIBC_TYPE" == "musl" ]; then
    BIN_URL="https://github.com/w3K-co/shpool/releases/latest/download/shpool-aarch64-unknown-linux-musl"
  else
    BIN_URL="https://github.com/w3K-co/shpool/releases/latest/download/shpool-aarch64-unknown-linux-gnu"
  fi
elif [ "$ARCH" == "armv7l" ]; then
  if [ "$LIBC_TYPE" == "musl" ]; then
    BIN_URL="https://github.com/w3K-co/shpool/releases/latest/download/shpool-armv7-unknown-linux-musleabihf"
  else
    BIN_URL="https://github.com/w3K-co/shpool/releases/latest/download/shpool-armv7-unknown-linux-gnueabihf"
  fi
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

# Update and install necessary dependencies
sudo apt update
sudo apt install -y curl wget systemd-user

# Download the shpool binary
echo "Downloading shpool binary..."
curl -Lo /usr/local/bin/shpool ${BIN_URL}

# Make the binary executable
chmod +x /usr/local/bin/shpool

# Setup systemd service for shpool
echo "Setting up systemd services..."
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/"
curl -fLo "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/shpool.service" \
    https://raw.githubusercontent.com/w3K-co/shpool/main/systemd/shpool.service
curl -fLo "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/shpool.socket" \
    https://raw.githubusercontent.com/w3K-co/shpool/main/systemd/shpool.socket

# Modify systemd service to point to the correct binary path
sed -i "s|/usr/bin/shpool|/usr/local/bin/shpool|" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/shpool.service"

# Enable and start the shpool service
systemctl --user enable shpool.socket
systemctl --user start shpool.socket

# Enable lingering for the user to keep shpool running after logout
loginctl enable-linger $(whoami)

echo "Shpool installation completed successfully."
echo "You can now use shpool by running 'shpool attach <session_name>' to start a new session."
