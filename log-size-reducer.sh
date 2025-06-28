#!/bin/bash

echo
echo "===== Reducing log size ====="

# Delete compressed and rotated log files
echo "[1/3] Cleaning /var/log/ compressed and rotated logs..."
cd /var/log/ || { echo "Failed to cd into /var/log"; exit 1; }
sudo rm -f *.gz *.1
echo "Done."

# Vacuum journal logs older than 7 days
echo "[2/3] Vacuuming journal logs older than 7 days..."
sudo journalctl --vacuum-time=7d
echo "Done."

# Set Docker log rotation options
echo "[3/3] Setting Docker log rotation config..."
DOCKER_CONFIG="/etc/docker/daemon.json"
sudo mkdir -p /etc/docker

sudo bash -c "cat > $DOCKER_CONFIG" <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

echo "Docker daemon.json updated."

# Restart Docker to apply changes
echo "Restarting Docker..."
sudo systemctl restart docker
echo "Docker restarted."

echo "===== Log reduction completed ====="