#!/bin/bash

BACKUP_PATH="/content/drive/MyDrive/ChromeBackup.zip"
CHROME_PROFILE="/root/.config/google-chrome/Default"

backup() {
    echo "Compressing Chrome profile..."
    zip -r -q "$BACKUP_PATH" "$CHROME_PROFILE" -x "*.lock" "*.socket" "*.cookie"
    echo "Backup completed! File saved at: $BACKUP_PATH"
}

restore() {
    echo "Restoring Chrome profile..."
    rm -rf "$CHROME_PROFILE"
    mkdir -p "$CHROME_PROFILE"
    unzip -q "$BACKUP_PATH" -d "/"
    echo "Restore completed!"
}

case "$1" in
    backup) backup ;;
    restore) restore ;;
    *) echo "Usage: $0 {backup|restore}" ;;
esac
