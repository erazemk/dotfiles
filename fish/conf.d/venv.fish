# Source: https://alexwlchan.net/2023/fish-venv/

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
