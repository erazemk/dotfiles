#!/bin/sh
# A script for initializing the dotfiles on a macOS host

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "This script is meant to be run on a macOS host"
    exit 1
fi

# Check if stow is installed
if ! command -v stow > /dev/null 2>&1; then
    echo "stow is not installed"
    exit 1
fi

mkdir -p \
    "$HOME/Library/Application Support/Cursor/User" \
    "$HOME/.config/fish" \
    "$HOME/.config/git" \
    "$HOME/.claude" \
    "$HOME/.ssh"

stow -t "$HOME/Library/Application Support/Cursor/User" -S cursor
stow -t "$HOME/.config/fish" -S fish
stow -t "$HOME/.config/git" -S git
stow -t "$HOME/.ssh" -S ssh
