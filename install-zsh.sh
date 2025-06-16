#!/bin/bash

# Ensure we have necessary tools
sudo apt-get update && sudo apt-get install -y zsh curl git

# Install ZSH
echo "Installing ZSH..."
sudo apt install zsh

# Set ZSH as default shell
echo "Setting ZSH as default shell..."
chsh -s $(which zsh)

# Install Oh My Zsh with retry logic
function install_ohmyzsh() {
    echo "Installing Oh My Zsh..."
    for i in {1..5}; do
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && break || sleep 5
    done
}

install_ohmyzsh

# Install ZSH plugins
echo "Installing ZSH plugins..."
mkdir -p ~/.oh-my-zsh/plugins

git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# Set up custom .zhsrc if desired
echo "Would you like to set up a custom .zhsrc configuration? (y/n) "
read setup_config
if [[ $setup_config == "y" ]]; then
    curl -o ~/.zhsrc https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/install-zsh.zhsrc.example
fi

echo "ZSH installation completed!"
echo "You may need to log out and back in for changes to take effect."