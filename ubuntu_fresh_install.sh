#!/bin/bash

# Detect the current user (not root)
CURRENT_USER=$(logname)

# Check if script is being run without sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    echo "Please try running it again with sudo:"
    echo "\nsudo $0 $*"
    exit 1
fi

# Ask user if they want to change the timezone to Asia/Taipei
read -p "Do you want to set the timezone to Asia/Taipei? (y/n): " response

if [ "$response" == "y" ] || [ "$response" == "Y" ]; then
  sudo timedatectl set-timezone Asia/Taipei
  echo "Timezone set to Asia/Taipei"
else
  echo "Skipping timezone change."
fi

# Download and execute the Docker installation script
wget -O install-docker.sh https://gitlab.com/bmcgonag/docker_installs/-/raw/main/install_docker_nproxyman.sh
sudo chmod +x install-docker.sh
sudo ./install-docker.sh

#fix docker-ce permission issue
sudo chmod 666 /var/run/docker.sock
sudo usermod -aG docker $USER

# Ask if they want to install Dockge and its services
read -p "Do you want to install Dockge? (y/n): " dockge_response
if [ "$dockge_response" == "y" ] || [ "$dockge_response" == "Y" ]; then
  # Download and execute the Dockge installation script
  wget -O install-dockge.sh https://github.com/justtest-ing/user-script/raw/refs/heads/main/install-dockge.sh
  sudo chmod +x install-dockge.sh
  sudo ./install-dockge.sh
  
  # Start the Docker Compose services for Dockge
  docker compose -f /mnt/appdata/dockge/compose.yaml up -d
fi

# Ask user if they want to mount an SMB share
read -p "Do you want to set up an SMB share mount? (y/n): " smb_response
if [ "$smb_response" == "y" ] || [ "$smb_response" == "Y" ]; then
  # Download and execute the user script to mount an SMB share
  wget -O ubuntu_mount_SMB_share.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/ubuntu_mount_SMB_share.sh
  sudo chmod +x ubuntu_mount_SMB_share.sh
  sudo ./ubuntu_mount_SMB_share.sh
else
  echo "Skipping SMB share setup."
fi

# Ask if they want to install zsh
read -p "Do you want to install zsh? (y/n): " zsh_response
if [ "$zsh_response" == "y" ] || [ "$zsh_response" == "Y" ]; then
  # Download and execute the zsh installation script
  wget -O install-zsh.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/install-zsh-sudo.sh
  sudo chmod +x install-zsh.sh
  sudo ./install-zsh-sudo.sh "$CURRENT_USER"
  echo "Zsh installed. You may want to reboot to switch shell."
fi

# Clean up downloaded scripts
sudo rm -f install-docker.sh >/dev/null 2>&1
sudo rm -f install-dockge.sh >/dev/null 2>&1
sudo rm -f ubuntu_mount_SMB_share.sh >/dev/null 2>&1
sudo rm -f install-zsh.sh >/dev/null 2>&1

echo "Script execution completed."
echo "If you see error with the script starting dockge, It is best to reboot and start dockge in /mnt/appdata/dockge/"
