#!/bin/bash
# ============================================================
# One-Command Installer for Raspberry Pi Zero W
# UDS Diagnostics Project
# ============================================================

set -e

APP_NAME="uds_diagnostics"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"
SERVICE_NAME="uds_diagnostics.service"
LOG_FILE="$PROJECT_DIR/install.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================="
echo " Installation started at $(date)"
echo "========================================="

# ---------------- ERROR HANDLER ----------------
error_exit() {
    echo "[ERROR] Failed at line $1"
    exit 1
}
trap 'error_exit $LINENO' ERR

# ---------------- SYSTEM UPDATE ----------------
echo "[INFO] Updating system..."
sudo apt update

# ---------------- INSTALL SYSTEM DEPENDENCIES ----------------
echo "[INFO] Installing system dependencies..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libjpeg-dev \
    zlib1g-dev \
    libfreetype6-dev \
    libopenjp2-7-dev \
    libtiff5-dev \
    libatlas-base-dev \
    python3-smbus \
    i2c-tools \
    can-utils

# ---------------- ENABLE I2C ----------------
echo "[INFO] Enabling I2C..."
sudo raspi-config nonint do_i2c 0 || true

# ---------------- CREATE VENV ----------------
echo "[INFO] Creating virtual environment..."
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# ---------------- INSTALL PYTHON DEPENDENCIES ----------------
echo "[INFO] Installing Python dependencies..."
pip install --upgrade pip

if [ -f "$PROJECT_DIR/requirements.txt" ]; then
    pip install -r "$PROJECT_DIR/requirements.txt"
else
    echo "[WARNING] requirements.txt not found"
fi

# ---------------- CREATE SERVICE FILE ----------------
echo "[INFO] Creating systemd service..."
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

sudo bash -c "cat > $SERVICE_PATH" <<EOL
[Unit]
Description=UDS Diagnostics Service
After=network.target

[Service]
ExecStart=$VENV_DIR/bin/python $PROJECT_DIR/main.py
WorkingDirectory=$PROJECT_DIR
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOL

# ---------------- ENABLE SERVICE ----------------
echo "[INFO] Enabling service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

# ---------------- FINAL ----------------
deactivate

echo "========================================="
echo " Installation completed successfully!"
echo " Service status:"
sudo systemctl status $SERVICE_NAME --no-pager

echo "========================================="
