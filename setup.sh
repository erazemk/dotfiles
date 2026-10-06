#!/usr/bin/env bash

# Check if installing on DevRev-managed machine
DEVREV=0
if systemextensionsctl list | grep -q jumpcloud; then
    DEVREV=1
fi

if [[ ! -d /opt/homebrew ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# General packages
brew install -q --formulae curl fish gh git go gopls helix jq ketch node stow
brew install -q --casks ghostty pearcleaner rectangle zed

# DevRev-specific packages
if [[ $DEVREV -eq 1 ]]; then
    brew install -q --formulae awscli circleci colima docker docker-buildx docker-compose docker-credential-helper golangci-lint
    brew install -q --casks aws-vpn-client granola slack
fi

#
# Stow dotfiles
#

mkdir -p $HOME/.config/fish
stow -t $HOME -S fish

mkdir -p $HOME/.config/ghostty
stow -t $HOME -S ghostty

mkdir -p $HOME/.config/git
stow -t $HOME -S git

mkdir -p $HOME/Library/LaunchAgents
stow -t $HOME -S launchctl

mkdir -p $HOME/.pi/agent
stow -t $HOME -S pi

mkdir -p $HOME/.ssh
stow -t $HOME -S ssh

mkdir -p $HOME/.config/zed
stow -t $HOME -S zed

# Stow DevRev-specific dotfiles
if [[ $DEVREV -eq 1 ]]; then
    mkdir -p $HOME/.aws
    stow -t $HOME -S aws

    mkdir -p $HOME/.config/colima
    stow -t $HOME -S colima

    mkdir -p $HOME/.config/opencode
    stow -t $HOME -S opencode

    mkdir -p "$HOME/Library/Application\ Support/Code/User"
    stow -t $HOME -S vscode
fi

# Enable launch configurations
if ! launchctl print "gui/$(id -u)/com.erazemk.env" >/dev/null 2>&1; then
    launchctl bootstrap gui/$(id -u) $HOME/Library/LaunchAgents/com.erazemk.env.plist
fi

if [[ $DEVREV -eq 1 ]] && ! launchctl print "gui/$(id -u)/com.erazemk.colima" >/dev/null 2>&1; then
    launchctl bootstrap gui/$(id -u) $HOME/Library/LaunchAgents/com.erazemk.colima.plist
fi

echo "Done"
