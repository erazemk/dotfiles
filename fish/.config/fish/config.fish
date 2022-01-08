#
# ~/.config/fish/config.fish
#

# Disable greeting
set fish_greeting

#################
# Abbreviations #
#################

# Random
abbr lsblk 'lsblk -f'
abbr upgrade 'sudo dnf upgrade --refresh'
abbr conf 'nvim ~/.config/fish/config.fish'
abbr fpk 'flatpak kill'
abbr code 'codium'
abbr c 'codium'
abbr top 'gotop --nvidia'
abbr pc 'podman-compose'
abbr flaptak 'flatpak'

# Toolbox
abbr tb 'toolbox'
abbr tbe 'toolbox enter'

# Directories
abbr mkdir 'mkdir -p'
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .... 'cd ../../..'
abbr ..... 'cd ../../../..'

# Files
abbr cp 'cp -Riv'
abbr mv 'mv -iv'
abbr rm 'rm -Iv'

#############
# Functions #
#############

function grep -w grep
    command grep --color=auto $argv
end

function ls -w exa
    command exa -l --group-directories-first $argv
end

function la -w exa
    command exa -la --group-directories-first $argv
end

function lt -w exa
	command exa -lT --group-directories-first $argv
end

function rcp -w rsync
    rsync -vrulpEh --stats --progress $argv
end

function cdtmp
    cd (mktemp -d $argv[1])
end

function info
    curl cheat.sh/$argv[1]
end

#############
# Variables #
#############

# Add user binaries to PATH
set PATH $PATH $HOME/.local/bin

# Global variables
set -x EDITOR nvim
set -x PAGER less
set -x MANPAGER less

set -x XDG_CACHE_HOME $HOME/.cache
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share

set -x GNUPGHOME $XDG_CONFIG_HOME/gnupg
set -x GOPATH $XDG_DATA_HOME/go

# GPG config
set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
set -x GPG_TTY (tty)
eval (gpgconf --launch gpg-agent)

# Add Golang binaries to PATH
set PATH $PATH $GOPATH/bin

# Add Flutter binaries to PATH
set PATH $PATH $XDG_DATA_HOME/flutter/bin

# Set CHROME_EXECUTABLE to please flutter doctor
set -x CHROME_EXECUTABLE /usr/bin/brave-browser

# Add Android binaries to PATH
set -x ANDROID_HOME $XDG_DATA_HOME/android-sdk
set PATH $PATH $ANDROID_HOME/cmdline-tools/latest/bin
set PATH $PATH $ANDROID_HOME/platform-tools

# Set Adwaita dark as the default GTK theme
set GTK_THEME 'Adwaita:dark'
