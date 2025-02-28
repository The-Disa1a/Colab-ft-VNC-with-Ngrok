#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if an argument is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 \"<NGROK_AUTH_TOKEN>\""
    exit 1
fi

# Assign the first argument as the Ngrok auth token
NGROK_AUTH_TOKEN="$1"

# Function to create user
create_user() {
    echo "Creating User and Setting it up"
    username="user"
    password="root"
    
    useradd -m "$username"
    echo "$username:$password" | sudo chpasswd
    usermod -aG sudo "$username"
    sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
    
    echo "User '$username' created and configured."
}

# Function to install and configure RDP using VNC
setup_vnc() {
    echo "Installing Desktop Environment and VNC"
    apt update > /dev/null 2>&1 &
    apt install --assume-yes xfce4 xfce4-terminal tightvncserver wget curl tmate > /dev/null 2>&1 &

    echo "Installing and configuring Ngrok"
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
     | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
     && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
     | sudo tee /etc/apt/sources.list.d/ngrok.list \
     && sudo apt update \
     && sudo apt install ngrok -y
    
    ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
    vncserver :1
    
    echo "Setup completed."
}

# Execute functions
create_user
setup_vnc
