#
# ~/.config/fish/config.fish
#

# XDG paths
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
fish_add_path -gP $HOME/.local/bin

# Other exports
set -gx EDITOR code --wait
set -gx COLIMA_HOME $XDG_CONFIG_HOME/colima
set -gx SSH_AUTH_SOCK ~/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock

# Golang
set -gx GIT_TERMINAL_PROMPT 1
set -gx GOPATH $XDG_DATA_HOME/go
fish_add_path -gP $GOPATH/bin

abbr mv 'mv -iv'
abbr rm 'rm -Iv'
abbr cp 'cp -Riv'
abbr mkdir 'mkdir -p'
abbr cdtmp 'cd (mktemp -d)'

if test -d /opt/homebrew
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
end

if status is-interactive
    function update --description "Update system packages"
        brew update && brew upgrade && brew autoremove && brew cleanup
    end

    function opencode --description "OpenCode AI harness"
        set -gx OPENCODE_ENABLE_EXA true
        set -gx OPENCODE_EXPERIMENTAL_LSP_TOOL true
        set -gx OPENCODE_EXPERIMENTAL_MARKDOWN true

        command opencode $argv
    end

    abbr oc opencode
end
