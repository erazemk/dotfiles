#!/usr/bin/env bash

DOTFILES_HOME="$HOME/.config/dotfiles/personal"

mkdir -p ~/.config/fish
ln -sf $DOTFILES_HOME/fish/* ~/.config/fish/

mkdir -p ~/.config/git
ln -sf $DOTFILES_HOME/git/* ~/.config/git/

mkdir -p ~/.config/opencode
ln -sf $DOTFILES_HOME/opencode/* ~/.config/opencode/

mkdir -p ~/.config/zed
ln -sf $DOTFILES_HOME/zed/* ~/.config/zed/

if ! command -v brew &> /dev/null; then
    sudo -v
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew install $(cat $DOTFILES_HOME/homebrew/formulae | tr '\n' ' ')
brew install --cask $(cat $DOTFILES_HOME/homebrew/casks | tr '\n' ' ')

sudo chsh -s /opt/homebrew/bin/fish erazemk
sudo chsh -s /opt/homebrew/bin/fish root
