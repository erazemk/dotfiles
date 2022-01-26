# .bash_profile

# User specific environment and startup programs
export EDITOR=kak
export PAGER='kak -ro'

export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_RUNTIME_DIR="/tmp/runtime-$(id -un)"
export XDG_CACHE_HOME="/tmp/cache-$(id -un)"

export GNUPGHOME="$HOME/.config/gnupg"
export GOPATH="$HOME/.local/share/golang"
export WINEPREFIX="$HOME/.local/share/wineprefixes/default"
export ANDROID_HOME="$HOME/.local/share/android-sdk"

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# Set the alias for thefuck
eval $(thefuck --alias)
