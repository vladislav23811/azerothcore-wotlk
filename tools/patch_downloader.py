#!/usr/bin/env python3
"""
Patch Downloader Tool
Downloads MPQ patches from server automatically
Can be called by addon or run manually
"""

import sys
import os
import requests
import shutil
from pathlib import Path

# Configuration
SERVER_URL = "http://your-server-ip:8080"  # Change this!
PATCH_VERSION_URL = f"{SERVER_URL}/patches/version.txt"
PATCH_DOWNLOAD_URL = f"{SERVER_URL}/patches/latest/patch-Z.MPQ"
VERSION_FILE = "Interface/AddOns/ProgressiveSystems/patch_version.txt"
PATCH_DEST = "Data/patch-Z.MPQ"

def get_local_version():
    """Get local patch version"""
    if os.path.exists(VERSION_FILE):
        with open(VERSION_FILE, 'r') as f:
            return f.read().strip()
    return "0"

def get_server_version():
    """Get server patch version"""
    try:
        response = requests.get(PATCH_VERSION_URL, timeout=5)
        if response.status_code == 200:
            return response.text.strip()
    except Exception as e:
        print(f"Error checking server version: {e}")
    return None

def download_patch():
    """Download patch from server"""
    try:
        print(f"Downloading patch from {PATCH_DOWNLOAD_URL}...")
        response = requests.get(PATCH_DOWNLOAD_URL, timeout=30, stream=True)
        
        if response.status_code == 200:
            # Create Data directory if needed
            os.makedirs(os.path.dirname(PATCH_DEST), exist_ok=True)
            
            # Download file
            with open(PATCH_DEST, 'wb') as f:
                shutil.copyfileobj(response.raw, f)
            
            print(f"Patch downloaded successfully to {PATCH_DEST}")
            return True
        else:
            print(f"Error: Server returned status code {response.status_code}")
            return False
    except Exception as e:
        print(f"Error downloading patch: {e}")
        return False

def save_version(version):
    """Save patch version"""
    os.makedirs(os.path.dirname(VERSION_FILE), exist_ok=True)
    with open(VERSION_FILE, 'w') as f:
        f.write(version)

def main():
    print("=== Progressive Systems Patch Downloader ===")
    
    # Get versions
    local_version = get_local_version()
    print(f"Local version: {local_version}")
    
    server_version = get_server_version()
    if not server_version:
        print("Could not connect to server. Check SERVER_URL in script.")
        return 1
    
    print(f"Server version: {server_version}")
    
    # Check if update needed
    if server_version > local_version:
        print("New patch available! Downloading...")
        if download_patch():
            save_version(server_version)
            print("✓ Patch updated successfully!")
            print("Please restart your WoW client.")
            return 0
        else:
            print("✗ Failed to download patch")
            return 1
    else:
        print("✓ Patch is up to date!")
        return 0

if __name__ == "__main__":
    sys.exit(main())

