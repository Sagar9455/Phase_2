#!/bin/bash
# ============================================================
#  Build + Install Script (Raspberry Pi OS)
#  Uses PyInstaller .spec + installs systemd service
# ============================================================

set -e

# -------- CONFIG --------
APP_NAME="UDS"              # executable name
SPEC_FILE="uds_app.spec"        # your .spec file
SERVICE_FILE="uds_app.service"  # your .service file
INSTALL_DIR="/opt/$APP_NAME"

echo "🔧 Starting full build & install process..."

# -------- STEP 1: Create virtual environment --------
echo "📦 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# -------- STEP 2: Install dependencies --------
echo "📥 Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
pip install pyinstaller

# -------- STEP 3: Clean old builds --------
echo "🧹 Cleaning old builds..."
rm -rf build dist __pycache__

# -------- STEP 4: Build using .spec --------
echo "🚀 Building using $SPEC_FILE..."
pyinstaller $SPEC_FILE

# -------- STEP 5: Install executable --------
echo "📁 Installing application..."

sudo mkdir -p $INSTALL_DIR
sudo cp dist/$APP_NAME $INSTALL_DIR/
sudo chmod +x $INSTALL_DIR/$APP_NAME

# -------- STEP 6: Install systemd service --------
echo "⚙️ Installing systemd service..."

sudo cp $SERVICE_FILE /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# Enable service at boot
sudo systemctl enable $APP_NAME.service

# Start service
sudo systemctl start $APP_NAME.service

# -------- STEP 7: Status --------
echo "📊 Service status:"
sudo systemctl status $APP_NAME.service --no-pager

# -------- DONE --------
echo "✅ Build & installation complete!"
echo "🚀 App installed at: $INSTALL_DIR/$APP_NAME"

# Deactivate venv
deactivate