# Homebrew
eval (/opt/homebrew/bin/brew shellenv fish)

#
# Environment variables
#

set -g fish_greeting
set -gx GOPRIVATE "github.com/devrev"
set -gx GOPATH "$HOME/.local/share/go"

fish_add_path -gP $GOPATH/bin
fish_add_path -gP $HOME/.amp/bin
fish_add_path -gP $HOME/.local/bin

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

function amp --description 'Amp Code'
    command amp --executor runner:macbook-pro --runner-dir "$PWD" $argv
end

function update --description "Update system packages"
    echo "Updating dotfiles..."
    git -C $HOME/.config/dotfiles pull; or return

    echo "Updating homebrew packages..."
    brew update && brew upgrade && brew autoremove && brew cleanup
end

function tldr --description "Get cheat sheets for CLI programs"
    command curl cheat.sh/"$argv[1]"
end

function mksh --description "Create an executable script skeleton"
    echo '#!/usr/bin/env bash' >>"$argv[1]" && chmod u+x "$argv[1]"
end

function mkcd --description "Create a directory and enter it"
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
