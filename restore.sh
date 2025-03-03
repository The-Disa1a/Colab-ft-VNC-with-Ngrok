#!/bin/bash

# Mount Google Drive
from google.colab import drive
drive.mount('/content/drive')

# Restore Chrome profile
rsync -av /content/drive/MyDrive/chrome-profile/ ~/.config/google-chrome/
