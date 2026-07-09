#
# ~/.config/fish/config.fish
#

#
# Environment variables
#

set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
fish_add_path -gP $HOME/.local/bin

set -gx GIT_TERMINAL_PROMPT 1
set -gx GOPATH $XDG_DATA_HOME/go
set -gx GOPRIVATE github.com/devrev
fish_add_path -gP $GOPATH/bin

set -gx EDITOR code --wait
set -gx COLIMA_HOME $XDG_CONFIG_HOME/colima
set -gx SSH_AUTH_SOCK ~/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock

# Homebrew

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

#
# Aliases
#

abbr mv 'mv -iv'
abbr rm 'rm -Iv'
abbr cp 'cp -Riv'
abbr mkdir 'mkdir -p'
abbr cdtmp 'cd (mktemp -d)'

# Claude

abbr cc 'claude'
abbr usage 'npx ccusage@latest claude'

if not set -q DEVREV_API_KEY
    set -gx DEVREV_API_KEY (security find-generic-password -w -s "DevRev API Key" -a "API Keys")
end

#
# Functions
#

function update --description "Update system packages"
    brew update && brew upgrade && brew autoremove && brew cleanup
end

function tldr --description "Get cheat sheets for CLI programs"
    command curl cheat.sh/"$argv[1]"
end

function jwt --description "Decode a JWT token"
    echo "$argv[1]" | jq -R 'split(".") | .[1] | @base64d | fromjson'
end

function mksh --description "Create an executable script skeleton"
    echo '#!/usr/bin/env bash' >>"$argv[1]" && chmod u+x "$argv[1]"
end

function mkcd --description "Create a temporary directory and go into it"
    mkdir -p "$argv[1]" && cd "$argv[1]"
end

function devrev --description "Run DevRev CLI or install it if missing"
    if ! command -v devrev &>/dev/null
        go install -v github.com/devrev/devrev-cli/devrev@main
    end

    command devrev -q $argv
end

function aws --description "Run AWS CLI with automatic log in (when using S3)"
    if test "$argv[1]" = s3
        set -l output (command aws $argv 2>&1)
        set -l exit_code $status

        echo -n $output

        if string match -q "*Token has expired and refresh failed*" -- $output
            command aws sso login
            if test $status -eq 0
                command aws $argv
            else
                return $status
            end
        end

        return $exit_code
    else
        command aws $argv
    end
end

function ecr --description "Log into AWS ECR through docker"
    aws sso login
    aws ecr get-login-password --region us-east-1 | \
        docker login --username AWS --password-stdin 173672169127.dkr.ecr.us-east-1.amazonaws.com
end

function venv --description "Create and activate a new virtual environment"
    python3 -m venv .venv --upgrade-deps
    source .venv/bin/activate.fish

    if test -e .git
        set line_to_append ".venv"
        set target_file ".git/info/exclude"

        if not grep --quiet --fixed-strings --line-regexp "$line_to_append" "$target_file" 2>/dev/null
            echo "$line_to_append" >>"$target_file"
        end
    end
end

function auto_venv --on-variable PWD --description "Auto (de)activate venv when changing directories"
    set REPO_ROOT (git rev-parse --show-toplevel 2>/dev/null)

    if test -z "$REPO_ROOT"; and test -n "$VIRTUAL_ENV"
        deactivate
    end
    if [ "$VIRTUAL_ENV" = "$REPO_ROOT/.venv" ]
        return
    end
    if [ -d "$REPO_ROOT/.venv" ]
        source "$REPO_ROOT/.venv/bin/activate.fish" &>/dev/null
    end
end
