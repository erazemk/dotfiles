#!/usr/bin/env bash

mkdir -p ~/.config/fish
ln -s $(PWD)/git ~/.config/
ln -s $(PWD)/fish/config.fish ~/.config/fish/

# macOS-specific
if [[ $(uname) == "Darwin" ]]; then
    mkdir -p ~/.aws ~/Library/Application\ Support/Code/User/
    ln -s $(PWD)/aws/config ~/.aws/
    ln -s $(PWD)/aerospace ~/.config/
    ln -s $(PWD)/fish/conf.d ~/.config/fish/
    ln -s $(PWD)/vscode/settings.json $(PWD)/vscode/keybindings.json ~/Library/Application\ Support/Code/User/

    # Homebrew
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install -y awscli colima curl deno docker docker-buildx docker-compose fish gh git git-lfs go helix jq node openssh python ripgrep tree unzip uv xz zstd
    brew install -y --cask aerospace aws-vpn-client brave-browser codex ghostty lookaway monitorcontrol pearcleaner slack visual-studio-code

    # Switch to fish shell
    sudo chsh -s $(which fish) $(id -un)
    sudo chsh -s $(which fish) root

    # TODO: Setup and start colima container
fi

# Coding agents
mkdir ~/.pi/agent ~/.agents ~/.claude
ln -s $(PWD)/pi/extensions $(PWD)/pi/prompts $(PWD)/pi/AGENTS.md ~/.pi/agent/
ln -s $(PWD)/pi/skills ~/.agents/
ln -s $(PWD)/pi/skills $(PWD)/claude-code/settings.json ~/.claude/
