#!/bin/bash
set -e

# Get target user from first argument, fallback to SUDO_USER, then logname
USERNAME="${1:-${SUDO_USER:-$(logname)}}"
USER_HOME=$(eval echo "~$USERNAME")

echo "Running setup for user: $USERNAME"
echo "User home: $USER_HOME"

# Install Zsh
echo "Installing Zsh..."
apt update && apt install -y zsh curl git

# Set default shell for the user
echo "Setting Zsh as default shell for $USERNAME..."
chsh -s $(which zsh) "$USERNAME"

# Install Oh My Zsh (as user)
echo "Installing Oh My Zsh..."
sudo -u "$USERNAME" sh -c '
    export RUNZSH=no
    export CHSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
'

# Define plugin path
ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"

# Clone plugins (as the user)
sudo -u "$USERNAME" git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
sudo -u "$USERNAME" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# Modify .zshrc (as the user)
sudo -u "$USERNAME" sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="jonathan"/' "$USER_HOME/.zshrc" || true
sudo -u "$USERNAME" sed -i '/^plugins=/c\plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' "$USER_HOME/.zshrc" || \
echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$USER_HOME/.zshrc"

# Fix permissions
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.oh-my-zsh"
chown "$USERNAME:$USERNAME" "$USER_HOME/.zshrc"

echo "✅ Zsh and Oh My Zsh installed for $USERNAME. Have them run 'zsh' or re-login to use it."