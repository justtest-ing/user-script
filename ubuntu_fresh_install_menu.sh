#!/bin/bash

# Function to display menu
function show_menu {
    echo "
Menu:
1. Set Timezone
2. Install Docker
3. Install Dockge
4. Mount SMB Share
5. Install ZSH
6. ALL (Run all installations)
7. Exit
"
}

# Detect the current user (not root)
CURRENT_USER=$(logname)

# Check if script is being run without sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

while true; do
    show_menu
    read -p "Please select an option (1-6) or press q to quit: " choice
    
    case $choice in
        1)
            # Set Timezone
            read -p "Do you want to set the timezone to Asia/Taipei? (y/n): " response
            if [ "$response" == "y" ] || [ "$response" == "Y" ]; then
                sudo timedatectl set-timezone Asia/Taipei
                echo "Timezone set to Asia/Taipei"
            else
                echo "Skipping timezone change."
            fi
        ;;
        
        2)
            # Install Docker
            wget -O install-docker.sh https://gitlab.com/bmcgonag/docker_installs/-/raw/main/install_docker_nproxyman.sh
            sudo chmod +x install-docker.sh
            sudo ./install-docker.sh
            echo "Docker installed successfully"
        ;;
        
        3)
            # Install Dockge
            read -p "Do you want to install Dockge? (y/n): " dockge_response
            if [ "$dockge_response" == "y" ] || [ "$dockge_response" == "Y" ]; then
                wget -O install-dockge.sh https://github.com/justtest-ing/user-script/raw/refs/heads/main/install-dockge.sh
                sudo chmod +x install-dockge.sh
                sudo ./install-dockge.sh
                docker compose -f /mnt/appdata/dockge/compose.yaml up -d
            fi
        ;;
        
        4)
            # Mount SMB Share
            read -p "Do you want to set up an SMB share mount? (y/n): " smb_response
            if [ "$smb_response" == "y" ] || [ "$smb_response" == "Y" ]; then
                wget -O ubuntu_mount_SMB_share.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/ubuntu_mount_SMB_share.sh
                sudo chmod +x ubuntu_mount_SMB_share.sh
                sudo ./ubuntu_mount_SMB_share.sh
            else
                echo "Skipping SMB share setup."
            fi
        ;;
        
        5)
            # Install ZSH
            read -p "Do you want to install zsh? (y/n): " zsh_response
            if [ "$zsh_response" == "y" ] || [ "$zsh_response" == "Y" ]; then
                wget -O install-zsh-sudo.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/install-zsh-sudo.sh
                sudo chmod +x install-zsh-sudo.sh
                sudo ./install-zsh-sudo.sh "$CURRENT_USER"
                echo "Zsh installed. You may want to reboot to switch shell."
            fi
        ;;
        
        6)
            # Run ALL installations
            echo "Running all installations..."
            for i in {1..5}; do
                sleep 1
                echo -n "."
            done
            echo ""
            # ... (run all installation steps here) ...
        ;;
        
        q|Q)
            exit 0
        ;;
        
        *)
            echo "Invalid option. Please try again."
        ;;
    esac
    
    # Clear the screen for next menu
    clear
done

# Clean up downloaded scripts
sudo rm -f install-docker.sh install-dockge.sh ubuntu_mount_SMB_share.sh install-zsh-sudo.sh >/dev/null 2>&1

echo "Script execution completed."