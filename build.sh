#!/bin/bash
# ============================================================
#  UDS Diagnostics - Raspberry Pi Build Script
#  Supports: Pi 3, Pi 4, Pi 5, Pi Zero 2 (32-bit & 64-bit OS)
#  Run this script DIRECTLY on your Raspberry Pi
# ============================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="uds_diagnostics"
OUTPUT_DIR="$PROJECT_DIR/dist"

echo ""
echo "=============================================="
echo "  UDS Diagnostics - Raspberry Pi Build Tool"
echo "=============================================="
echo ""

# --- Step 1: Check Python version ---
echo "[1/6] Checking Python..."
python3 --version || { echo "ERROR: python3 not found. Install it with: sudo apt install python3"; exit 1; }

# --- Step 2: Install pip if missing ---
echo "[2/6] Checking pip..."
python3 -m pip --version 2>/dev/null || {
    echo "pip not found, installing..."
    sudo apt-get install -y python3-pip
}

# --- Step 3: Install all required Python dependencies ---
echo "[3/6] Installing Python dependencies..."
pip3 install --break-system-packages \
    pyinstaller \
    RPi.GPIO \
    adafruit-circuitpython-ssd1306 \
    adafruit-blinka \
    Pillow \
    python-can \
    can-isotp \
    udsoncan \
    || pip3 install \
    pyinstaller \
    RPi.GPIO \
    adafruit-circuitpython-ssd1306 \
    adafruit-blinka \
    Pillow \
    python-can \
    can-isotp \
    udsoncan

echo ""
echo "[4/6] Setting up project structure..."
cd "$PROJECT_DIR"

# Make sure drivers folder has __init__.py
touch drivers/__init__.py

# --- Step 5: Run PyInstaller ---
echo "[5/6] Building executable with PyInstaller..."
echo "      This may take a few minutes..."
echo ""

pyinstaller \
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

# --- Step 6: Done ---
echo ""
echo "[6/6] Build complete!"
echo ""

if [ -f "$OUTPUT_DIR/$APP_NAME" ]; then
    echo "  ✅ Executable created:"
    echo "     $OUTPUT_DIR/$APP_NAME"
    echo ""
    echo "  File size: $(du -sh "$OUTPUT_DIR/$APP_NAME" | cut -f1)"
    echo ""
    echo "  To run:"
    echo "     sudo $OUTPUT_DIR/$APP_NAME"
    echo ""
    echo "  To make it auto-start on boot, see README.md"
else
    echo "  ❌ Build failed - executable not found in dist/"
    echo "     Check the build output above for errors."
    exit 1
fi
