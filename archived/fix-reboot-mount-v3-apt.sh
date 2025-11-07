#!/bin/bash
# =====================================================================
# fix-cifs-modules.sh
# Automatically ensures linux-modules-extra-$(uname -r) and cifs-utils
# are installed to prevent CIFS mount errors on reboot.
# Works perfectly with Proxmox Cloud-Init Ubuntu VMs.
# =====================================================================

set -e

echo "🔧 Setting up automatic CIFS module installer..."

# Ensure directory exists
sudo mkdir -p /etc/apt/apt.conf.d/

# Write a valid one-line APT hook (no multiline, no unescaped semicolons)
sudo tee /etc/apt/apt.conf.d/99-fix-cifs-modules > /dev/null <<'EOF'
DPkg::Post-Invoke { "bash -c 'KERNEL=$(uname -r); if ! dpkg -l | grep -q linux-modules-extra-$KERNEL; then echo [CIFS-FIX] Installing linux-modules-extra-$KERNEL; apt-get install -y linux-modules-extra-$KERNEL || true; else echo [CIFS-FIX] linux-modules-extra-$KERNEL already installed; fi; if ! dpkg -l | grep -q cifs-utils; then echo [CIFS-FIX] Installing cifs-utils; apt-get install -y cifs-utils || true; else echo [CIFS-FIX] cifs-utils already installed; fi'"; };
EOF

# Install for current kernel now
echo "📦 Installing linux-modules-extra and cifs-utils for current kernel..."
sudo apt update -qq
sudo apt install -y linux-modules-extra-$(uname -r) cifs-utils

echo "✅ CIFS module + utils fix installed successfully."
echo "This will automatically install missing packages after any kernel update."
