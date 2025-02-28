#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Prompt user for Ngrok authtoken
echo "Please enter your Ngrok authtoken: "
read NGROK_AUTH_TOKEN

# Function to create user
create_user() {
    echo "Creating User and Setting it up"
    username="user"
    password="root"
    
    useradd -m "$username"
    adduser "$username" sudo
    echo "$username:$password" | sudo chpasswd
    sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
    
    echo "User '$username' created and configured."
}

# Function to install and configure RDP using VNC
setup_vnc() {
    echo "Installing Desktop Environment and VNC"
    apt update
    apt install --assume-yes xfce4 xfce4-terminal tightvncserver wget curl
    
    echo "Setting up VNC Server"
    su - colab -c "vncserver :1 -geometry 1280x720 -depth 24"
    
    echo "Installing and configuring Ngrok"
    wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
    unzip ngrok-stable-linux-amd64.zip
    mv ngrok /usr/local/bin/
    ngrok authtoken $NGROK_AUTH_TOKEN
    
    echo "Starting Ngrok Tunnel"
    su - colab -c "ngrok tcp 5901 &"
    
    echo "VNC setup completed."
}

# Execute functions
create_user
setup_vnc

# Keep-alive loop
echo "Starting keep-alive loop. Press Ctrl+C to stop."
while true; do
    echo "I'm alive"
    sleep 300  # Sleep for 5 minutes
done
