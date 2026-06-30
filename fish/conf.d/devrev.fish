# Only run on DevRev MacBook
if test -d ~/DevRev
    set -gx EDITOR code --wait
    set -gx GOPRIVATE github.com/devrev
    set -gx COLIMA_HOME $XDG_CONFIG_HOME/colima

    if not set -q DEVREV_API_KEY
        set -gx DEVREV_API_KEY (security find-generic-password -w -s "DevRev API Key" -a "API Keys")
    end

    function cc --description "Claude Code"
        command claude $argv
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
end
