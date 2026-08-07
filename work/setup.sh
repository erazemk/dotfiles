#!/usr/bin/env bash

DOTFILES_HOME="$HOME/.config/dotfiles/work"

source ../common/setup.sh

# AWS
mkdir -p ~/.aws
ln -sf $DOTFILES_HOME/aws/* ~/.aws/

# Colima
mkdir -p ~/.config/colima/_templates ~/Library/LaunchAgents
ln -sf $DOTFILES_HOME/colima/template.yaml ~/.config/colima/_templates/default.yaml
ln -sf $DOTFILES_HOME/launchctl/com.erazemk.colima.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.erazemk.colima.plist

# OpenCode
ln -sf $DOTFILES_HOME/opencode/agents/* ~/.config/opencode/agents/
ln -sf $DOTFILES_HOME/opencode/commands/* ~/.config/opencode/commands/
ln -sf $DOTFILES_HOME/opencode/skills/* ~/.config/opencode/skills/

# VSCode
mkdir -p "~/Library/Application Support/Code/User/"
ln -sf $DOTFILES_HOME/vscode/* "~/Library/Application Support/Code/User/"
