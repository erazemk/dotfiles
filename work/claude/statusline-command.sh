#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
branch_full=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
branch_stripped="${branch_full##*/}"

# Full path, home directory shortened to ~
case "$cwd" in
  "$HOME") path_full="~" ;;
  "$HOME"/*) path_full="~/${cwd#$HOME/}" ;;
  *) path_full="$cwd" ;;
esac

# Fallback: ellipsize the middle of the path, e.g. ~/DevRev/.../foo or ~/.../foo
case "$cwd" in
  "$HOME") path_ellipsized="~" ;;
  "$HOME"/*)
    rel="${cwd#$HOME/}"
    path_ellipsized="~/$(echo "$rel" | awk -F'/' '{n=NF; if (n<=2) print $0; else print $1"/.../"$n}')"
    ;;
  *) path_ellipsized="$cwd" ;;
esac

# Further fallback: drop everything but the current directory name.
case "$cwd" in
  "$HOME") path_dironly="~" ;;
  *) path_dironly=".../${cwd##*/}" ;;
esac

blue='\033[34m'
pink='\033[95m'
green='\033[32m'
yellow='\033[33m'
red='\033[31m'
reset='\033[0m'

model_name=$(echo "$input" | jq -r '.model.display_name // empty' | sed 's/ (1M context)//' | awk '{print tolower($1)}')
effort_level=$(echo "$input" | jq -r '.effort.level // empty')
if [ -n "$model_name" ] && [ -n "$effort_level" ]; then
  model_str=$(printf "%b[%s/%s]%b" "$blue" "$model_name" "$effort_level" "$reset")
elif [ -n "$model_name" ]; then
  model_str=$(printf "%b[%s]%b" "$blue" "$model_name" "$reset")
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
  ctx_str=$(printf "%b(%s%%)%b" "$ctx_color" "$used_int" "$reset")
else
  ctx_str=""
fi

line_len() {
  printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g' | wc -m
}

# Join non-empty parts with a single space.
join_parts() {
  out=""
  for p in "$@"; do
    [ -z "$p" ] && continue
    if [ -z "$out" ]; then out="$p"; else out="$out $p"; fi
  done
  printf '%s' "$out"
}

# Greedily pack parts onto as few lines as possible, wrapping to a new
# line once a part would push the current line past $cols. Never drops
# a part - if a single part alone exceeds $cols it just gets its own line.
pack_lines() {
  cur=""
  out=""
  for p in "$@"; do
    [ -z "$p" ] && continue
    if [ -z "$cur" ]; then
      cur="$p"
      continue
    fi
    candidate="$cur $p"
    if [ "$cols" -gt 0 ] && [ "$(line_len "$candidate")" -gt "$cols" ]; then
      if [ -z "$out" ]; then out="$cur"; else out="$(printf '%s\n%s' "$out" "$cur")"; fi
      cur="$p"
    else
      cur="$candidate"
    fi
  done
  if [ -n "$cur" ]; then
    if [ -z "$out" ]; then out="$cur"; else out="$(printf '%s\n%s' "$out" "$cur")"; fi
  fi
  printf '%s' "$out"
}

cols=$(tput cols 2>/dev/null || echo 0)

path_colored() { printf "%b%s%b" "$blue" "$1" "$reset"; }
branch_colored() { [ -n "$1" ] && printf "%b%s%b" "$pink" "$1" "$reset"; }

single_line() {
  join_parts "$(path_colored "$1")" "$(branch_colored "$2")" "$model_str" "$ctx_str"
}

line=$(single_line "$path_full" "$branch_full")

if [ "$cols" -gt 0 ] && [ "$(line_len "$line")" -gt "$cols" ]; then
  line=$(single_line "$path_ellipsized" "$branch_full")
fi

if [ "$cols" -gt 0 ] && [ "$(line_len "$line")" -gt "$cols" ]; then
  line=$(single_line "$path_ellipsized" "$branch_stripped")
fi

if [ "$cols" -gt 0 ] && [ "$(line_len "$line")" -gt "$cols" ]; then
  line=$(single_line "$path_dironly" "$branch_stripped")
fi

# Last resort: nothing fits on one line even fully shortened - split across
# multiple lines instead of cutting any information off.
if [ "$cols" -gt 0 ] && [ "$(line_len "$line")" -gt "$cols" ]; then
  line=$(pack_lines "$(path_colored "$path_dironly")" "$(branch_colored "$branch_stripped")" "$model_str" "$ctx_str")
fi

printf '%s' "$line"
