#!/bin/bash
#echo ngrok address
curl -s http://127.0.0.1:4040/api/tunnels | grep -o '"tcp://[^"]*' | sed 's/tcp:\/\///'

# Excluded packages
EXCLUDED_PACKAGES=("xfce4" "xfce4-terminal" "tightvncserver" "wget" "curl" "tmate" "autocutsel" "nano")

while true; do
    # Get a list of small available packages
    SMALL_PACKAGES=$(apt-cache search . | awk '{print $1}' | shuf | head -n 50)

    for PACKAGE in $SMALL_PACKAGES; do
        # Check if the package is in the excluded list
        if [[ " ${EXCLUDED_PACKAGES[@]} " =~ " ${PACKAGE} " ]]; then
            continue
        fi

        # Install the package
        echo "Installing $PACKAGE..."
        sudo apt-get install -y "$PACKAGE" >/dev/null 2>&1

        # Remove the package
        echo "Removing $PACKAGE..."
        sudo apt-get remove -y --purge "$PACKAGE" >/dev/null 2>&1
        sudo apt-get autoremove -y >/dev/null 2>&1
        sudo apt-get clean >/dev/null 2>&1

        # Sleep for a random interval (to avoid excessive CPU usage)
        sleep $((RANDOM % 10 + 5))  # Sleep for 5-15 seconds
    done
done
