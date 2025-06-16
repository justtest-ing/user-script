#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Install Zsh
echo "Installing Zsh..."
sudo apt update && sudo apt install -y zsh curl git

# Set Zsh as default shell for the current user
echo "Setting Zsh as default shell..."
chsh -s $(which zsh)

# Install Oh My Zsh (non-interactive)
echo "Installing Oh My Zsh..."
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Define custom plugin directory
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Install plugins
echo "Installing zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

echo "Installing zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Update .zshrc
echo "Configuring .zshrc..."
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="jonathan"/' ~/.zshrc
sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc || \
echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> ~/.zshrc

# Final message
echo "Installation complete. Please restart your terminal or run 'zsh' to start using Zsh."