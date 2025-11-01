#!/bin/bash
# Detect the current user (not root)
CURRENT_USER=${SUDO_USER:-${LOGNAME:-$(whoami)}}

# Check if script is being run without sudo
if [ "$EUID" -ne 0 ]; then
    echo ""
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

# Function to display menu
function show_menu {
    echo "
Menu:
1.  Set Timezone
2.  Install Docker
3.  Install Dockge
4.  Mount SMB Share
5.  Fix Reboot Mount
6.  Install ZSH
7.  Install tdu (top disk usage)
8.  Apply Log Size Reducer
a.  Run ALL installations
b.  Run custom selections (e.g., 1,2,5)
c.  Cleanup temporary files
0.  Exit
"
}

# Function for setting timezone
function set_timezone {
    echo ""
    echo "==========================================="
    echo "           🕒 Set System Timezone"
    echo "==========================================="
    echo ""
    echo "Popular timezones:"
    echo "  1) UTC"
    echo "  2) Asia/Taipei"
    echo "  3) Asia/Singapore"
    echo "  4) Asia/Tokyo"
    echo "  5) Europe/London"
    echo "  6) America/New_York"
    echo ""
    echo "If you’re unsure, see the full list here:"
    echo "https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
    echo ""

    read -p "Enter the timezone name (e.g., Asia/Taipei): " timezone_input

    if [ -z "$timezone_input" ]; then
        echo ""
        echo "No input provided. Skipping timezone change."
        return
    fi

    # Validate timezone
    if timedatectl list-timezones | grep -qx "$timezone_input"; then
        timedatectl set-timezone "$timezone_input"
        echo ""
        echo "✅ Timezone successfully set to: $timezone_input"
    else
        echo ""
        echo "❌ Invalid timezone: $timezone_input"
        echo "Run 'timedatectl list-timezones' to see all valid options."
    fi
}

# Function for installing Docker
function install_docker {
    wget -O install-docker.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/install_docker_nproxyman.sh
    sudo chmod +x install-docker.sh
    sudo ./install-docker.sh

    # Check if Docker is installed and running before fixing permission
    if command -v docker >/dev/null 2>&1 && sudo systemctl is-active --quiet docker; then
        echo ""
        echo "Fixing docker permission."
        sudo chmod 666 /var/run/docker.sock
        sudo usermod -aG docker "$CURRENT_USER"
    else
        echo ""
        echo "Docker not found. Skipping applying permission fix."
    fi

    echo ""
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

#

# Function for mounting SMB share
function mount_smb {
    read -p "Do you want to set up an SMB share mount? (y/n): " smb_response
    if [ "$smb_response" == "y" ] || [ "$smb_response" == "Y" ]; then
        wget -O ubuntu_mount_SMB_share.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/ubuntu_mount_SMB_share.sh
        sudo chmod +x ubuntu_mount_SMB_share.sh
        sudo ./ubuntu_mount_SMB_share.sh
    else
        echo ""
        echo "Skipping SMB share setup."
    fi
}

# Function to install and schedule reboot mount fix
function fix_reboot_mount {
    read -p "Do you want to set up reboot mount fix script? (y/n): " smb_response
    if [ "$smb_response" == "y" ] || [ "$smb_response" == "Y" ]; then
        echo ""
        echo "==========================================="
        echo "     🔧 Install Reboot Mount Fix Script"
        echo "==========================================="
        echo ""

        SCRIPT_URL="https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/fix-reboot-mount.sh"
        TARGET_DIR="/home/$CURRENT_USER/.script"
        TARGET_FILE="$TARGET_DIR/fix-reboot-mount.sh"

        echo "➡️  Creating directory: $TARGET_DIR"
        mkdir -p "$TARGET_DIR"

        echo "➡️  Downloading script from GitHub..."
        wget -q -O "$TARGET_FILE" "$SCRIPT_URL"

        if [ ! -s "$TARGET_FILE" ]; then
            echo "❌ Failed to download script. Check your network connection."
            return 1
        fi

        echo "➡️  Setting executable permission..."
        chmod +x "$TARGET_FILE"

        echo "➡️  Adding crontab entry to run script at reboot..."
        # Remove any previous duplicate entries first
        crontab -u "$CURRENT_USER" -l 2>/dev/null | grep -v "fix-reboot-mount.sh" | crontab -u "$CURRENT_USER" -
        # Add new entry
        (crontab -u "$CURRENT_USER" -l 2>/dev/null; echo "@reboot $TARGET_FILE") | crontab -u "$CURRENT_USER" -

        echo ""
        echo "✅ Reboot mount fix installed successfully!"
        echo "   Script location: $TARGET_FILE"
        echo "   Crontab entry added for user: $CURRENT_USER"
    else
        echo ""
        echo "Skipping reboot mount fix script setup."
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
    read -p "Do you want to install tdu (top disk usage)? (y/n): " tdu_response
    if [ "$tdu_response" == "y" ] || [ "$tdu_response" == "Y" ]; then
        wget -O install-tdu.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/install-tdu.sh
        sudo chmod +x install-tdu.sh
        sudo ./install-tdu.sh
        echo ""
        echo "tdu installed successfully"
    fi
}

# Function for applying log size reducer
function log_size_fix {
    read -p "Do you want to apply log size reduction fix? (y/n): " logreduce_response
    if [ "$logreduce_response" == "y" ] || [ "$logreduce_response" == "Y" ]; then
        wget -O log-size-reducer.sh https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/log-size-reducer.sh
        sudo chmod +x log-size-reducer.sh
        sudo ./log-size-reducer.sh
        echo ""
        echo "Log size reduction applied successfully"
    fi
}

# Function for custom selection
function run_custom_selection {
    echo ""
    read -p "Enter the task numbers separated by commas (e.g., 1,3,5): " selection
    IFS=',' read -ra TASKS <<< "$selection"

    for task in "${TASKS[@]}"; do
        case ${task// /} in
            1) set_timezone ;;
            2) install_docker ;;
            3) install_dockge ;;
            4) mount_smb ;;
            5) fix_reboot_mount ;;
            6) install_zsh ;;
            7) install_tdu ;;
            8) log_size_fix ;;
            *)
                echo "⚠️  Invalid option: $task"
            ;;
        esac
    done
    echo ""
    echo "✅ Selected tasks completed."
}

# Function to clean up downloaded scripts and temp files
function cleanup_files {
    echo ""
    echo "==========================================="
    echo "           🧹 Cleanup Utility"
    echo "==========================================="
    echo ""

    DOWNLOADS=("install-docker.sh" "install-dockge.sh" "ubuntu_mount_SMB_share.sh" \
               "install-zsh-sudo.sh" "install-tdu.sh" "log-size-reducer.sh")

    echo "The following temporary files (if any) will be removed:"
    for file in "${DOWNLOADS[@]}"; do
        echo "  - $file"
    done

    echo ""
    read -p "Proceed with cleanup? (y/n): " confirm_cleanup
    if [[ "$confirm_cleanup" =~ ^[Yy]$ ]]; then
        echo ""
        echo "➡️  Removing temporary installer scripts..."
        for file in "${DOWNLOADS[@]}"; do
            [ -f "$file" ] && rm -f "$file"
        done

        echo ""
        echo "✅ Cleanup completed successfully!"
    else
        echo ""
        echo "❌ Cleanup cancelled."
    fi
}

# Main script execution
while true; do
    show_menu
    read -p "Please select an option (1-9) or press q to quit: " choice
    
    case $choice in
        1) set_timezone ;;
        2) install_docker ;;
        3) install_dockge ;;
        4) mount_smb ;;
        5) fix_reboot_mount ;;
        6) install_zsh ;;
        7) install_tdu ;;
        8) log_size_fix ;;
        a|A)
            echo "Running all installations..."
            set_timezone || true
            install_docker || true
            install_dockge || true
            mount_smb || true
            fix_reboot_mount || true
            install_zsh || true
            install_tdu || true
            log_size_fix || true
            echo "✅ All installations completed."
        ;;
        b|B)
            run_custom_selection
        ;;
        c|C)
            cleanup_files
        ;;
        0|q|Q)
            cleanup_files
            echo ""
            echo "👋 Exiting script. Goodbye!"
            exit 0
        ;;
        *)
            echo "Invalid option. Please try again."
        ;;
    esac

    # If user selects an option (other than ALL or Exit), we break the loop to exit
done

<<<<<<< HEAD
echo "Script execution completed."
=======
echo "Script execution completed."
>>>>>>> fab48dd76d4817f05f58e18623f24e16d433496d
