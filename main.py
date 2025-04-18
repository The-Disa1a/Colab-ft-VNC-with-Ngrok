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
    #print(f"🗄 Zipping folder {folder_path} into {zip_path}")
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(folder_path):
            for file in files:
                file_path = os.path.join(root, file)
                if not os.path.islink(file_path):  # Skip symlinks
                    arcname = os.path.relpath(file_path, folder_path)
                    zipf.write(file_path, arcname)

import os, shutil, zipfile

def unzip_folder(zip_path, extract_to):
    """Unzip archive to extract_to, stripping any leading folder paths
       that match the extract_to location itself."""
    # Prepare strip‐prefixes:
    #  1) absolute (no leading slash):  "root/.mozilla/firefox"
    #  2) home‐relative:                ".mozilla/firefox"
    abs_prefix   = extract_to.lstrip(os.sep)
    home_prefix  = os.path.relpath(extract_to, os.path.expanduser("~")).lstrip(os.sep)
    prefixes     = [abs_prefix, home_prefix]

    # Clear out any existing folder
    if os.path.exists(extract_to):
        shutil.rmtree(extract_to)
    os.makedirs(extract_to, exist_ok=True)

    with zipfile.ZipFile(zip_path, 'r') as zipf:
        for member in zipf.namelist():
            # skip directories
            if member.endswith('/'):
                continue

            # normalize (remove any leading “/” in the zip entry)
            m = member.lstrip('/')

            # strip off any of our prefixes
            for p in prefixes:
                if m.startswith(p + '/'):
                    m = m[len(p) + 1:]
                    break

            # avoid dangerous paths
            m = os.path.normpath(m)
            if m.startswith('..'):
                continue

            # write out
            dest = os.path.join(extract_to, m)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with zipf.open(member) as src, open(dest, 'wb') as dst:
                dst.write(src.read())
                
def backup():
    print("🗂️ Starting backup...")
    for name, paths in backups.items():
        if os.path.isdir(paths["src"]):
            tmp_backup = f"/tmp/{os.path.basename(paths['dst'])}"

            # Move current to old
            if os.path.exists(paths["dst"]):
                #print(f"🗃 Moving current backup '{paths['dst']}' to '{paths['old']}'")
                shutil.move(paths["dst"], paths["old"])

            if os.path.exists(tmp_backup):
                #print(f"🧹 Removing stale temp backup: {tmp_backup}")
                os.remove(tmp_backup)

            #print(f"🆕 Creating backup for {name}")
            zip_folder(paths["src"], tmp_backup)
            shutil.move(tmp_backup, paths["dst"])
            print(f"✅ {name} profile backed up to {paths['dst']}.")

            # Remove old after successful backup
            if os.path.exists(paths["old"]):
                os.remove(paths["old"])
                print(f"🧹 Deleted old backup: {paths['old']}")
        else:
            print(f"⚠️ Source for {name} does not exist: {paths['src']}")
    log_time("✅ Backup complete at")

def restore():
    print("🗃️ Starting restore...")
    for name, paths in backups.items():
        if os.path.exists(paths["dst"]):
            print(f"📑 Restoring {name} from {paths['dst']}")
            unzip_folder(paths["dst"], paths["src"])
            print(f"✅ {name} profile restored.")
        else:
            print(f"⚠️ {name} backup not found. Skipping.")

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
