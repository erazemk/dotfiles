# XDG Paths
set -x XDG_CACHE_HOME $HOME/.cache
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share
fish_add_path -gP $HOME/.local/bin

# Homebrew
if test -d /opt/homebrew
    /opt/homebrew/bin/brew shellenv | source

    set -gx HOMEBREW_NO_ENV_HINTS 1
    ! set -q MANPATH; and set MANPATH ''
    set -gx MANPATH $HOMEBREW_PREFIX/share/man $MANPATH
    ! set -q INFOPATH; and set INFOPATH ''
    set -gx INFOPATH $HOMEBREW_PREFIX/share/info $INFOPATH

    abbr brewer 'brew update && brew upgrade --greedy && brew cleanup'
end

# Program variables
set -x EDITOR hx
set -x GIT_TERMINAL_PROMPT 1
set -x GOPATH $XDG_DATA_HOME/go
fish_add_path -gP $GOPATH/bin

if status is-interactive
    # Disable fish greeting
    set -Ux fish_greeting

    # Pager (less) colors
    set -x LESS_TERMCAP_mb (set_color brred)
    set -x LESS_TERMCAP_md (set_color brred)
    set -x LESS_TERMCAP_me (set_color normal)
    set -x LESS_TERMCAP_se (set_color normal)
    set -x LESS_TERMCAP_so (set_color -b blue bryellow)
    set -x LESS_TERMCAP_ue (set_color normal)
    set -x LESS_TERMCAP_us (set_color brgreen)

    # Abbreviations
    abbr mkdir 'mkdir -p'
    abbr cp 'cp -Riv'
    abbr mv 'mv -iv'
    abbr rm 'rm -Iv'
    abbr cdtmp 'cd (mktemp -d)'

    # Get cheatsheets for programs
    function tldr
        command curl cheat.sh/"$argv[1]"
    end
end
