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

# Directories
abbr mkdir 'mkdir -p'
abbr cdd 'cd /mnt/d'
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

function ls -w ls
    command ls -lhp --color=auto --group-directories-first $argv
end

function la -w ls
    command ls -lAhp --color=auto --group-directories-first $argv
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

# Global variables
set -x EDITOR nvim
set -x PAGER less
set -x MANPAGER less

set -x XDG_CACHE_HOME /tmp/cache-$USER
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share

set -x GNUPGHOME $XDG_CONFIG_HOME/gnupg
set -x GOPATH $XDG_DATA_HOME/golang

# GPG config
set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
set -x GPG_TTY (tty)
eval (gpgconf --launch gpg-agent)

# Add user binaries to PATH
set PATH $PATH $HOME/.local/bin

# Add Golang binaries to PATH
set PATH $PATH $GOPATH/bin
