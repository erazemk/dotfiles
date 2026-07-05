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

model_name=$(echo "$input" | jq -r '.model.display_name // empty' | sed 's/ (1M context)//')
if [ -n "$model_name" ]; then
  model_str=" ${blue}[${model_name}]${reset}"
else
  model_str=""
fi

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
  printf "%b%s%b %b%s%b%b%b" "$blue" "$short" "$reset" "$pink" "$branch" "$reset" "$model_str" "$ctx_str"
else
  printf "%b%s%b%b%b" "$blue" "$short" "$reset" "$model_str" "$ctx_str"
fi
