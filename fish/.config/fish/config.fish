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
abbr top 'gotop'

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

# Pager (less) colors
set -x LESS_TERMCAP_mb (set_color brred)
set -x LESS_TERMCAP_md (set_color brred)
set -x LESS_TERMCAP_me (set_color normal)
set -x LESS_TERMCAP_se (set_color normal)
set -x LESS_TERMCAP_so (set_color -b blue bryellow)
set -x LESS_TERMCAP_ue (set_color normal)
set -x LESS_TERMCAP_us (set_color brgreen)

#############
# Functions #
#############

function conf
    if test (count $argv) -eq 0
        kak ~/.config/fish/config.fish
    else if test (count $argv) -eq 1
        # Common configs
        if test $argv[1] = "git"
            kak ~/.config/git/config
        # General parsing
        else if test -f ~/.config/"$argv[1]"
            kak ~/.config/"$argv[1]"
        else if test -d ~/.config/"$argv[1]"
            echo "Argument has to be a file!"
        end
    else
        echo "Usage: conf <config file> (e.g. conf git/config)"
    end
end

function grep -w grep
    command grep --color=auto $argv
end

function rcp -w rsync
    command rsync -vrulpEh --stats --progress $argv
end

function cdtmp
    cd (mktemp -d $argv[1])
end

function info
    command curl cheat.sh/$argv[1]
end

function sha256sum -w sha256sum
    command sha256sum --ignore-missing $argv
end

#############
# Variables #
#############

# Add user binaries to PATH
set PATH $PATH $HOME/.local/bin

# Global variables
set -x EDITOR kak
set -x PAGER less
set -x MANPAGER less

set -x XDG_CACHE_HOME $HOME/.cache
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share
set -x GNUPGHOME $XDG_CONFIG_HOME/gnupg

# GPG config
if test -d $XDG_CONFIG_HOME/gnupg
	set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
	set -x GPG_TTY (tty)
	eval (gpgconf --launch gpg-agent)
end

# Go config
if type -sq go; or test -d /usr/local/go
	set -x GOPATH $XDG_DATA_HOME/go
	set PATH $PATH $GOPATH/bin
	set PATH $PATH /usr/local/go/bin
end

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

# WSL-specific config
#if set -q WSL_DISTRO_NAME
#    abbr dir 'cd /mnt/c/Users/Erazem'
#end

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
