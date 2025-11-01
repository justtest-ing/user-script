#!/bin/bash
# =====================================================================
# fix-cifs-modules.sh
# Automatically ensures linux-modules-extra-$(uname -r) is installed
# to prevent CIFS mount errors ("iocharset utf8 not found") on boot.
# Works well for Proxmox Cloud-Init Ubuntu VMs.
# =====================================================================

set -e

echo "🔧 Setting up automatic CIFS module installer..."

# Ensure the directory exists
sudo mkdir -p /etc/apt/apt.conf.d/

# Create the apt hook
sudo tee /etc/apt/apt.conf.d/99-fix-cifs-modules > /dev/null <<'EOF'
DPkg::Post-Invoke {
  "KERNEL=$(uname -r); \
   if ! dpkg -l | grep -q linux-modules-extra-$KERNEL; then \
     echo '[CIFS FIX] Installing linux-modules-extra for kernel $KERNEL'; \
     apt install -y linux-modules-extra-$KERNEL || true; \
   else \
     echo '[CIFS FIX] linux-modules-extra-$KERNEL already installed'; \
   fi";
};
EOF

# Optional: install once now for the current kernel
echo "📦 Installing linux-modules-extra for current kernel..."
sudo apt update -qq
sudo apt install -y linux-modules-extra-$(uname -r)

echo "✅ CIFS module fix installed successfully."
echo "This will automatically install matching linux-modules-extra packages on future kernel updates."