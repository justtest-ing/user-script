#!/bin/bash
# Fail2ban quick setup for SSH protection

set -e

echo "=== Fail2ban installer ==="

# Detect OS
if [ -f /etc/debian_version ]; then
    echo "Detected Debian/Ubuntu system"
    sudo apt update
    sudo apt install -y fail2ban
    LOG_PATH="/var/log/auth.log"
elif [ -f /etc/redhat-release ]; then
    echo "Detected CentOS/RHEL system"
    sudo yum install -y epel-release
    sudo yum install -y fail2ban
    LOG_PATH="/var/log/secure"
else
    echo "Unsupported OS. Please install Fail2ban manually."
    exit 1
fi

# Configure jail.local
JAIL_FILE="/etc/fail2ban/jail.local"
echo "Creating $JAIL_FILE"

sudo tee $JAIL_FILE > /dev/null <<EOF
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = $LOG_PATH
maxretry = 5
bantime  = 3600
EOF

# Enable and start fail2ban
echo "Enabling and starting fail2ban..."
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# Show status
echo "=== Fail2ban status ==="
sudo fail2ban-client status sshd

#To see active jails:
#sudo fail2ban-client status
#To see details of the SSH jail:
#sudo fail2ban-client status sshd
