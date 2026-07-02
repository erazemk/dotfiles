#!/usr/bin/env bash

DOTFILES_HOME="$HOME/.config/dotfiles/personal"

mkdir -p ~/.config/fish
ln -sf $DOTFILES_HOME/fish/* ~/.config/fish/

mkdir -p ~/.config/git
ln -sf $DOTFILES_HOME/git/* ~/.config/git/

mkdir -p ~/.config/opencode
ln -sf $DOTFILES_HOME/opencode/* ~/.config/opencode/

sudo -v
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install $(cat $DOTFILES_HOME/homebrew/formulae | tr '\n' ' ')
brew install --cask $(cat $DOTFILES_HOME/homebrew/casks | tr '\n' ' ')

chsh -s /opt/homebrew/bin/fish erazemk
sudo chsh -s /opt/homebrew/bin/fish root
