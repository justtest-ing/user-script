#!/bin/bash
#make sure to mount all file systems in /etc/fstab (for some reason linux-modules-extra will break after reboot)

# Check if linux-modules-extra-$(uname -r) is installed (adding support for special characters)
if dpkg -s linux-modules-extra-$(uname -r) &> /dev/null; then
    echo "linux-modules-extra-$(uname -r) Is already installed."
        echo
else
    echo "linux-modules-extra-$(uname -r) Is not installed. Installing..."
    echo
    sudo apt-get update
    sudo apt-get install -y linux-modules-extra-$(uname -r)
fi
wait

# Attempt to mount all file systems in /etc/fstab
if ! sudo mount -a; then
    echo 
    echo "Error: Failed to mount one or more file systems. Stopping the script."
    exit 1
fi
echo 
echo "All file systems mounted successfully."