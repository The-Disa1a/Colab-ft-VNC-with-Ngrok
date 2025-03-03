#!/bin/bash

# Define paths
CHROME_PROFILE="$HOME/.config/google-chrome"
BACKUP_PATH="/content/drive/MyDrive/chrome-profile"

# Save Chrome Profile
backup() {
    echo "Backing up Chrome profile..."
    rsync -av --progress "$CHROME_PROFILE/" "$BACKUP_PATH/"
    echo "Backup completed."
}

# Restore Chrome Profile
restore() {
    echo "Restoring Chrome profile..."
    rsync -av --progress "$BACKUP_PATH/" "$CHROME_PROFILE/"
    echo "Restore completed."
}

# Check user input
if [ "$1" == "backup" ]; then
    backup
elif [ "$1" == "restore" ]; then
    restore
else
    echo "Usage: bash /content/backup.sh [backup|restore]"
fi
