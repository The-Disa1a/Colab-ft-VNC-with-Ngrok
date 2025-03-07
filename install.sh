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
   echo "Installing Desktop Environment and VNC..."
   apt update -qq > /dev/null 2>&1 && apt install -qq -y xfce4 xfce4-terminal tightvncserver wget curl tmate autocutsel nano tigervnc-standalone-server > /dev/null 2>&1

   echo "Installing and configuring Ngrok..."
   curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc > /dev/null 2>&1
   echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list > /dev/null 2>&1
   apt update -qq > /dev/null 2>&1 && apt install -qq -y ngrok > /dev/null 2>&1

   echo "Installation completed silently."
   
    ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
    mkdir -p ~/.vnc
    echo "123456" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    export USER=root
    vncserver -geometry 1200x900 -depth 16 :1
    export DISPLAY=:1
    /usr/bin/autocutsel -fork
    /usr/bin/autocutsel -selection PRIMARY -fork
    ngrok tcp --region in  5901 > /dev/null 2>&1 &
  
    echo "Setup completed."
}

# Paths
BACKUP_PATH="/content/drive/MyDrive/ChromeBackup.zip"
CHROME_PROFILE="/root/.config/google-chrome/Default"

# Function to handle backup when script exits (Ctrl+C)
backup_on_exit() {
    echo -e "\n\n🚀 Detected exit! Backing up Chrome profile..."
    
    # Check if Chrome profile exists
    if [ -d "$CHROME_PROFILE" ]; then
        echo "Creating backup..."
        zip -r -q "$BACKUP_PATH" "$CHROME_PROFILE"
        echo "✅ Backup completed: $BACKUP_PATH"
    else
        echo "⚠️ No Chrome profile found to backup!"
    fi
    
    exit 0
}

# Trap Ctrl+C (SIGINT) to trigger backup_on_exit function
trap backup_on_exit SIGINT

# Function to install Google Chrome
install_chrome() {
    echo "Installing Google Chrome..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome.deb
    dpkg --install /tmp/google-chrome.deb > /dev/null 2>&1 || apt install -qq -y --fix-broken > /dev/null 2>&1
    echo "Google Chrome Installed!"
    sed -i 's|^Exec=/usr/bin/google-chrome-stable.*|Exec=/usr/bin/google-chrome-stable --no-sandbox %U|' /usr/share/applications/google-chrome.desktop
    sudo chmod -R 777 /root/.local/share/applications
    update-desktop-database ~/.local/share/applications
}

# Function to restore Chrome profile if backup exists
restore_profile() {
    if [[ -f "$BACKUP_PATH" ]]; then
        echo "Chrome profile backup found! Restoring..."
        rm -rf "$CHROME_PROFILE"
        mkdir -p "$CHROME_PROFILE"
        unzip -q "$BACKUP_PATH" -d "/"
        echo "Chrome profile restored successfully!"
    else
        echo "No Chrome profile backup found. Skipping restore."
    fi
}
echo "Setup completed!"

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
install_chrome
restore_profile
wall_change

#echo ngrok address
curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'tcp://[^"]*' | sed 's/tcp:\/\///; s/"//g'

#loop
start_time=$(date +%s); while true; do elapsed=$(( $(date +%s) - start_time )); elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))); echo -ne "\rRunning Time: $elapsed_formatted"; sleep 5; done
