#!/bin/bash

# Function to echo text in yellow color
echo_yellow() {
    echo -e "\e[93m$1\e[0m"
}

# Function to check if the ping was successful
check_ping() {
    if ping -c 4 "$1" &> /dev/null; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# Add two blank lines
echo

# Check if cifs-utils is installed
if command -v mount.cifs &> /dev/null; then
    echo_yellow "cifs-utils is already installed."
	echo
else
    echo_yellow "cifs-utils is not installed. Installing..."
    echo
    sudo apt-get update
    sudo apt-get install -y cifs-utils
fi

# Add two blank lines
echo

# Check if linux-modules-extra-$(uname -r) is installed (adding support for special characters)
if dpkg -s linux-modules-extra-$(uname -r) &> /dev/null; then
    echo_yellow "linux-modules-extra-$(uname -r) Is already installed."
	echo
else
    echo_yellow "linux-modules-extra-$(uname -r) Is not installed. Installing..."
    echo
    sudo apt-get update
    sudo apt-get install -y linux-modules-extra-$(uname -r)

    # Check if installation was successful
    if [ $? -eq 0 ]; then
        echo_yellow "linux-modules-extra installed successfully."
    else
        echo
        echo_yellow "Failed to install linux-modules-extra. Would you want to change the locale to Chinese? (y/n)"
        read -e -p "[y/n]: " answer  # Use read -e for echoing the input
        if [ "$answer" = "y" ]; then
            sudo localectl set-locale LANG=zh_TW.UTF-8
            echo_yellow "Locale changed to Chinese."
        else
            echo_yellow "Locale remains unchanged."
        fi
    fi

fi


# Add two blank lines
echo

# Prompt user for remote server IP
read -p "Enter the remote server IP: " server_ip

# Loop until a successful ping
while ! check_ping "$server_ip"; do
    echo_yellow "Ping to $server_ip failed. Please check the IP and try again."
    read -p "Enter the correct remote server IP: " server_ip
done

echo_yellow "Ping to $server_ip successful."

# Prompt user for share name on the remote server
read -p "Enter the share name on the remote server: " share_name

# Prompt user for username
read -p "Enter your username: " username

# Prompt user for password (will be stored securely)
read -s -p "Enter your password: " password
echo

# Store credentials in a hidden file in the home directory
credentials_file="$HOME/.smbcredentials"
echo "username=$username" > "$credentials_file"
echo "password=$password" >> "$credentials_file"

# Set appropriate permissions for the credentials file
chmod 600 "$credentials_file"

# Create the mount point in /remote/
mount_point="/mnt/remote/$share_name"
sudo mkdir -p "$mount_point"
echo_yellow "The remote share will be mounted at $mount_point"
echo

# Attempt to mount the share with iocharset=utf8
if sudo mount -t cifs "//${server_ip}/${share_name}" "$mount_point" -o "credentials=${credentials_file},iocharset=utf8"; then
    echo_yellow "SMB share has been mounted."
	echo

    # Ask user if they want to mount the share at boot
    read -p "Do you want to mount this share at boot? (y/n): " mount_at_boot
    if [ "$mount_at_boot" == "y" ]; then
        # Add entry to /etc/fstab for automatic mounting at boot
        echo "//${server_ip}/${share_name} ${mount_point} cifs credentials=${credentials_file},iocharset=utf8 0 0" | sudo tee -a /etc/fstab
        echo_yellow "SMB share has been configured for automatic mounting at boot."
    else
        echo_yellow "SMB share will not be mounted at boot."
		echo
    fi
else
    echo_yellow "Failed to mount SMB share. Please check your credentials and try again."
	echo
fi
