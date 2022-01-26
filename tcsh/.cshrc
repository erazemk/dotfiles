#
# ~/.cshrc
#

### Aliases
alias h		history 25
alias j		jobs -l
alias grep	grep --color=auto

# Directories
alias la	ls -lFGhpA --color=auto
alias ls	/bin/ls -lFGhp --color=auto
alias mkdir	mkdir -pv
alias ..	cd ..
alias ...	cd ../..
alias ....	cd ../../..
alias .....	cd ../../../..

# Files
alias rcp	rsync -vrulpEh --stats --progress
alias cp	cp -Riv
alias mv	mv -iv
alias rm	rm -Iv

# Create and cd into temporary directories
alias cdtmp	cd `mktemp -d`

# Export variables
setenv EDITOR	nvim
setenv PAGER	less
setenv BROWSER	qutebrowser
set path = ($HOME/.local/bin /sbin /bin /usr/sbin /usr/bin /usr/local/sbin /usr/local/bin)

# XDG dirs
setenv XDG_CONFIG_HOME		$HOME/.config
setenv XDG_CACHE_HOME		/tmp/cache-`id -un`
setenv XDG_RUNTIME_DIR		/tmp/runtime-`id -un`
setenv XDG_DATA_HOME		$HOME/.local/share
setenv XDG_DOWNLOAD_DIR		$HOME/downloads
setenv XDG_DOCUMENTS_DIR	$HOME/documents
setenv XDG_MUSIC_DIR		$HOME/music
setenv XDG_PICTURES_DIR		$HOME/pictures
setenv XDG_VIDEOS_DIR		$HOME/videos

# Cleanup
setenv GNUPGHOME			$XDG_DATA_HOME/gnupg
setenv GOPATH				$XDG_DATA_HOME/go
setenv PASSWORD_STORE_DIR	$XDG_DATA_HOME/password-store
setenv WINEPREFIX			$XDG_DATA_HOME/wineprefixes/default

# Wayland vars
setenv QT_WAYLAND_DISABLE_WINDOWDECORATION	1
setenv _JAVA_AWT_WM_NONREPARENTING			1
setenv XDG_SESSION_TYPE						wayland
setenv BEMENU_BACKEND						wayland

# NNN vars
setenv NNN_OPTS		AdEFx
setenv NNN_COLORS	1234

if ($?prompt) then
	alias precmd 'source /usr/local/bin/prompt.csh'

	set filec
	set history = 100000
	set savehist = (100000 merge)
	set autolist
	set autoexpand
	set autorehash
	set mail = (/var/mail/$USER)
	if ( $?tcsh ) then
		bindkey "^W" backward-delete-word
		bindkey -k up history-search-backward
		bindkey -k down history-search-forward
	endif

	# GPG config
	setenv SSH_AUTH_SOCK `gpgconf --list-dirs agent-ssh-socket`
	setenv GPG_TTY `tty`
	gpg-connect-agent updatestartuptty /bye >/dev/null
	clear
endif

# Sway/Wayland support
mkdir $XDG_RUNTIME_DIR
chmod 0700 $XDG_RUNTIME_DIR
unsetenv DISPLAY
