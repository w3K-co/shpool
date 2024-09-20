#!/bin/bash

#Get Input from user e.g. Y or N/n... usage: YorN "This is the prompt (A/B)" "AB" "B" 10
YorN() {
    local prompter=$1
    local response_string=$2
    local default_response=$3
    local timeout=$4

    # Test if the shell supports "read -t"
    local supports_timeout=false
    if read -t 1 2>/dev/null; then
        supports_timeout=true
    fi

    # Function to check if the response is valid (exists in the response string)
    is_valid_response() {
        local input=$1
        if [ "${response_string#*$input}" != "$response_string" ]; then
            return 0
        else
            return 1
        fi
    }

    # Prompt the user for input with the specified timeout (if any)
    if [ "$supports_timeout" = true ] && [ -n "$timeout" ]; then
        read -t "$timeout" -p "$prompter" response
    else
        read -p "$prompter" response
    fi

    # Convert the response to uppercase to handle both cases (e.g., Y/y or N/n)
    response=$(echo "$response" | tr '[:lower:]' '[:upper:]')

    # Check if the response is empty (timeout occurred or user pressed Enter)
    if [ -z "$response" ]; then
        # Use the default_response if provided
        response="$default_response"
    fi

    # Check if the response is valid
    while ! is_valid_response "$response"; do
        echo "Invalid response. Please answer with ${response_string:0:1} or ${response_string:1:1}."
        read -p "$prompter" response
    done

    echo # Move to the next line after the user input
}


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
  BIN_URL=""
  echo "Unsupported architecture: $ARCH"
  exit 1
fi


#Display Architecture Detected
echo "Architecture detected: $ARCH"
echo "Library Type: $LIBC_TYPE"
echo "Download URL: $BIN_URL"
echo ""
echo ""
echo ""

# Update and install necessary dependencies
YorN "Install necessary dependencies? (Y/N): " "YN" "Y" 10
if [ "$response" = "Y" ]; then
	sudo apt update
	sudo apt install -y curl wget systemd-user
fi

# Download the shpool binary
YorN "Download shpool binary? (Y/N): " "YN" "Y" 10
if [ "$response" = "Y" ]; then
	echo "Downloading shpool binary..."
	curl -Lo /usr/local/bin/shpool ${BIN_URL}
fi

# Setup
YorN "install and Activate service? (Y/N): " "YN" "Y" 10
if [ "$response" = "Y" ]; then
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
fi

echo ""
echo "Goodbye!"
echo ""
