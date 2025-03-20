#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if an argument (Ngrok auth token) is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 \"<NGROK_AUTH_TOKEN>\""
    exit 1
fi

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

# Function to install and configure RDP using VNC and Ngrok
setup_vnc() {
    echo "Installing Desktop Environment and VNC..."
    apt update -qq > /dev/null 2>&1 && apt install -qq -y xfce4 xfce4-terminal tightvncserver wget curl tmate autocutsel nano tigervnc-standalone-server > /dev/null 2>&1
    pip install playwright openai > /dev/null 2>&1
    python -m playwright install firefox > /dev/null 2>&1
    # Automatically detect the latest Firefox Nightly folder from the Playwright cache
   firefox_folder=$(find "$HOME/.cache/ms-playwright" -maxdepth 1 -type d -name 'firefox-*' | sort -r | head -n 1)

   if [ -n "$firefox_folder" ]; then
    # Create the symlink for the firefox binary (Nightly)
    sudo ln -sf "$firefox_folder/firefox/firefox" /usr/local/bin/nightly

    # Get just the folder name (e.g. firefox-1475)
    firefox_folder_basename=$(basename "$firefox_folder")

    # Create a dynamic desktop entry for Firefox Nightly
    echo -e "[Desktop Entry]
   Version=1.0
   Name=Firefox Nightly
   Comment=Browse the World Wide Web
   Exec=$HOME/.cache/ms-playwright/$firefox_folder_basename/firefox/firefox %u
   Icon=firefox
   Terminal=false
   Type=Application
   Categories=Network;WebBrowser;Internet;
   StartupWMClass=Firefox" | sudo tee /usr/share/applications/firefox-nightly.desktop > /dev/null && sudo chmod +x /usr/share/applications/firefox-nightly.desktop

    echo "Firefox Nightly desktop entry updated."
   else
    echo "Could not find Firefox Nightly installation directory."
   fi

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
    vncserver -geometry 1200x900 :1
    export DISPLAY=:1
    /usr/bin/autocutsel -fork
    /usr/bin/autocutsel -selection PRIMARY -fork
    ngrok tcp 5901 > /dev/null 2>&1 &
  
    echo "VNC and Ngrok setup completed."
}

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

# Function to restore profiles from backup
restore_profile() {
    echo "Checking for backup files..."
    echo "Looking for Chrome backup at: /content/drive/MyDrive/Profiles/ChromeBackup.zip"
    echo "Looking for Firefox root backup at: /content/drive/MyDrive/Profiles/RNightly.zip"
    echo "Looking for Firefox local backup at: /content/drive/MyDrive/Profiles/LNightly.zip"

    CHROME_BACKUP_PATH="/content/drive/MyDrive/Profiles/ChromeBackup.zip"
    NIGHTLY_RBACKUP_PATH="/content/drive/MyDrive/Profiles/RNightly.zip"
    NIGHTLY_LBACKUP_PATH="/content/drive/MyDrive/Profiles/LNightly.zip"
    CHROME_PROFILE="$HOME/.config/google-chrome/Default"
    NIGHTLY_ROOT_PROFILE="$HOME/.mozilla/firefox"
    NIGHTLY_LOCAL_PROFILE="$HOME/.cache/mozilla/firefox"

    if [[ -f "$CHROME_BACKUP_PATH" ]]; then
        echo "📂 Chrome profile backup found! Restoring..."
        rm -rf "$CHROME_PROFILE"
        mkdir -p "$CHROME_PROFILE"
        unzip -q "$CHROME_BACKUP_PATH" -d "/"
        echo "✅ Chrome profile restored successfully!"
    else
        echo "⚠️ No Chrome profile backup found. Skipping restore."
    fi

    if [[ -f "$NIGHTLY_RBACKUP_PATH" ]]; then
        echo "🔥 Firefox Nightly root profile backup found! Restoring..."
        rm -rf "$NIGHTLY_ROOT_PROFILE"
        mkdir -p "$NIGHTLY_ROOT_PROFILE"
        unzip -q "$NIGHTLY_RBACKUP_PATH" -d "/"
        echo "✅ Firefox Nightly root profile restored successfully!"
    else
        echo "⚠️ No Firefox Nightly root profile backup found. Skipping restore."
    fi

    if [[ -f "$NIGHTLY_LBACKUP_PATH" ]]; then
        echo "🔥 Firefox Nightly local profile backup found! Restoring..."
        rm -rf "$NIGHTLY_LOCAL_PROFILE"
        mkdir -p "$NIGHTLY_LOCAL_PROFILE"
        unzip -q "$NIGHTLY_LBACKUP_PATH" -d "/"
        echo "✅ Firefox Nightly local profile restored successfully!"
    else
        echo "⚠️ No Firefox Nightly local profile backup found. Skipping restore."
    fi
}

# Function to change Wallpaper
wall_change() {
   curl -s -L -k -o xfce-verticals.png "https://raw.githubusercontent.com/The-Disa1a/Colab-ft-VNC-with-Ngrok/refs/heads/main/wall/CachedImage_1024_768_POS4.jpg"
   CUSTOM_WALLPAPER_PATH="$(pwd)/xfce-verticals.png"
   DESTINATION_PATH="/usr/share/backgrounds/xfce/"
   sudo cp "$CUSTOM_WALLPAPER_PATH" "$DESTINATION_PATH"
   echo "Wallpaper Changed."
}

# ----------------- Backup Functions (Minimal Logging) -----------------

# Define backup paths and profiles
CHROME_BACKUP_PATH="/content/drive/MyDrive/Profiles/ChromeBackup.zip"
NIGHTLY_RBACKUP_PATH="/content/drive/MyDrive/Profiles/RNightly.zip"
NIGHTLY_LBACKUP_PATH="/content/drive/MyDrive/Profiles/LNightly.zip"
CHROME_PROFILE="$HOME/.config/google-chrome/Default"
NIGHTLY_ROOT_PROFILE="$HOME/.mozilla/firefox"
NIGHTLY_LOCAL_PROFILE="$HOME/.cache/mozilla/firefox"

# Perform the backup silently
perform_backup() {
    [ -d "$CHROME_PROFILE" ] && rm -f "$CHROME_BACKUP_PATH" && zip -r -q "$CHROME_BACKUP_PATH" "$CHROME_PROFILE"
    [ -d "$NIGHTLY_ROOT_PROFILE" ] && rm -f "$NIGHTLY_RBACKUP_PATH" && zip -r -q "$NIGHTLY_RBACKUP_PATH" "$NIGHTLY_ROOT_PROFILE"
    [ -d "$NIGHTLY_LOCAL_PROFILE" ] && rm -f "$NIGHTLY_LBACKUP_PATH" && zip -r -q "$NIGHTLY_LBACKUP_PATH" "$NIGHTLY_LOCAL_PROFILE"
}

# Call backup and then print a single summary log with a 12-hour timestamp (GMT+5:30)
do_backup() {
    perform_backup
    backup_time=$(TZ='Asia/Kolkata' date '+%I:%M:%S %p')
    echo -e "\n✅ Backup Was Done: $backup_time"
}

# Trap for SIGINT (Ctrl+C) to perform a final backup with minimal logging
backup_on_exit() {
    echo -e "\n\nDetected exit! Performing final backup..."
    perform_backup
    backup_time=$(TZ='Asia/Kolkata' date '+%I:%M:%S %p')
    echo -e "✅ Final Backup Was Done: $backup_time"
    exit 0
}
trap backup_on_exit SIGINT

# ----------------- End Backup Functions -----------------

# Execute initial setup functions
create_user
setup_vnc
install_chrome
restore_profile
wall_change

# Show Ngrok address
ngrok_addr=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'tcp://[^"]*' | sed 's/tcp:\/\///; s/"//g')
echo "$ngrok_addr"

# Main loop: live running time updated on the same line and automatic backup every 5 minutes
start_time=$(date +%s)
last_backup_time=$(date +%s)
backup_interval=3600  # 3600 seconds = 60 minutes

while true; do
    current_time=$(date +%s)
    running_time=$(( current_time - start_time ))
    live_time=$(printf "%02d:%02d:%02d" $((running_time/3600)) $(((running_time%3600)/60)) $((running_time%60)))
    
    # Update running time on the same line
    echo -ne "\rRunning Time: $live_time"
    
    # Check if 5 minutes have passed and perform backup if so
    if (( current_time - last_backup_time >= backup_interval )); then
         do_backup
         last_backup_time=$current_time
    fi
    
    sleep 15
done
