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
abbr fpi 'flatpak install flathub'

# Directories
abbr mkdir 'mkdir -p'
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

function tldr
    command curl cheat.sh/$argv[1]
end

#function sha256sum -w sha256sum
#    command sha256sum --ignore-missing $argv
#end

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

# Specify R user library location
set -x R_LIBS_USER $XDG_DATA_HOME/R

# GPG
if test -d $XDG_CONFIG_HOME/gnupg
    set -x GNUPGHOME $XDG_CONFIG_HOME/gnupg
    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    set -x GPG_TTY (tty)
    eval (gpgconf --launch gpg-agent)
end

# Go
if test -e /usr/bin/go
    set -x GOPATH $XDG_DATA_HOME/go
    set PATH $PATH $GOPATH/bin
end

# Android
if test -d $XDG_DATA_HOME/android
    set PATH $PATH $XDG_DATA_HOME/android/platform-tools
    set PATH $PATH $ANDROID_HOME/cmdline-tools/latest/bin
    set -x ANDROID_HOME $XDG_DATA_HOME/android
end

# Flutter
if test -d $XDG_DATA_HOME/flutter
    set PATH $PATH $XDG_DATA_HOME/flutter/bin
end

# Fedora-specific
if test (cat /etc/os-release | grep -m 1 "ID" | cut -d '=' -f2) = "fedora"
    abbr upgrade 'sudo dnf upgrade --refresh'
    abbr fpk 'flatpak kill'
    abbr flaptak 'flatpak'
    abbr tb 'toolbox'
    abbr tbe 'toolbox enter'
    abbr db 'distrobox'
    abbr dbe 'distrobox enter'
end

