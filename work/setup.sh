#!/usr/bin/env bash

DOTFILES_HOME="$HOME/.config/dotfiles/work"
COMMON_DOTFILES_HOME="$HOME/.config/dotfiles/common"

# AWS
mkdir -p ~/.aws
ln -sf $DOTFILES_HOME/aws/* ~/.aws/

# Colima
mkdir -p ~/.config/colima/_templates ~/Library/LaunchAgents
ln -sf $DOTFILES_HOME/colima/template.yaml ~/.config/colima/_templates/default.yaml
ln -sf $DOTFILES_HOME/launchctl/com.erazemk.colima.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.erazemk.colima.plist

# Fish shell
mkdir -p ~/.config/fish/conf.d
ln -sf $DOTFILES_HOME/fish/* ~/.config/fish/
ln -sf $COMMON_DOTFILES_HOME/fish/conf.d/* ~/.config/fish/conf.d/

# Ghostty
mkdir -p ~/.config/ghostty
ln -sf $COMMON_DOTFILES_HOME/ghostty/* ~/.config/ghostty/

# Git
mkdir -p ~/.config/git
ln -sf $DOTFILES_HOME/git/* ~/.config/git/

# Global environment variables
mkdir -p ~/Library/LaunchAgents
ln -sf $DOTFILES_HOME/launchctl/com.erazemk.env.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.erazemk.env.plist

# OpenCode
mkdir -p ~/.config/opencode/agents ~/.config/opencode/commands ~/.config/opencode/skills
ln -sf $DOTFILES_HOME/opencode/agents/* ~/.config/opencode/agents/
ln -sf $DOTFILES_HOME/opencode/commands/* ~/.config/opencode/commands/
ln -sf $DOTFILES_HOME/opencode/skills/* ~/.config/opencode/skills/
ln -sf $DOTFILES_HOME/opencode/AGENTS.md ~/.config/opencode/AGENTS.md
ln -sf $DOTFILES_HOME/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc
ln -sf $COMMON_DOTFILES_HOME/opencode/agents/* ~/.config/opencode/agents/
ln -sf $COMMON_DOTFILES_HOME/opencode/commands/* ~/.config/opencode/commands/
ln -sf $COMMON_DOTFILES_HOME/opencode/skills/* ~/.config/opencode/skills/
ln -sf $COMMON_DOTFILES_HOME/opencode/tui.jsonc ~/.config/opencode/tui.jsonc

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
