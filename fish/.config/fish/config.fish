#
# ~/.config/fish/config.fish
#

# Disable greeting
set -U fish_greeting ""

#################
# Abbreviations #
#################

# Random
abbr lsblk 'lsblk -f'
abbr code 'codium'
abbr c 'codium'
abbr top 'gotop'
abbr conf 'kak ~/.config/fish/config.fish'

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
set -x EDITOR kak
set -x PAGER kak-pager
set -x MANPAGER kak-pager

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

# Fedora-specific config
if test (cat /etc/os-release | grep -m 1 "ID" | cut -d '=' -f2) = "fedora"
	# Set common abbreviations
	abbr upgrade 'sudo dnf upgrade --refresh'
	abbr fpk 'flatpak kill'
	abbr flaptak 'flatpak'
	abbr tb 'toolbox'
	abbr tbe 'toolbox enter'

	# Set Adwaita dark as the default GTK theme
	set GTK_THEME 'Adwaita:dark'
end

# If flutter is installed, add its files to PATH
if test -d $XDG_DATA_HOME/flutter
	# Add Flutter binaries to PATH
	set PATH $PATH $XDG_DATA_HOME/flutter/bin

	# Set CHROME_EXECUTABLE to please flutter doctor
	set -x CHROME_EXECUTABLE /usr/bin/brave-browser

	# Add Android binaries to PATH
	set -x ANDROID_HOME $XDG_DATA_HOME/android-sdk
	set PATH $PATH $ANDROID_HOME/cmdline-tools/latest/bin
	set PATH $PATH $ANDROID_HOME/platform-tools
end
