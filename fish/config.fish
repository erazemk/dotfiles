#
# ~/.config/fish/config.fish
#

set -gx EDITOR hx
set -gx GOKRAZY_PARENT_DIR ~/Personal

if test -d /opt/homebrew
    set --global --export HOMEBREW_PREFIX /opt/homebrew
    set --global --export HOMEBREW_CELLAR /opt/homebrew/Cellar
    set --global --export HOMEBREW_REPOSITORY /opt/homebrew

    fish_add_path --global --move --path /opt/homebrew/bin /opt/homebrew/sbin
    fish_add_path $HOMEBREW_PREFIX/opt/curl/bin

    if test -n "$MANPATH[1]"
        set --global --export MANPATH '' $MANPATH
    end

    if not contains /opt/homebrew/share/info $INFOPATH
        set --global --export INFOPATH /opt/homebrew/share/info $INFOPATH
    end
end

if status is-interactive
    function update --description "Update system packages"
        switch (uname)
            case Linux
                sudo dnf upgrade --refresh
            case Darwin
                brew update && brew upgrade && brew autoremove && brew cleanup
        end

        npm i -g @mariozechner/pi-coding-agent
    end

    function claude --description "Claude Code"
        if not set -q AWS_BEARER_TOKEN_BEDROCK
            set -gx AWS_BEARER_TOKEN_BEDROCK (security find-generic-password -w -s aws-bedrock -a aws-bedrock)
        end
        if not set -q DEVREV_API_KEY
            set -gx DEVREV_API_KEY (security find-generic-password -w -s devrev -a devrev)
        end
        if not set -q CIRCLECI_TOKEN
            set -gx CIRCLECI_TOKEN (security find-generic-password -w -s circleci -a circleci)
        end

        command claude $argv
    end

    abbr upi 'npm i -g @mariozechner/pi-coding-agent'
    function pi --description "Pi coding agent"
        if not set -q AWS_BEARER_TOKEN_BEDROCK
            set -gx AWS_BEARER_TOKEN_BEDROCK (security find-generic-password -w -s aws-bedrock -a aws-bedrock)
        end
        if not set -q OPENAI_API_KEY
            set -gx OPENAI_API_KEY (security find-generic-password -w -s openai -a openai)
        end
        if not set -q OLLAMA_API_KEY
            set -gx OLLAMA_API_KEY (security find-generic-password -w -s ollama -a ollama)
        end

        set -x AWS_REGION eu-central-1

        command pi $argv
    end
end
