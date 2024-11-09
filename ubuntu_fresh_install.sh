#!/bin/bash

# Set timezone to Asia/Taipei
sudo timedatectl set-timezone Asia/Taipei

# Download and execute the Docker installation script
wget -O install-docker.sh https://gitlab.com/bmcgonag/docker_installs/-/raw/main/install_docker_nproxyman.sh
sudo chmod +x install-docker.sh
sudo ./install-docker.sh

# Download and execute the Dockge installation script
wget -O install-dockge.sh https://github.com/justtest-ing/user-script/raw/refs/heads/main/install-dockge.sh
sudo chmod +x install-dockge.sh
sudo ./install-dockge.sh

# Download and execute the user script to mount an SMB share
wget https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/ubuntu_mount_SMB_share.sh
sudo chmod +x ubuntu_mount_SMB_share.sh
sudo ./ubuntu_mount_SMB_share.sh

# Clean up downloaded scripts
sudo rm install-docker.sh
sudo rm install-dockge.sh
sudo rm ubuntu_mount_SMB_share.sh

echo "Script execution completed."
echo "It is best to reboot and start dockge in /mnt/appdata/dockge/"
