# XDG Paths
set -x XDG_CACHE_HOME $HOME/.cache
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share

# Program variables
set -x EDITOR hx
set -x GIT_TERMINAL_PROMPT 1
set -x GOPATH $XDG_DATA_HOME/go
set -x GOPRIVATE github.com/devrev
set -x GOKRAZY_PARENT_DIR ~/Personal
set -x PI_CODING_AGENT_DIR $XDG_CONFIG_HOME/pi

# Homebrew
if test -d /opt/homebrew
    set --global --export HOMEBREW_PREFIX "/opt/homebrew"
    set --global --export HOMEBREW_CELLAR "/opt/homebrew/Cellar"
    set --global --export HOMEBREW_REPOSITORY "/opt/homebrew"
    fish_add_path --global --move --path "/opt/homebrew/bin" "/opt/homebrew/sbin"

    if test -n "$MANPATH[1]"
        set --global --export MANPATH '' $MANPATH
    end

    if not contains "/opt/homebrew/share/info" $INFOPATH
        set --global --export INFOPATH "/opt/homebrew/share/info" $INFOPATH
    end

    abbr brewer 'brew update && brew upgrade && brew autoremove && brew cleanup'
end

fish_add_path -gP $GOPATH/bin
fish_add_path -gP $HOME/.local/bin
fish_add_path $HOMEBREW_PREFIX/opt/curl/bin

if status is-interactive
    # Pager (less) colors
    set -x LESS_TERMCAP_mb (set_color brred)
    set -x LESS_TERMCAP_md (set_color brred)
    set -x LESS_TERMCAP_me (set_color normal)
    set -x LESS_TERMCAP_se (set_color normal)
    set -x LESS_TERMCAP_ue (set_color normal)
    set -x LESS_TERMCAP_us (set_color brgreen)
    set -x LESS_TERMCAP_so (set_color -b blue bryellow)

    # Abbreviations
    abbr mv 'mv -iv'
    abbr rm 'rm -Iv'
    abbr cp 'cp -Riv'
    abbr mkdir 'mkdir -p'
    abbr cdtmp 'cd (mktemp -d)'

    function tldr --description "Get cheat sheets for CLI programs"
        command curl cheat.sh/"$argv[1]"
    end

    function jwt --description "Helper for decoding JWT tokens"
        echo "$argv[1]" | jq -R 'split(".") | .[1] | @base64d | fromjson'
    end

    function mksh --description "Shortcut for creating executable scripts"
        echo '#!/usr/bin/env bash' >>"$argv[1]" && chmod u+x "$argv[1]"
    end

    function mkcd --description "Shortcut for creating a temp dir and cd-ing into it"
        mkdir -p "$argv[1]" && cd "$argv[1]"
    end

    function dr --description "DevRev CLI wrapper with auto-download"
        if ! command -v devrev &>/dev/null
            go install -v github.com/devrev/devrev-cli/devrev@main
        end

        command devrev -q $argv
    end

    function aws --description "AWS CLI wrapper with automatic SSO re-login"
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

    function howto --description "CLI AI-assisted cheat sheet"
        if not set -q HOWTO_AI_TOKEN
            set -gx HOWTO_AI_TOKEN (security find-generic-password -w -s nalgeon/howto -a nalgeon/howto)
        end

        command howto $argv
    end

    function pi --description "Pi coding agent"
        if not set -q AWS_BEARER_TOKEN_BEDROCK
            set -gx AWS_BEARER_TOKEN_BEDROCK (security find-generic-password -w -s aws-bedrock -a aws-bedrock)
        end
        if not set -q OPENAI_API_KEY
            set -gx OPENAI_API_KEY (security find-generic-password -w -s openai -a openai)
        end
        if not set -q DD_API_KEY
            set -gx DD_API_KEY (security find-generic-password -w -s datadog -a datadog-api-key)
        end
        if not set -q DD_APP_KEY
            set -gx DD_APP_KEY (security find-generic-password -w -s datadog -a datadog-app-key)
        end
        if not set -q DEVREV_API_KEY
            set -gx DEVREV_API_KEY (security find-generic-password -w -s devrev -a devrev)
        end
        if not set -q JINA_API_KEY
            set -gx JINA_API_KEY (security find-generic-password -w -s jina-ai -a jina-ai)
        end

        set -x AWS_REGION eu-central-1

        command pi $argv
    end

    function upi --description "Update the Pi coding agent and its packages"
        # Update the Pi agent
        npm install -g @mariozechner/pi-coding-agent

        # Update the git repos for extensions and prompts
        for dir in $PI_CODING_AGENT_DIR/packages/*/
            echo "Pulling updates for $dir"
            git -C $dir pull
        end
    end
end
