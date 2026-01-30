#!/bin/bash
# setup-fix-cifs.sh
# Usage: sudo ./setup-fix-cifs.sh /mnt/path1 /mnt/path2

set -e

# --- New: Capture paths from command line arguments ---
MOUNT_PATHS="$@"

if [ -z "$MOUNT_PATHS" ]; then
    echo "❌ Error: No mount paths provided."
    echo "Usage: sudo $0 /mnt/remote/path1 /mnt/remote/path2"
    exit 1
fi

LOGFILE="/var/log/fix-cifs.log"

echo "🔧 Setting up CIFS auto-fix system for: $MOUNT_PATHS"

# === Create fix-cifs.sh script ===
cat <<'EOF' | sudo tee /usr/local/bin/fix-cifs.sh >/dev/null
#!/bin/bash
LOGFILE="/var/log/fix-cifs.log"

echo "=== [$(date)] CIFS fix script starting ===" | tee -a "$LOGFILE"

install_dependencies() {
    echo "[INFO] Installing dependencies..." | tee -a "$LOGFILE"
    for i in {1..10}; do
        if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            echo "[INFO] APT lock detected. Waiting 15s... ($i/10)" | tee -a "$LOGFILE"
            sleep 15
        else
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
}

load_cifs_module() {
    echo "[INFO] Loading CIFS kernel module..." | tee -a "$LOGFILE"
    modprobe cifs || echo "[WARN] Failed to load CIFS module" | tee -a "$LOGFILE"
}

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
}

mount_cifs_shares() {
    echo "[INFO] Mounting all CIFS shares..." | tee -a "$LOGFILE"
    mount -a -t cifs 2>>"$LOGFILE" || echo "[WARN] Some mounts failed" | tee -a "$LOGFILE"
}

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
After=network-online.target systemd-modules-load.service cloud-final.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-cifs.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# === Modified Docker dependency section ===
if systemctl list-unit-files | grep -q '^docker.service'; then
    echo "🐳 Adding Docker dependency on paths: $MOUNT_PATHS"
    sudo mkdir -p /etc/systemd/system/docker.service.d
    
    # We use a heredoc here but allow variable expansion for $MOUNT_PATHS
    cat <<EOF | sudo tee /etc/systemd/system/docker.service.d/require-mounts.conf > /dev/null
[Unit]
RequiresMountsFor=$MOUNT_PATHS
EOF
    sudo systemctl daemon-reload
else
    echo "⚠️  Docker service not found — skipping Docker dependency patch."
fi

sudo systemctl enable fix-cifs.service

echo "✅ CIFS auto-fix setup complete!"
echo "✅ Docker now depends on: $MOUNT_PATHS"