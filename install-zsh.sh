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
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
            echo "Oh My Zsh installed successfully!"
            exit 0  # Exit with success after successful installation
        fi
        sleep 5
    done
    echo "Failed to install Oh My Zsh after multiple attempts."
    exit 1  # Exit with failure if all retries fail
}

install_ohmyzsh || { echo "Proceeding with the rest of the script..."; }

# Install ZSH plugins
echo "Installing ZSH plugins..."
mkdir -p ~/.oh-my-zsh/plugins

git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Set up custom .zhsrc if desired
echo "Would you like to set up a custom .zhsrc configuration? (y/n) "
read setup_config
if [[ $setup_config == "y" ]]; then
    curl -o ~/.zhsrc https://raw.githubusercontent.com/justtest-ing/user-script/refs/heads/main/install-zsh.zhsrc.example
fi

echo "ZSH installation completed!"
echo "You may need to log out and back in for changes to take effect."