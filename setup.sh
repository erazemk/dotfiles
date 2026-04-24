#!/usr/bin/env bash

DOTFILES="$HOME/.config/dotfiles"

#
# Copy dotfiles
#

# Aerospace
echo "Setting up Aerospace dotfiles"
mkdir -p ~/.config/aerospace
ln -sf $DOTFILES/aerospace/* ~/.config/aerospace/

# AWS
echo "Setting up AWS dotfiles"
mkdir -p ~/.aws
ln -sf $DOTFILES/aws/* ~/.aws/

# Colima
echo "Setting up Colima dotfiles"
mkdir -p ~/.config/colima/_templates ~/Library/LaunchAgents
ln -sf $DOTFILES/colima/template.yml ~/.config/colima/_templates/default.yml
ln -sf $DOTFILES/launchctl/com.erazemk.colima.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.erazemk.colima.plist

# Fish
echo "Setting up Fish dotfiles"
mkdir -p ~/.config/fish†
ln -sf $DOTFILES/fish/* ~/.config/fish/
echo "SETUVAR --export fish_greeting:\x1d" >> ~/.config/fish/fish_variables

# Git
echo "Setting up Git dotfiles"
mkdir -p ~/.config/git
ln -sf $DOTFILES/git/* ~/.config/git/

# OpenCode
echo "Setting up OpenCode dotfiles"
mkdir -p ~/.config/opencode
ln -sf $DOTFILES/opencode/* ~/.config/opencode/
ln -sf $DOTFILES/agents/* ~/.config/opencode/

# VSCode
echo "Setting up VSCode dotfiles"
mkdir -p ~/Library/Application\ Support/Code/User/
ln -sf $DOTFILES/vscode/* ~/Library/Application\ Support/Code/User/

# Other
echo "Setting up other dotfiles"
mkdir -p ~/.local/bin

#
# Installation steps
#

# Homebrew
echo "Installing Homebrew"
sudo -v
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install awscli colima docker docker-buildx docker-compose docker-credential-helper fish gh git git-lfs go helix jq anomalyco/tap/opencode
brew install --cask aws-vpn-client bitwarden brave-browser ghostty granola handy lookaway obsidian pearcleaner slack visual-studio-code nikitabobko/tap/aerospace

# Switch to fish shell
echo "Switching to fish shell"
sudo chsh -s $(which fish) $(id -un)
sudo chsh -s $(which fish) root
