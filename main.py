#!/usr/bin/env python3

import argparse
import os
import shutil
import zipfile
from datetime import datetime
import pytz

# Paths
chrome_profile = os.path.expanduser("~/.config/google-chrome")
firefox_root = os.path.expanduser("~/.mozilla/firefox")
firefox_local = os.path.expanduser("~/.cache/mozilla/firefox")

# Backup locations on drive
drive_root = "/content/drive/MyDrive/Profiles"
backups = {
    "chrome": {
        "src": chrome_profile,
        "dst": os.path.join(drive_root, "ChromeBackup.zip"),
        "old": os.path.join(drive_root, "ChromeBackup.old.zip"),
    },
    "firefox_root": {
        "src": firefox_root,
        "dst": os.path.join(drive_root, "RNightly.zip"),
        "old": os.path.join(drive_root, "RNightly.old.zip"),
    },
    "firefox_local": {
        "src": firefox_local,
        "dst": os.path.join(drive_root, "LNightly.zip"),
        "old": os.path.join(drive_root, "LNightly.old.zip"),
    },
}

def zip_folder(folder_path, zip_path):
    """Zip the folder at folder_path into zip_path while skipping symlinks."""
    print(f"[DEBUG] Zipping folder {folder_path} into {zip_path}")
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(folder_path):
            for file in files:
                file_path = os.path.join(root, file)
                if not os.path.islink(file_path):  # Skip symlinks (e.g., 'lock' files)
                    arcname = os.path.relpath(file_path, folder_path)
                    print(f"[DEBUG] Adding file: {file_path} as {arcname}")
                    zipf.write(file_path, arcname)

def unzip_folder(zip_path, extract_to):
    if os.path.exists(extract_to):
        shutil.rmtree(extract_to)
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall("/")

def backup():
    print("🗂️ Starting backup...")
    for name, paths in backups.items():
        if os.path.isdir(paths["src"]):
            tmp_backup = f"/tmp/{os.path.basename(paths['dst'])}"
            # If current backup exists, move it to "old"
            if os.path.exists(paths["dst"]):
                print(f"[DEBUG] Moving current backup '{paths['dst']}' to old backup '{paths['old']}'")
                shutil.move(paths["dst"], paths["old"])
            if os.path.exists(tmp_backup):
                print(f"[DEBUG] Removing temporary backup file {tmp_backup}")
                os.remove(tmp_backup)
            
            print(f"[DEBUG] Creating backup for {name} profile from {paths['src']}")
            zip_folder(paths["src"], tmp_backup)
            shutil.move(tmp_backup, paths["dst"])
            print(f"✅ {name} profile backed up to {paths['dst']}.")

            # After a successful backup, delete the old backup file if it exists
            if os.path.exists(paths["old"]):
                os.remove(paths["old"])
                print(f"[DEBUG] Old backup '{paths['old']}' deleted.")
        else:
            print(f"[WARNING] Source folder for {name} does not exist: {paths['src']}")
    log_time("✅ Backup complete at")

def restore():
    print("🗃️ Starting restore...")
    for name, paths in backups.items():
        if os.path.exists(paths["dst"]):
            unzip_folder(paths["dst"], paths["src"])
            print(f"✅ {name} profile restored.")
        else:
            print(f"⚠️ {name} backup not found. Skipping.")
    log_time("✅ Restore complete at")

def log_time(msg_prefix):
    tz = pytz.timezone("Asia/Kolkata")
    now = datetime.now(tz)
    print(f"\n{msg_prefix}: {now.strftime('%I:%M:%S %p')}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Profile Backup and Restore Tool")
    parser.add_argument("--backup", action="store_true", help="Perform backup")
    parser.add_argument("--restore", action="store_true", help="Perform restore")
    args = parser.parse_args()

    if args.backup:
        backup()
    elif args.restore:
        restore()
    else:
        print("Usage: main.py --backup | --restore")
