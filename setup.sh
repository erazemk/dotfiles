#!/usr/bin/env bash

DOTFILES="$HOME/.config/dotfiles"

mkdir -p ~/.config/fish
ln -s $DOTFILES/git ~/.config/
ln -s $DOTFILES/fish/config.fish ~/.config/fish/

# macOS-specific
if [[ $(uname) == "Darwin" ]]; then
    mkdir -p ~/.aws ~/.colima/_templates ~/Library/Application\ Support/Code/User/
    ln -s $DOTFILES/aws/config ~/.aws/
    ln -s $DOTFILES/aerospace ~/.config/
    ln -s $DOTFILES/fish/conf.d ~/.config/fish/
    ln -s $DOTFILES/vscode/settings.json $DOTFILES/vscode/keybindings.json ~/Library/Application\ Support/Code/User/

    # Homebrew
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install -y awscli colima curl docker docker-buildx docker-compose docker-credential-helper fish gh git git-lfs go helix jq node openssh python ripgrep tree unzip uv xz zstd
    brew install -y --cask aerospace aws-vpn-client brave-browser codex ghostty lookaway monitorcontrol pearcleaner slack visual-studio-code

    # Switch to fish shell
    sudo chsh -s $(which fish) $(id -un)
    sudo chsh -s $(which fish) root

    ln -s $DOTFILES/colima/template.yml ~/.colima/_templates/default.yml
    brew services start colima
fi

# Coding agents
mkdir ~/.pi/agent ~/.agents ~/.claude
ln -s $DOTFILES/pi/extensions $DOTFILES/pi/prompts $DOTFILES/pi/AGENTS.md ~/.pi/agent/
ln -s $DOTFILES/pi/skills ~/.agents/
ln -s $DOTFILES/pi/skills $DOTFILES/claude-code/settings.json ~/.claude/
