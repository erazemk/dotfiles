#
# /etc/profile.d/defaults.sh
#
# Contains sensible system-wide per-user defaults.

# XDG paths
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export PATH="$HOME/.local/bin:$PATH"

# Go-specific
export GIT_TERMINAL_PROMPT=1
export GOPATH="$XDG_DATA_HOME/go"
export PATH="$GOPATH/bin:$PATH"

#
# DevRev-specific additions
#

export GOPRIVATE="github.com/devrev"
export XDG_CACHE_DIR="$XDG_CACHE_HOME" # sidekick compatibility
