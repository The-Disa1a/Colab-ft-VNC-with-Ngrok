#!/bin/bash

# Check if an argument (Ngrok auth token) is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 \"<NGROK_AUTH_TOKEN>\""
    exit 1
fi

NGROK_AUTH_TOKEN="$1"

sudo apt update
sudo apt install tigervnc-standalone-server -y
echo "123456" | vncpasswd -f > ~/.vnc/passwd
python -m playwright install firefox
chmod 600 ~/.vnc/passwd
vncserver :1
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
ngrok tcp --region ap 5901 > /dev/null 2>&1 &
echo -e "[Desktop Entry]
   Version=1.0
   Name=Firefox Nightly
   Comment=Browse the World Wide Web
   Exec=/usr/lib/firefox/firefox/firefox %u
   Icon=firefox
   Terminal=false
   Type=Application
   Categories=Network;WebBrowser;Internet;
   StartupWMClass=Firefox" | sudo tee /usr/share/applications/firefox-nightly.desktop > /dev/null && sudo chmod +x /usr/share/applications/firefox-nightly.desktop
sleep 5
curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'tcp://[^"]*' | sed 's/tcp:\/\///; s/"//g'
start_time=$(date +%s); while true; do elapsed=$(( $(date +%s) - start_time )); elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))); echo -ne "\rRunning Time: $elapsed_formatted"; sleep 15; done
