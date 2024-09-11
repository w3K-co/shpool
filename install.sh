#!/bin/bash

# Function to detect system type and set the correct binary URL
detect_binary_url() {
    libc_type=$(ldd --version 2>&1 | grep -o 'musl\|glibc')

    if [[ "$libc_type" == "musl" ]]; then
        binary="shpool-x86_64-unknown-linux-musl"
    else
        binary="shpool-x86_64-unknown-linux-gnu"
    fi

    echo "Detected system type: $libc_type"
    BIN_URL="https://github.com/w3K-co/shpool/releases/latest/download/$binary"
}

# Update and install necessary dependencies
echo "Installing necessary dependencies..."
sudo apt update
sudo apt install -y curl wget systemd-user

# Detect system and determine the correct binary
detect_binary_url

# Download the shpool binary
echo "Downloading shpool binary..."
curl -Lo /usr/local/bin/shpool "$BIN_URL"

# Make the binary executable
chmod +x /usr/local/bin/shpool

# Setup systemd service for shpool
echo "Setting up systemd services..."
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/"
curl -fLo "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/shpool.service" \
    https://raw.githubusercontent.com/w3K-co/shpool/master/systemd/shpool.service
curl -fLo "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/shpool.socket" \
    https://raw.githubusercontent.com/w3K-co/shpool/master/systemd/shpool.socket

# Modify systemd service to point to the correct binary path
sed -i "s|/usr/bin/shpool|/usr/local/bin/shpool|" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/shpool.service"

# Enable and start the shpool service
systemctl --user enable shpool.socket
systemctl --user start shpool.socket

# Enable lingering for the user to keep shpool running after logout
loginctl enable-linger $(whoami)

echo "Shpool installation completed successfully."
echo "You can now use shpool by running 'shpool attach <session_name>' to start a new session."
