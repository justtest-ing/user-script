#!/bin/bash

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root"
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

# Download and execute the Dockge installation script
wget -O install-dockge.sh https://github.com/justtest-ing/user-script/raw/refs/heads/main/install-dockge.sh
sudo chmod +x install-dockge.sh
sudo ./install-dockge.sh

# Start the Docker Compose services using the absolute path to the compose file
docker compose -f /mnt/appdata/dockge/docker-compose.yaml up -d

# Download and execute the user script to mount an SMB share
wget -O https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/ubuntu_mount_SMB_share.sh
sudo chmod +x ubuntu_mount_SMB_share.sh
sudo ./ubuntu_mount_SMB_share.sh

# Clean up downloaded scripts
sudo rm install-docker.sh
sudo rm install-dockge.sh
sudo rm ubuntu_mount_SMB_share.sh

echo "Script execution completed."
echo "If you see error with the script starting dockge, It is best to reboot and start dockge in /mnt/appdata/dockge/"
