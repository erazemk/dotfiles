# Homebrew
eval (brew shellenv fish)

#
# Environment variables
#

set -Ux fish_greeting
set -gx EDITOR 'zed --wait'

set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
fish_add_path -gP $HOME/.local/bin

set -gx GIT_TERMINAL_PROMPT 1
set -gx GOPATH $XDG_DATA_HOME/go
set -gx GOPRIVATE github.com/devrev
set -gx COLIMA_HOME $XDG_CONFIG_HOME/colima
fish_add_path -gP $GOPATH/bin

set -gx ARCUS_API_KEY (security find-generic-password -a devrev -s arcus-token -w 2>/dev/null)
set -gx DEVREV_API_KEY (security find-generic-password -a devrev -s devrev-token -w 2>/dev/null)

#
# Aliases
#

abbr mv 'mv -iv'
abbr rm 'rm -Iv'
abbr cp 'cp -Riv'
abbr mkdir 'mkdir -p'
abbr cdtmp 'cd (mktemp -d)'

#
# Functions
#

function update --description "Update system packages"
    echo "Updating dotfiles..."
    git -C $HOME/.config/dotfiles pull
    echo "Updating homebrew packages..."
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

function jwt --description "Decode a JWT token"
    echo "$argv[1]" | jq -R 'split(".") | .[1] | @base64d | fromjson'
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
