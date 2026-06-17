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
