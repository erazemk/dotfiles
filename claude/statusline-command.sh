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
green='\033[32m'
yellow='\033[33m'
red='\033[31m'
reset='\033[0m'

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -lt 50 ]; then
    ctx_color="$green"
  elif [ "$used_int" -lt 80 ]; then
    ctx_color="$yellow"
  else
    ctx_color="$red"
  fi
  ctx_str=" ${ctx_color}(${used_int}%)${reset}"
else
  ctx_str=""
fi

if [ -n "$branch" ]; then
  printf "%b%s%b %b%s%b%b" "$blue" "$short" "$reset" "$pink" "$branch" "$reset" "$ctx_str"
else
  printf "%b%s%b%b" "$blue" "$short" "$reset" "$ctx_str"
fi
