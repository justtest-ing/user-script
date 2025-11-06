#!/bin/bash
# setup-fix-cifs.sh
# Automate CIFS reliability fix after kernel updates + Docker dependency setup
# solves CIFS: VFS: CIFS mount error: iocharset utf8 not found after kernel update & reboot
# Log file: /var/log/fix-cifs.log

set -e

LOGFILE="/var/log/fix-cifs.log"

echo "🔧 Setting up automatic CIFS module installer..."

# === Create fix-cifs.sh script ===
cat <<'EOF' | sudo tee /usr/local/bin/fix-cifs.sh >/dev/null
#!/bin/bash
LOGFILE="/var/log/fix-cifs.log"

echo "=== [$(date)] CIFS fix script starting ===" | tee -a "$LOGFILE"

# === Retry-safe APT installer ===
install_dependencies() {
    echo "[INFO] Installing dependencies..." | tee -a "$LOGFILE"

    for i in {1..10}; do
        if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            echo "[INFO] APT lock detected. Waiting 15s... ($i/10)" | tee -a "$LOGFILE"
            sleep 15
        else
            # Check if packages already installed
            if ! dpkg -s cifs-utils >/dev/null 2>&1; then
                apt-get update -qq >>"$LOGFILE" 2>&1 || true
                apt-get install -y -qq cifs-utils >>"$LOGFILE" 2>&1 || true
            fi

            KERNEL_PKG="linux-modules-extra-$(uname -r)"
            if ! dpkg -s "$KERNEL_PKG" >/dev/null 2>&1; then
                apt-get install -y -qq "$KERNEL_PKG" >>"$LOGFILE" 2>&1 || true
            fi

            return
        fi
    done

    echo "[WARN] Could not acquire APT lock after multiple attempts." | tee -a "$LOGFILE"
}

# === Load CIFS kernel module ===
load_cifs_module() {
    echo "[INFO] Loading CIFS kernel module..." | tee -a "$LOGFILE"
    modprobe cifs || echo "[WARN] Failed to load CIFS module" | tee -a "$LOGFILE"
}

# === Wait for network-online.target ===
wait_for_network() {
    echo "[INFO] Waiting for network-online..." | tee -a "$LOGFILE"
    systemctl is-active --quiet network-online.target || \
        systemctl start network-online.target 2>/dev/null
    for i in {1..30}; do
        if ping -c1 8.8.8.8 >/dev/null 2>&1; then
            return
        fi
        sleep 2
    done
    echo "[WARN] Network still not ready after 60s." | tee -a "$LOGFILE"
}

# === Mount all CIFS shares ===
mount_cifs_shares() {
    echo "[INFO] Mounting all CIFS shares..." | tee -a "$LOGFILE"
    mount -a -t cifs 2>>"$LOGFILE" || echo "[WARN] Some mounts failed" | tee -a "$LOGFILE"
}

# === Main sequence ===
install_dependencies
load_cifs_module
wait_for_network
mount_cifs_shares

echo "=== [$(date)] CIFS fix script completed ===" | tee -a "$LOGFILE"
EOF

sudo chmod +x /usr/local/bin/fix-cifs.sh

# === Create systemd service ===
cat <<'EOF' | sudo tee /etc/systemd/system/fix-cifs.service >/dev/null
[Unit]
Description=Fix CIFS mounts after reboot or kernel update
After=network-online.target systemd-modules-load.service apt-daily.service apt-daily-upgrade.service
Wants=network-online.target apt-daily.service apt-daily-upgrade.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-cifs.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# === Enable the service ===
sudo systemctl daemon-reload
sudo systemctl enable fix-cifs.service

echo "✅ CIFS auto-fix setup complete!"
echo "🔍 Logs will be written to: $LOGFILE"
