#
# ~/.config/fish/config.fish
#

set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
fish_add_path -gP $HOME/.local/bin

set -gx GIT_TERMINAL_PROMPT 1
set -gx GOPATH $XDG_DATA_HOME/go
fish_add_path -gP $GOPATH/bin

set -gx EDITOR zed --wait
set -gx SSH_AUTH_SOCK ~/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock

abbr mv 'mv -iv'
abbr rm 'rm -Iv'
abbr cp 'cp -Riv'
abbr mkdir 'mkdir -p'
abbr cdtmp 'cd (mktemp -d)'
abbr oc 'opencode'

set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
set -gx HOMEBREW_REPOSITORY /opt/homebrew
fish_add_path -g --move --path /opt/homebrew/bin /opt/homebrew/sbin
fish_add_path $HOMEBREW_PREFIX/opt/curl/bin

if test -n "$MANPATH[1]"
    set -gx MANPATH '' $MANPATH
end

if not contains /opt/homebrew/share/info $INFOPATH
    set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
end

function update --description "Update system packages"
    brew update && brew upgrade && brew autoremove && brew cleanup
end

function tldr --description "Get cheat sheets for CLI programs"
    command curl cheat.sh/"$argv[1]"
end

function mksh --description "Create an executable script skeleton"
    echo '#!/usr/bin/env bash' >>"$argv[1]" && chmod u+x "$argv[1]"
end

function mkcd --description "Create a temporary directory and go into it"
    mkdir -p "$argv[1]" && cd "$argv[1]"
end
