#!/bin/bash
# Download the tdu file
wget "https://github.com/josephpaul0/tdu/releases/download/v1.36/tdu_linux_v1.36.tar.xz"

# Decompress and extract
unxz tdu_linux_v1.36.tar.xz
tar -xvf tdu_linux_v1.36.tar
rm tdu_linux_v1.36.tar

# Determine the CPU architecture
CPU_ARCH=$(uname -m)
CMD_PATH="$(pwd)/tdu_linux_v1.36"

if [ "$CPU_ARCH" == "x86_64" ]; then
    echo ""
    echo "You are using x86_64 (AMD64/Intel 64) architecture."
    echo "Run tdu with:"
    echo -e "\e[33msudo ${CMD_PATH}/tdu.linux.amd64 <directory_path>\e[0m"
elif [ "$CPU_ARCH" == "i386" ] || [ "$CPU_ARCH" == "i686" ]; then
    echo ""
    echo "You are using i386 (32-bit) architecture."
    echo "Run tdu with:"
    echo -e "\e[33msudo ${CMD_PATH}/tdu.linux.386 <directory_path>\e[0m"
elif [ "$CPU_ARCH" == "armv6l" ]; then
    echo ""
    echo "You are using armv6l (Raspberry Pi 1/Zero) architecture."
    echo "Run tdu with:"
    echo -e "\e[33msudo ${CMD_PATH}/tdu.linux.armv6.rpi <directory_path>\e[0m"
else
    echo ""
    echo "Unsupported architecture detected: $CPU_ARCH"
fi

# Note: Replace <directory_path> with the actual directory you want to process.