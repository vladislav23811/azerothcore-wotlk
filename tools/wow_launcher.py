#!/usr/bin/env python3
"""
WoW Custom Launcher
Full-featured launcher that:
- Downloads/updates WoW client
- Checks for missing files
- Downloads patches automatically
- Launches game
"""

import os
import sys
import json
import zipfile
import shutil
import requests
import hashlib
import subprocess
from pathlib import Path
from datetime import datetime

# ============================================================
# CONFIGURATION
# ============================================================
CONFIG = {
    # Server URLs
    "server_url": "http://localhost",  # Change to your server IP
    "game_zip_url": "http://localhost/WOTLKHD.zip",  # Full game download
    "patch_version_url": "http://localhost/patches/version.txt",
    "patch_download_url": "http://localhost/patches/latest/patch-Z.MPQ",
    
    # Local paths
    "wow_path": "C:/WoW",  # WoW installation path
    "temp_path": "C:/WoW_Launcher_Temp",  # Temporary files
    "config_file": "launcher_config.json",
    
    # Game executable
    "wow_exe": "Wow.exe",  # or WowClassic.exe depending on client
    
    # Settings
    "auto_update": True,
    "check_missing_files": True,
    "verify_integrity": False,  # Can be slow, enable if needed
}

class WoWLauncher:
    def __init__(self):
        self.config = self.load_config()
        self.setup_paths()
        
    def load_config(self):
        """Load or create config file"""
        if os.path.exists(CONFIG["config_file"]):
            with open(CONFIG["config_file"], 'r') as f:
                user_config = json.load(f)
                CONFIG.update(user_config)
        else:
            self.save_config()
        return CONFIG
    
    def save_config(self):
        """Save config to file"""
        with open(CONFIG["config_file"], 'w') as f:
            json.dump(CONFIG, f, indent=4)
    
    def setup_paths(self):
        """Create necessary directories"""
        os.makedirs(self.config["temp_path"], exist_ok=True)
        os.makedirs(self.config["wow_path"], exist_ok=True)
    
    def print_header(self):
        """Print launcher header"""
        print("=" * 60)
        print("  WoW Custom Launcher - Progressive Systems")
        print("=" * 60)
        print()
    
    def check_wow_installation(self):
        """Check if WoW is installed"""
        wow_exe_path = os.path.join(self.config["wow_path"], self.config["wow_exe"])
        if os.path.exists(wow_exe_path):
            print(f"✓ WoW found at: {self.config['wow_path']}")
            return True
        else:
            print(f"✗ WoW not found at: {self.config['wow_path']}")
            return False
    
    def download_file(self, url, dest_path, description="file"):
        """Download file with progress"""
        try:
            print(f"Downloading {description}...")
            print(f"  From: {url}")
            print(f"  To: {dest_path}")
            
            response = requests.get(url, stream=True, timeout=30)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            
            with open(dest_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size > 0:
                            percent = (downloaded / total_size) * 100
                            print(f"\r  Progress: {percent:.1f}% ({downloaded}/{total_size} bytes)", end='')
            
            print()  # New line after progress
            print(f"✓ {description} downloaded successfully!")
            return True
            
        except Exception as e:
            print(f"✗ Error downloading {description}: {e}")
            return False
    
    def extract_zip(self, zip_path, extract_to):
        """Extract ZIP file"""
        try:
            print(f"Extracting {zip_path} to {extract_to}...")
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                total_files = len(zip_ref.namelist())
                extracted = 0
                
                for file_info in zip_ref.namelist():
                    zip_ref.extract(file_info, extract_to)
                    extracted += 1
                    if extracted % 100 == 0:
                        print(f"\r  Extracted: {extracted}/{total_files} files", end='')
                
                print()  # New line
                print(f"✓ Extraction complete! ({extracted} files)")
                return True
                
        except Exception as e:
            print(f"✗ Error extracting ZIP: {e}")
            return False
    
    def install_wow_client(self):
        """Download and install WoW client"""
        print("\n=== Installing WoW Client ===")
        
        # Check if zip exists locally first
        local_zip = "WOTLKHD.zip"
        if not os.path.exists(local_zip):
            # Download from server
            temp_zip = os.path.join(self.config["temp_path"], "WOTLKHD.zip")
            if not self.download_file(self.config["game_zip_url"], temp_zip, "WoW client ZIP"):
                return False
            local_zip = temp_zip
        
        # Extract to WoW path
        if self.extract_zip(local_zip, self.config["wow_path"]):
            print(f"✓ WoW client installed to: {self.config['wow_path']}")
            return True
        
        return False
    
    def check_missing_files(self):
        """Check for critical missing files"""
        print("\n=== Checking for Missing Files ===")
        
        critical_files = [
            self.config["wow_exe"],
            "Data/enUS/patch-enUS.MPQ",
            "Data/enUS/patch-enUS-2.MPQ",
            "Data/enUS/patch-enUS-3.MPQ",
            "Data/patch.MPQ",
            "Data/patch-2.MPQ",
            "Data/patch-3.MPQ",
        ]
        
        missing = []
        for file in critical_files:
            file_path = os.path.join(self.config["wow_path"], file)
            if not os.path.exists(file_path):
                missing.append(file)
                print(f"✗ Missing: {file}")
            else:
                print(f"✓ Found: {file}")
        
        if missing:
            print(f"\n⚠ {len(missing)} critical file(s) missing!")
            response = input("Re-download client? (y/n): ")
            if response.lower() == 'y':
                return self.install_wow_client()
            return False
        
        print("✓ All critical files present!")
        return True
    
    def get_patch_version(self):
        """Get patch version from server"""
        try:
            response = requests.get(self.config["patch_version_url"], timeout=5)
            if response.status_code == 200:
                return response.text.strip()
        except:
            pass
        return None
    
    def get_local_patch_version(self):
        """Get local patch version"""
        patch_file = os.path.join(self.config["wow_path"], "Data", "patch-Z.MPQ")
        if os.path.exists(patch_file):
            # Use file modification time as version
            mtime = os.path.getmtime(patch_file)
            return str(int(mtime))
        return "0"
    
    def update_patch(self):
        """Download and update MPQ patch"""
        print("\n=== Checking for Patch Updates ===")
        
        server_version = self.get_patch_version()
        if not server_version:
            print("⚠ Could not connect to server. Skipping patch update.")
            return True  # Not a critical error
        
        local_version = self.get_local_patch_version()
        
        print(f"Local version: {local_version}")
        print(f"Server version: {server_version}")
        
        if server_version > local_version or local_version == "0":
            print("New patch available! Downloading...")
            
            patch_path = os.path.join(self.config["wow_path"], "Data", "patch-Z.MPQ")
            if self.download_file(self.config["patch_download_url"], patch_path, "MPQ patch"):
                print("✓ Patch updated successfully!")
                return True
            else:
                print("⚠ Patch download failed, but game can still run")
                return True  # Not critical
        else:
            print("✓ Patch is up to date!")
            return True
    
    def launch_game(self):
        """Launch WoW client"""
        print("\n=== Launching WoW ===")
        
        wow_exe_path = os.path.join(self.config["wow_path"], self.config["wow_exe"])
        
        if not os.path.exists(wow_exe_path):
            print(f"✗ WoW executable not found: {wow_exe_path}")
            return False
        
        print(f"Launching: {wow_exe_path}")
        try:
            # Change to WoW directory
            os.chdir(self.config["wow_path"])
            # Launch game
            subprocess.Popen([wow_exe_path], cwd=self.config["wow_path"])
            print("✓ WoW launched!")
            return True
        except Exception as e:
            print(f"✗ Error launching WoW: {e}")
            return False
    
    def run(self):
        """Main launcher loop"""
        self.print_header()
        
        # Check if WoW is installed
        if not self.check_wow_installation():
            print("\nWoW is not installed.")
            response = input("Download and install WoW client? (y/n): ")
            if response.lower() == 'y':
                if not self.install_wow_client():
                    print("✗ Installation failed!")
                    return
            else:
                print("Exiting...")
                return
        
        # Check for missing files
        if self.config["check_missing_files"]:
            if not self.check_missing_files():
                print("⚠ Some files are missing. Game may not work correctly.")
        
        # Update patch
        if self.config["auto_update"]:
            self.update_patch()
        
        # Launch game
        print("\n" + "=" * 60)
        response = input("Launch WoW now? (y/n): ")
        if response.lower() == 'y':
            self.launch_game()
        else:
            print("Exiting...")

def main():
    """Main entry point"""
    try:
        launcher = WoWLauncher()
        launcher.run()
    except KeyboardInterrupt:
        print("\n\nLauncher cancelled by user.")
        sys.exit(0)
    except Exception as e:
        print(f"\n✗ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

