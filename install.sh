#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if Ngrok auth token is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <NGROK_AUTH_TOKEN> <REGION> [BOT_API_TOKEN] [CHAT_ID]"
    exit 1
fi

# Check if region is provided
if [[ -z "$2" ]]; then
    echo "Usage: $0 <NGROK_AUTH_TOKEN> <REGION> [BOT_API_TOKEN] [CHAT_ID]"
    exit 1
fi

NGROK_AUTH_TOKEN="$1"
REGION="$2"
API="$3"
CHAT_ID="$4"

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
    apt install -qq -y xfce4 xfce4-terminal tightvncserver wget curl tmate autocutsel nano tigervnc-standalone-server
    pip install playwright openai pyTelegramBotAPI google-genai > /dev/null 2>&1
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
    ngrok tcp --region $REGION 5901 > /dev/null 2>&1 &
  
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

# Function to change Wallpaper
wall_change() {
   curl -s -L -k -o xfce-verticals.png "https://raw.githubusercontent.com/The-Disa1a/Colab-ft-VNC-with-Ngrok/refs/heads/main/wall/CachedImage_1024_768_POS4.jpg"
   CUSTOM_WALLPAPER_PATH="$(pwd)/xfce-verticals.png"
   DESTINATION_PATH="/usr/share/backgrounds/xfce/"
   sudo cp "$CUSTOM_WALLPAPER_PATH" "$DESTINATION_PATH"
   echo "Wallpaper Changed."
}

# Funtion to install vscode
vs_code() {
   sudo apt update -y > /dev/null 2>&1
   sudo apt install wget gpg -y > /dev/null 2>&1
   wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null 2>&1
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null 2>&1
   sudo apt update -y > /dev/null 2>&1
   sudo apt install code -y > /dev/null 2>&1
   echo 'alias code="code --no-sandbox --user-data-dir ~/.vscode-root"' >> ~/.bashrc > /dev/null 2>&1
   source ~/.bashrc > /dev/null 2>&1
   sudo sed -i 's|^Exec=/usr/share/code/code.*|Exec=/usr/share/code/code --no-sandbox --user-data-dir ~/.vscode-root %F|' /usr/share/applications/code.desktop > /dev/null 2>&1
   sudo chmod -R 777 /root/.local/share/applications > /dev/null 2>&1
   update-desktop-database ~/.local/share/applications > /dev/null 2>&1
}

# Execute initial setup functions
create_user
setup_vnc
install_chrome
wall_change

# Show Ngrok address
ngrok_addr=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'tcp://[^"]*' | sed 's/tcp:\/\///; s/"//g')
echo "$ngrok_addr"

# Prepare date and time separately
date_str=$(TZ=Asia/Colombo date "+%Y-%m-%d")
time_str=$(TZ=Asia/Colombo date "+%I:%M %p")

# Build the message with proper formatting:
# Bold labels and inline monospace for the URL
message="*Ngrok TCP Endpoint URL*%0A*DATE :* $date_str%0A*TIME :* $time_str%0A*URL :* \`$ngrok_addr\`"

# Send Telegram message if both API and CHAT_ID are provided
if [[ -n "$API" && -n "$CHAT_ID" ]]; then
    echo "Sending Telegram message..."
    
    # Split the CHAT_ID into an array by commas
    IFS=',' read -r -a chat_ids <<< "$CHAT_ID"
    
    # Loop through each chat ID and send the message
    for chat_id in "${chat_ids[@]}"; do
        curl -s -X POST "https://api.telegram.org/bot$API/sendMessage" \
             -d chat_id="$chat_id" \
             -d parse_mode=Markdown \
             -d text="$message" > /dev/null 2>&1
        echo "Message sent to chat ID: $chat_id"
    done
else
    echo -e "\n[Info] Bot API or Chat ID not provided. Skipping Telegram message."
fi

start_time=$(date +%s); while true; do elapsed=$(( $(date +%s) - start_time )); elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))); echo -ne "\rRunning Time: $elapsed_formatted"; sleep 10; done
