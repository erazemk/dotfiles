#!/usr/bin/env bash

DOTFILES_HOME="$HOME/.config/dotfiles/personal"

source ../common/setup.sh

# Zed
mkdir -p ~/.config/zed
ln -sf $DOTFILES_HOME/zed/* ~/.config/zed/
