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
    """Unzip archive to extract_to, avoiding nested folder duplication."""
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        members = zip_ref.namelist()
        common_prefix = os.path.commonprefix(members)
        zip_root_dir = os.path.normpath(common_prefix).split(os.sep)[0]
        target_basename = os.path.basename(os.path.normpath(extract_to))

        # Check if the zip is structured with the root dir (i.e., will cause nesting)
        has_nested_root = zip_root_dir == target_basename

        # Clean up existing target
        if os.path.exists(extract_to):
            shutil.rmtree(extract_to)

        if has_nested_root:
            # Extract to parent to avoid duplication
            parent_dir = os.path.dirname(extract_to)
            print(f"📁 Detected nested root, extracting to parent: {parent_dir}")
            zip_ref.extractall(parent_dir)

            extracted_path = os.path.join(parent_dir, zip_root_dir)
            if extracted_path != extract_to:
                # Clean target (again) in case partial conflict
                if os.path.exists(extract_to):
                    shutil.rmtree(extract_to)
                shutil.move(extracted_path, extract_to)
        else:
            print(f"📂 Extracting normally to: {extract_to}")
            os.makedirs(extract_to, exist_ok=True)
            zip_ref.extractall(extract_to)

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
