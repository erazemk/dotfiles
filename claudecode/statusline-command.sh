#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Shorten home directory to ~
case "$cwd" in
  "$HOME") short="~" ;;
  "$HOME"/*) short="~${cwd#$HOME}" ;;
  *) short="$cwd" ;;
esac

blue='\033[34m'
pink='\033[95m'
reset='\033[0m'

if [ -n "$branch" ]; then
  printf "%b%s%b %b%s%b" "$blue" "$short" "$reset" "$pink" "$branch" "$reset"
else
  printf "%b%s%b" "$blue" "$short" "$reset"
fi
