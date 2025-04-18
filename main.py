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

def unzip_folder(zip_path, extract_to):
    """Unzip archive to extract_to, fixing deeply nested paths like /root/..."""

    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        members = zip_ref.infolist()
        normalized_extract_to = os.path.normpath(extract_to)

        # Remove existing folder first
        if os.path.exists(extract_to):
            shutil.rmtree(extract_to)
        os.makedirs(extract_to, exist_ok=True)

        for member in members:
            member_path = member.filename

            # Normalize and split the path
            parts = Path(member_path).parts

            # Try to find where the real profile path begins inside the zip
            # e.g., skip over '/root/.mozilla/firefox' if restoring into ~/.mozilla/firefox
            try:
                # This is the index where profile name starts in zip entry
                idx = parts.index(Path(extract_to).name)
                relative_parts = parts[idx + 1:]  # +1 to skip the folder itself
            except ValueError:
                relative_parts = parts  # If no match, extract whole path

            if not relative_parts:
                continue  # Skip folders

            target_path = os.path.join(extract_to, *relative_parts)

            if member.is_dir():
                os.makedirs(target_path, exist_ok=True)
            else:
                os.makedirs(os.path.dirname(target_path), exist_ok=True)
                with zip_ref.open(member) as source, open(target_path, 'wb') as target:
                    shutil.copyfileobj(source, target)
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
