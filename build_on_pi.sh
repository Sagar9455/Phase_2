#!/usr/bin/env bash
# ============================================================
#  UDS Diagnostics - Raspberry Pi Build Script (Robust Version)
#  Works on: Pi 3, Pi 4, Pi 5, Pi Zero 2 (32-bit & 64-bit OS)
# ============================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="uds_diagnostics"
OUTPUT_DIR="$PROJECT_DIR/dist"
VENV_DIR="$PROJECT_DIR/venv"

echo ""
echo "=============================================="
echo "  UDS Diagnostics - Raspberry Pi Build Tool"
echo "=============================================="
echo ""

# --- Step 1: Check Python ---
echo "[1/7] Checking Python..."
python3 --version || {
    echo "ERROR: python3 not found. Install with:"
    echo "sudo apt install python3"
    exit 1
}

# --- Step 2: Ensure pip exists ---
echo "[2/7] Checking pip..."
python3 -m pip --version >/dev/null 2>&1 || {
    echo "Installing pip..."
    sudo apt-get update
    sudo apt-get install -y python3-pip
}

# --- Step 3: Create virtual environment ---
echo "[3/7] Setting up virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

# Activate venv
source "$VENV_DIR/bin/activate"

# --- Step 4: Upgrade pip ---
echo "[4/7] Upgrading pip..."
python -m pip install --upgrade pip

# --- Step 5: Install dependencies ---
echo "[5/7] Installing dependencies..."
pip install \
    pyinstaller \
    RPi.GPIO \
    adafruit-circuitpython-ssd1306 \
    adafruit-blinka \
    Pillow \
    python-can \
    can-isotp \
    udsoncan

# --- Step 6: Prepare project ---
echo "[6/7] Preparing project..."
cd "$PROJECT_DIR"

# Ensure package structure
mkdir -p drivers
touch drivers/__init__.py

# Clean old builds (optional but recommended)
rm -rf build dist *.spec

echo ""
echo "🏗️ Building executable..."
echo "This may take a few minutes..."
echo ""

# --- Step 7: Build ---
python -m PyInstaller \
    --onefile \
    --name "$APP_NAME" \
    --add-data "config.json:." \
    --add-data "drivers:drivers" \
    --hidden-import RPi \
    --hidden-import RPi.GPIO \
    --hidden-import board \
    --hidden-import busio \
    --hidden-import adafruit_ssd1306 \
    --hidden-import PIL \
    --hidden-import PIL.Image \
    --hidden-import PIL.ImageDraw \
    --hidden-import PIL.ImageFont \
    --hidden-import can \
    --hidden-import can.interfaces.socketcan \
    --hidden-import can.io.asc \
    --hidden-import isotp \
    --hidden-import udsoncan \
    --hidden-import udsoncan.client \
    --hidden-import udsoncan.connections \
    --hidden-import udsoncan.configs \
    --hidden-import udsoncan.services \
    --hidden-import drivers \
    --hidden-import drivers.config_loader \
    --hidden-import drivers.oled_display \
    --hidden-import drivers.button_input \
    --hidden-import drivers.uds_client \
    --hidden-import drivers.transfer_file \
    --hidden-import drivers.Parse_handler \
    --hidden-import drivers.can_logger \
    --hidden-import drivers.report_generator \
    main.py

# --- Done ---
echo ""
echo "=============================================="
echo "✅ Build complete!"
echo "=============================================="
echo ""

if [ -f "$OUTPUT_DIR/$APP_NAME" ]; then
    echo "Executable:"
    echo "  $OUTPUT_DIR/$APP_NAME"
    echo ""
    echo "Size:"
    du -sh "$OUTPUT_DIR/$APP_NAME"
    echo ""
    echo "Run with:"
    echo "  sudo $OUTPUT_DIR/$APP_NAME"
else
    echo "❌ Build failed - executable not found."
    exit 1
fi