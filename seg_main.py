#!/usr/bin/env python3
import argparse
import os
import shutil
import zipfile
import requests
import io
from datetime import datetime
import pytz
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload, MediaIoBaseDownload

# ======== CONFIG ========
SERVICE_ACCOUNT_URL = "https://raw.githubusercontent.com/The-Disa1a/downloads/refs/heads/main/drive_service_account.json"
SERVICE_ACCOUNT_FILE = "drive_service_account.json"
DRIVE_FOLDER_ID = "1t44Z0mJmBipoqNgkQZpU3SinIfGozb8B"  # <-- Replace with your Drive folder ID
# =========================

# Brave profile path
brave_profile = os.path.expanduser("/sec/root/.config/BraveSoftware/Brave-Browser")

# Backup file names
BACKUP_ZIP_NAME = "BraveBackup.zip"
OLD_BACKUP_ZIP_NAME = "BraveBackup.old.zip"
TMP_BACKUP = f"/tmp/{BACKUP_ZIP_NAME}"

# Local paths
local_backup_path = os.path.join(os.getcwd(), BACKUP_ZIP_NAME)
local_old_path = os.path.join(os.getcwd(), OLD_BACKUP_ZIP_NAME)

def download_service_account_json():
    if not os.path.exists(SERVICE_ACCOUNT_FILE):
        print("🌐 Downloading service account JSON...")
        r = requests.get(SERVICE_ACCOUNT_URL)
        with open(SERVICE_ACCOUNT_FILE, "wb") as f:
            f.write(r.content)
        print("✅ Service account JSON downloaded.")

def get_drive_service():
    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=["https://www.googleapis.com/auth/drive"]
    )
    return build("drive", "v3", credentials=creds)

def zip_folder(folder_path, zip_path):
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(folder_path):
            for file in files:
                file_path = os.path.join(root, file)
                if not os.path.islink(file_path):
                    arcname = os.path.relpath(file_path, folder_path)
                    zipf.write(file_path, arcname)

def unzip_folder(zip_path, extract_to):
    abs_prefix = extract_to.lstrip(os.sep)
    home_prefix = os.path.relpath(extract_to, os.path.expanduser("~")).lstrip(os.sep)
    prefixes = [abs_prefix, home_prefix]

    if os.path.exists(extract_to):
        shutil.rmtree(extract_to)
    os.makedirs(extract_to, exist_ok=True)

    with zipfile.ZipFile(zip_path, 'r') as zipf:
        for member in zipf.namelist():
            if member.endswith('/'):
                continue
            m = member.lstrip('/')
            for p in prefixes:
                if m.startswith(p + '/'):
                    m = m[len(p) + 1:]
                    break
            m = os.path.normpath(m)
            if m.startswith('..'):
                continue
            dest = os.path.join(extract_to, m)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with zipf.open(member) as src, open(dest, 'wb') as dst:
                dst.write(src.read())

def upload_to_drive(local_file, drive_filename):
    service = get_drive_service()
    query = f"name='{drive_filename}' and '{DRIVE_FOLDER_ID}' in parents and trashed=false"
    results = service.files().list(q=query, fields="files(id)").execute()
    for file in results.get('files', []):
        service.files().delete(fileId=file['id']).execute()

    metadata = {"name": drive_filename, "parents": [DRIVE_FOLDER_ID]}
    media = MediaFileUpload(local_file, resumable=True)
    uploaded = service.files().create(body=metadata, media_body=media, fields="id").execute()
    print(f"✅ Uploaded to Drive as {drive_filename} (ID: {uploaded['id']})")

def download_from_drive(drive_filename, local_path):
    service = get_drive_service()
    query = f"name='{drive_filename}' and '{DRIVE_FOLDER_ID}' in parents and trashed=false"
    results = service.files().list(q=query, fields="files(id)").execute()
    files = results.get('files', [])
    if not files:
        print(f"❌ File '{drive_filename}' not found on Drive.")
        return False
    file_id = files[0]['id']
    request = service.files().get_media(fileId=file_id)
    with open(local_path, 'wb') as f:
        downloader = MediaIoBaseDownload(f, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
            print(f"⬇️ Download {int(status.progress() * 100)}%.")
    print(f"✅ Downloaded '{drive_filename}' to {local_path}")
    return True

def delete_from_drive(drive_filename):
    service = get_drive_service()
    query = f"name='{drive_filename}' and '{DRIVE_FOLDER_ID}' in parents and trashed=false"
    results = service.files().list(q=query, fields="files(id)").execute()
    for file in results.get('files', []):
        service.files().delete(fileId=file['id']).execute()
        print(f"🗑️ Deleted '{drive_filename}' from Drive.")

def log_time(msg_prefix):
    tz = pytz.timezone("Asia/Kolkata")
    now = datetime.now(tz)
    print(f"\n{msg_prefix}: {now.strftime('%I:%M:%S %p')}")

def backup():
    print("🗂️ Starting backup...")
    if not os.path.isdir(brave_profile):
        print(f"⚠️ Source does not exist: {brave_profile}")
        return

    if os.path.exists(local_backup_path):
        shutil.move(local_backup_path, local_old_path)

    zip_folder(brave_profile, TMP_BACKUP)
    shutil.move(TMP_BACKUP, local_backup_path)

    upload_to_drive(local_backup_path, BACKUP_ZIP_NAME)
    delete_from_drive(OLD_BACKUP_ZIP_NAME)

    if os.path.exists(local_old_path):
        os.remove(local_old_path)
    print(f"✅ Local backup complete: {local_backup_path}")
    log_time("✅ Backup finished at")

def restore():
    print("🗃️ Starting restore...")
    success = download_from_drive(BACKUP_ZIP_NAME, local_backup_path)
    if not success:
        return
    unzip_folder(local_backup_path, brave_profile)
    print(f"✅ Restored Brave profile to {brave_profile}")
    log_time("✅ Restore finished at")

def delete_remote():
    print("🚨 Deleting remote backups...")
    delete_from_drive(BACKUP_ZIP_NAME)
    delete_from_drive(OLD_BACKUP_ZIP_NAME)
    log_time("✅ Deletion finished at")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Brave Profile Backup/Restore using Google Drive")
    parser.add_argument("--backup", action="store_true", help="Perform backup to Google Drive")
    parser.add_argument("--restore", action="store_true", help="Restore from Google Drive")
    parser.add_argument("--delete", action="store_true", help="Permanently delete remote backup from Drive")

    args = parser.parse_args()

    download_service_account_json()

    if args.backup:
        backup()
    elif args.restore:
        restore()
    elif args.delete:
        delete_remote()
    else:
        print("Usage: main.py --backup | --restore | --delete")
