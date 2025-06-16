#!/bin/bash

set -e

# Detect target user
if [ "$EUID" -eq 0 ]; then
    if [ -n "$SUDO_USER" ]; then
        USERNAME="$SUDO_USER"
    else
        echo "Script is running as root but no non-root user was detected. Please run as sudo from a regular user account."
        exit 1
    fi
else
    USERNAME="$USER"
fi

USER_HOME=$(eval echo "~$USERNAME")

echo "Running setup for user: $USERNAME"
echo "User home: $USER_HOME"

# Install Zsh
echo "Installing Zsh..."
apt update && apt install -y zsh curl git

# Set default shell for the user
echo "Setting Zsh as default shell for $USERNAME..."
chsh -s $(which zsh) "$USERNAME"

# Install Oh My Zsh (as the user)
echo "Installing Oh My Zsh..."
sudo -u "$USERNAME" sh -c '
    export RUNZSH=no
    export CHSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
'

# Define ZSH_CUSTOM and plugin paths
ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"

# Clone plugins (as the user)
echo "Installing zsh-autosuggestions..."
sudo -u "$USERNAME" git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

echo "Installing zsh-syntax-highlighting..."
sudo -u "$USERNAME" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# Modify .zshrc (as the user)
echo "Configuring .zshrc for $USERNAME..."
sudo -u "$USERNAME" sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="jonathan"/' "$USER_HOME/.zshrc" || true
sudo -u "$USERNAME" sed -i '/^plugins=/c\plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' "$USER_HOME/.zshrc" || \
echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$USER_HOME/.zshrc"

# Ensure ownership is correct
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.oh-my-zsh"
chown "$USERNAME:$USERNAME" "$USER_HOME/.zshrc"

echo "✅ Installation complete for user '$USERNAME'. run 'zsh' or re-login to start using Zsh."
