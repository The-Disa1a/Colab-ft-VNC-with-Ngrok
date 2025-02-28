#!/bin/bash
#echo ngrok address
curl -s http://127.0.0.1:4040/api/tunnels | grep -o '"tcp://[^"]*' | sed 's/tcp:\/\///'

# Keep-alive loop
start_time=$(date +%s)
while true; do
    elapsed=$(($(date +%s) - start_time))
    elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
    echo -ne "\rRunning Time: $elapsed_formatted"
    sleep 1
done
