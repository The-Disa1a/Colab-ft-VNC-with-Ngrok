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
    apt update -qq && apt install -qq -y xfce4 xfce4-terminal tightvncserver wget curl tmate autocutsel nano
    echo "Google Chrome Installing"
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg --install google-chrome-stable_current_amd64.deb
    apt install --assume-yes --fix-broken
    echo "Installing and configuring Ngrok"
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
     | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
     && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
     | sudo tee /etc/apt/sources.list.d/ngrok.list \
     && sudo apt update \
     && sudo apt install ngrok -y
    
    ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
    mkdir -p ~/.vnc
    echo "123456" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
export USER=root
    vncserver :1
    sed -i '/autocutsel/d' ~/.vnc/xstartup && echo -e "\n# Enable clipboard sharing\nexport DISPLAY=:1\n/usr/bin/autocutsel -fork\n/usr/bin/autocutsel -selection PRIMARY -fork" >> ~/.vnc/xstartup
    chmod +x ~/.vnc/xstartup
    vncserver -kill :1
    vncserver :1
    ngrok tcp --region in  5901 > /dev/null 2>&1 &
  
    echo "Setup completed."
}

# Change Wallpaper
wall_change() {
   # Download the image
   curl -s -L -k -o xfce-verticals.png "https://raw.githubusercontent.com/The-Disa1a/Colab-ft-VNC-with-Ngrok/refs/heads/main/wall/CachedImage_1024_768_POS4.jpg"

   # Define paths
   CUSTOM_WALLPAPER_PATH="$(pwd)/xfce-verticals.png"
   DESTINATION_PATH="/usr/share/backgrounds/xfce/"

   # Copy the image to the destination
   sudo cp "$CUSTOM_WALLPAPER_PATH" "$DESTINATION_PATH"
   echo "Wallpaper Changed."
}

# Execute functions
create_user
setup_vnc
wall_change

#echo ngrok address
curl -s http://127.0.0.1:4040/api/tunnels | grep -o '"tcp://[^"]*' | sed 's/tcp:\/\///'

#loop
start_time=$(date +%s); while true; do elapsed=$(( $(date +%s) - start_time )); elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))); echo -ne "\rRunning Time: $elapsed_formatted"; sleep 1; done
