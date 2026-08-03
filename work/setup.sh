#!/usr/bin/env bash

DOTFILES_HOME="$HOME/.config/dotfiles/work"

# AWS
mkdir -p ~/.aws
ln -sf $DOTFILES_HOME/aws/* ~/.aws/

# Binaries
mkdir -p ~/.local/bin
ln -sf $DOTFILES_HOME/bin/* ~/.local/bin/

# Colima
mkdir -p ~/.config/colima/_templates ~/Library/LaunchAgents
ln -sf $DOTFILES_HOME/colima/template.yml ~/.config/colima/_templates/default.yml
ln -sf $DOTFILES_HOME/launchctl/com.erazemk.colima.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.erazemk.colima.plist

# Fish shell
mkdir -p ~/.config/fish
ln -sf $DOTFILES_HOME/fish/* ~/.config/fish/

# Ghostty
mkdir -p ~/.config/ghostty
ln -sf $DOTFILES_HOME/ghostty/* ~/.config/ghostty/

# Git
mkdir -p ~/.config/git
ln -sf $DOTFILES_HOME/git/* ~/.config/git/

# Global environment variables
mkdir -p ~/Library/LaunchAgents
ln -sf $DOTFILES_HOME/launchctl/com.erazemk.env.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.erazemk.env.plist

# OpenCode
mkdir -p ~/.config/opencode
ln -sf $DOTFILES_HOME/opencode/* ~/.config/opencode/

# VSCode
mkdir -p "~/Library/Application Support/Code/User/"
ln -sf $DOTFILES_HOME/vscode/* "~/Library/Application Support/Code/User/"

# ZSH shell
ln -sf $DOTFILES_HOME/zsh/zprofile ~/.zprofile
ln -sf $DOTFILES_HOME/zsh/zshrc ~/.zshrc

# Install homebrew
if ! command -v brew &> /dev/null; then
    sudo -v
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install homebrew packages
brew install $(cat $DOTFILES_HOME/homebrew/formulae | tr '\n' ' ')
brew install --cask $(cat $DOTFILES_HOME/homebrew/casks | tr '\n' ' ')
