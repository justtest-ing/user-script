#!/bin/bash

# Detect the current user (not root)
CURRENT_USER=$(logname)

# Check if script is being run without sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

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

# Function for setting timezone
function set_timezone {
    read -p "Do you want to set the timezone to Asia/Taipei? (y/n): " response
    if [ "$response" == "y" ] || [ "$response" == "Y" ]; then
        sudo timedatectl set-timezone Asia/Taipei
        echo "Timezone set to Asia/Taipei"
    else
        echo "Skipping timezone change."
    fi
}

# Function for installing Docker
function install_docker {
    wget -O install-docker.sh https://gitlab.com/bmcgonag/docker_installs/-/raw/main/install_docker_nproxyman.sh
    sudo chmod +x install-docker.sh
    sudo ./install-docker.sh
    echo "Docker installed successfully"
}

# Function for installing Dockge
function install_dockge {
    read -p "Do you want to install Dockge? (y/n): " dockge_response
    if [ "$dockge_response" == "y" ] || [ "$dockge_response" == "Y" ]; then
        wget -O install-dockge.sh https://github.com/justtest-ing/user-script/raw/refs/heads/main/install-dockge.sh
        sudo chmod +x install-dockge.sh
        sudo ./install-dockge.sh
        docker compose -f /mnt/appdata/dockge/compose.yaml up -d
    fi
}

# Function for mounting SMB share
function mount_smb {
    read -p "Do you want to set up an SMB share mount? (y/n): " smb_response
    if [ "$smb_response" == "y" ] || [ "$smb_response" == "Y" ]; then
        wget -O ubuntu_mount_SMB_share.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/ubuntu_mount_SMB_share.sh
        sudo chmod +x ubuntu_mount_SMB_share.sh
        sudo ./ubuntu_mount_SMB_share.sh
    else
        echo "Skipping SMB share setup."
    fi
}

# Function for installing ZSH
function install_zsh {
    read -p "Do you want to install zsh? (y/n): " zsh_response
    if [ "$zsh_response" == "y" ] || [ "$zsh_response" == "Y" ]; then
        wget -O install-zsh-sudo.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/install-zsh-sudo.sh
        sudo chmod +x install-zsh-sudo.sh
        sudo ./install-zsh-sudo.sh "$CURRENT_USER"
    fi
}

# Function for installing tdu
function install_tdu {
    read -p "Do you want to install zsh? (y/n): " tdu_response
    if [ "$tdu_response" == "y" ] || [ "$tdu_response" == "Y" ]; then
        wget -O install-tdu.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/install-tdu.sh
        sudo chmod +x install-tdu.sh
        sudo ./install-tdu.sh
        echo "tdu installed successfully"
    fi
}

# apply log size reduer
function log_size_fix {
    read -p "Do you want to install zsh? (y/n): " logreduce_response
    if [ "$logreduce_response" == "y" ] || [ "$logreduce_response" == "Y" ]; then
        wget -O log-size-reducer.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/log-size-reducer.sh
        sudo chmod +x log-size-reducer.sh
        sudo ./log-size-reducer.sh
        echo "log-size-fix successfully"
    fi
}

# Main script execution
while true; do
    show_menu
    read -p "Please select an option (1-7) or press q to quit: " choice
    
    case $choice in
        1)
            set_timezone && break
        ;;
        
        2)
            install_docker && break
        ;;
        
        3)
            install_dockge && break
        ;;
        
        4)
            mount_smb && break
        ;;
        
        5)
            install_zsh && break
        ;;
        
        6)
            # Run ALL installations
            echo "Running all installations..."
            
            set_timezone || true
            install_docker || true
            install_dockge || true
            mount_smb || true
            install_zsh || true
            
            echo "All installations completed."
            break
        ;;
        
        7)
            exit 0
        ;;
        
        q|Q)
            exit 0
        ;;
        
        *)
            echo "Invalid option. Please try again."
            continue
        ;;
    esac
    
    # If user selects an option (other than ALL or Exit), we break the loop to exit
done

# Clean up downloaded scripts
sudo rm -f install-docker.sh install-dockge.sh ubuntu_mount_SMB_share.sh install-zsh-sudo.sh install-tdu.sh >/dev/null 2>&1

echo "Script execution completed."