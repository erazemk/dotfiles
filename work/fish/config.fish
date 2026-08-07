#
# Environment variables
#

set -gx EDITOR 'code --wait'
set -gx GOPRIVATE github.com/devrev
set -gx COLIMA_HOME $XDG_CONFIG_HOME/colima

#
# Functions
#

function jwt --description "Decode a JWT token"
    echo "$argv[1]" | jq -R 'split(".") | .[1] | @base64d | fromjson'
end

function opencode --description "OpenCode"
    if not set -q DEVREV_API_KEY
        set -gx DEVREV_API_KEY (security find-generic-password -a "API Keys" -s "DevRev API Key" -w)
    end
    if not set -q ARCUS_API_KEY
        set -gx ARCUS_API_KEY (security find-generic-password -a devrev -s arcus-token -w)
    end

    command opencode $argv
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
