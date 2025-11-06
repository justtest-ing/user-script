#!/bin/bash
# setup-fix-cifs.sh
# Automate CIFS reliability fix after kernel updates + Docker dependency setup
# solves CIFS: VFS: CIFS mount error: iocharset utf8 not found after kernel update & reboot

set -euo pipefail

echo "🔧 Setting up CIFS auto-fix system..."

# === Create CIFS fix script ===
echo "📄 Creating /usr/local/bin/fix-cifs.sh..."
cat <<'EOF' | sudo tee /usr/local/bin/fix-cifs.sh > /dev/null
#!/bin/bash
# fix-cifs.sh
# Ensures CIFS mounts work after kernel update or reboot

set -euo pipefail
LOGFILE="/var/log/fix-cifs.log"

echo "=== [$(date)] CIFS fix script starting ===" | tee -a "$LOGFILE"

# Wait a bit for network and apt
sleep 5

echo "[INFO] Installing dependencies..." | tee -a "$LOGFILE"
apt-get update -qq || true
apt-get install -y -qq cifs-utils linux-modules-extra-$(uname -r) >>"$LOGFILE" 2>&1 || true

echo "[INFO] Loading CIFS kernel module..." | tee -a "$LOGFILE"
modprobe cifs || echo "[WARN] Could not load CIFS module" | tee -a "$LOGFILE"

echo "[INFO] Waiting for network-online..." | tee -a "$LOGFILE"
for i in {1..30}; do
    ping -c1 -W1 8.8.8.8 >/dev/null 2>&1 && break
    sleep 2
done

echo "[INFO] Mounting all CIFS shares..." | tee -a "$LOGFILE"
mount -a || echo "[WARN] Some mounts failed" | tee -a "$LOGFILE"

echo "=== [$(date)] CIFS fix script completed ===" | tee -a "$LOGFILE"
EOF

sudo chmod +x /usr/local/bin/fix-cifs.sh

# === Create systemd service ===
echo "⚙️  Creating /etc/systemd/system/fix-cifs.service..."
cat <<'EOF' | sudo tee /etc/systemd/system/fix-cifs.service > /dev/null
[Unit]
Description=Fix CIFS mounts after reboot or kernel update
After=network-online.target systemd-modules-load.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-cifs.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable fix-cifs.service

# === Optional Enhancement: Add Docker dependency ===
if systemctl list-unit-files | grep -q '^docker.service'; then
    echo "🐳 Adding Docker dependency on fix-cifs.service..."
    sudo mkdir -p /etc/systemd/system/docker.service.d
    cat <<'EOF' | sudo tee /etc/systemd/system/docker.service.d/depends-on-fix-cifs.conf > /dev/null
[Unit]
After=fix-cifs.service
Requires=fix-cifs.service
EOF
    sudo systemctl daemon-reload
else
    echo "⚠️  Docker service not found — skipping Docker dependency patch."
fi

# === Start immediately ===
echo "🚀 Running fix-cifs.service now..."
sudo systemctl start fix-cifs.service

echo "✅ Setup complete!"
echo "CIFS mounts will now be auto-repaired after reboot or kernel update."
echo "Log file: /var/log/fix-cifs.log"
