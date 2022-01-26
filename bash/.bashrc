# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Add user binaries to PATH
PATH="$HOME/.local/bin:$PATH"

# Add Golang binaries to PATH
PATH="$GOPATH/bin:$PATH"

# Add Flutter binaries to PATH
PATH="$HOME/.local/share/flutter/bin:$PATH"

export PATH

# Bash history
HISTCONTROL=ignoreboth
HISTSIZE=100000
HISTFILESIZE=1000000
HISTFILE="$HOME/.config/bash/history"
HISTIGNORE='ls:la:cd:pwd'

# User specific aliases and functions
alias lsblk='lsblk -f'
alias grep='grep --color=auto'
alias dot='/usr/bin/git --git-dir=$HOME/.local/share/dotfiles/ --work-tree=$HOME'
alias mkdir='mkdir -pv'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ls='ls -lGhp --color=auto --group-directories-first'
alias la='ls -lAGhp --color=auto --group-directories-first'

alias rcp='rsync -vrulpEh --stats --progress'
alias cp='cp -Riv'
alias mv='mv -iv'
alias rm='rm -Iv'

# Source bash functions
for func in ${HOME}/.config/bash/*.sh; do source ${func}; done

# Create and cd into temporary directories
cdtmp() {
	cd "$(mktemp -d)"
}

# cheat.sh shortcut
info() {
	curl cheat.sh/$1
}

# PS1 configuration
RED='\[\e[1;31m\]'
YELLOW='\[\e[1;33m\]'
BLUE='\[\e[1;34m\]'
PURPLE='\[\e[1;35m\]'
NONE='\[\e[m\]'

prompt_config() {
	local EXIT_CODE="$?"
	history -a
	history -n

	# Check if running as root
	if [ "$(id -u)" -eq 0 ]; then
		PS1="${RED}\u@\h${NONE}: ${BLUE}\w${NONE}"
	else
		PS1="${YELLOW}\u@\h${NONE}: ${BLUE}\w${NONE}"
	fi

	# Add git branch info
	if [ -x /usr/bin/git ]; then
		# Check if we're in a git directory
		if git rev-parse --is-inside-work-tree &>/dev/null; then
			PS1+="${PURPLE}$(git branch 2> /dev/null | \
					sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/')${NONE}"
		fi
	fi

	# Show exit code if there was an error
	if [ "${EXIT_CODE}" -ne 0 ]; then
		PS1+=" ${RED}[${EXIT_CODE}]${NONE}"
	fi

	# Add the PS1 end
	PS1+=" \\$ "
}

#PROMPT_COMMAND="history -a; history -n; prompt_config"
PROMPT_COMMAND=prompt_config

# GPG config
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
export GPG_TTY="$(tty)"
gpgconf --launch gpg-agent
