sudo apt update
sudo apt install tigervnc-standalone-server -y
echo "123456" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
vncserver :1
ngrok config add-authtoken 2P8v3I9oxTnCsnsVcKIOjd9Rt4Y_5jzoNH4hQQNfWcR8iQz8i
ngrok tcp --region ap  5901 > /dev/null 2>&1 &
sleep 5
curl -s http://127.0.0.1:4040/api/tunnels | grep -o '"tcp://[^"]*' | sed 's/tcp:\/\///'
start_time=$(date +%s); while true; do elapsed=$(( $(date +%s) - start_time )); elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))); echo -ne "\rRunning Time: $elapsed_formatted"; sleep 1; done
