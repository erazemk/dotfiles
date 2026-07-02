#!/usr/bin/env bash

DOTFILES_HOME="$HOME/.config/dotfiles/work"

mkdir -p ~/.aws
ln -sf $DOTFILES_HOME/aws/* ~/.aws/

mkdir -p ~/.config/colima/_templates ~/Library/LaunchAgents
ln -sf $DOTFILES_HOME/colima/template.yml ~/.config/colima/_templates/default.yml
ln -sf $DOTFILES_HOME/launchctl/* ~/Library/LaunchAgents/
for file in ~/Library/LaunchAgents/*; do
    launchctl load "$file"
done

mkdir -p ~/.config/fish
ln -sf $DOTFILES_HOME/fish/* ~/.config/fish/

mkdir -p ~/.config/git
ln -sf $DOTFILES_HOME/git/* ~/.config/git/

mkdir -p ~/Library/Application\ Support/Code/User/
ln -sf $DOTFILES_HOME/vscode/* ~/Library/Application\ Support/Code/User/

if ! command -v brew &> /dev/null; then
    sudo -v
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew install $(cat $DOTFILES_HOME/homebrew/formulae | tr '\n' ' ')
brew install --cask $(cat $DOTFILES_HOME/homebrew/casks | tr '\n' ' ')

sudo chsh -s /opt/homebrew/bin/fish erazemk
sudo chsh -s /opt/homebrew/bin/fish root
