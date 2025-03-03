#!/bin/bash

# Mount Google Drive
from google.colab import drive
drive.mount('/content/drive')

# Backup Chrome profile
rsync -av ~/.config/google-chrome/ /content/drive/MyDrive/chrome-profile/
