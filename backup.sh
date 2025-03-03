#!/bin/bash

BACKUP_PATH="/content/drive/MyDrive/ChromeBackup"
CHROME_PROFILE="/root/.config/google-chrome/Default"

backup() {
    echo "Backing up Chrome profile..."
    mkdir -p "$BACKUP_PATH"
    rsync -av --progress "$CHROME_PROFILE/" "$BACKUP_PATH/" --exclude="SingletonLock" --exclude="SingletonSocket" --exclude="SingletonCookie"
    echo "Backup completed!"
}

restore() {
    echo "Restoring Chrome profile..."
    mkdir -p "$CHROME_PROFILE"
    rsync -av --progress "$BACKUP_PATH/" "$CHROME_PROFILE/"
    rm -rf "$CHROME_PROFILE/SingletonLock" "$CHROME_PROFILE/SingletonSocket" "$CHROME_PROFILE/SingletonCookie"
    echo "Restore completed!"
}

case "$1" in
    backup) backup ;;
    restore) restore ;;
    *) echo "Usage: $0 {backup|restore}" ;;
esac
