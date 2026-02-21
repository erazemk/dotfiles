#
# /etc/fish/conf.d/defaults.fish
#
# Contains sensible per-user defaults.

# XDG paths
set -x XDG_CACHE_HOME $HOME/.cache
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share
fish_add_path -gP $HOME/.local/bin

# Go-specific
set -x GIT_TERMINAL_PROMPT 1
set -x GOPATH $XDG_DATA_HOME/go
fish_add_path -gP $GOPATH/bin

#
# Useful additions
#

set -Ux fish_greeting

abbr mv 'mv -iv'
abbr rm 'rm -Iv'
abbr cp 'cp -Riv'
abbr mkdir 'mkdir -p'
abbr cdtmp 'cd (mktemp -d)'

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

function update --description "Update system packages"
    sudo dnf upgrade --refresh
end

#
# DevRev-specific additions
#

set -x GOPRIVATE github.com/devrev
set -x XDG_CACHE_DIR $XDG_CACHE_HOME # sidekick compatibility

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
