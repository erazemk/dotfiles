#!/usr/bin/env bash
input=$(cat)

current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0 | floor | tostring')

git_branch=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch=" ($branch)"
    fi
fi

YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

if [ "$used_pct" -ge 90 ]; then
    ctx_str="[${RED}${used_pct}%${RESET}]"
elif [ "$used_pct" -ge 70 ]; then
    ctx_str="[${YELLOW}${used_pct}%${RESET}]"
else
    ctx_str="[${used_pct}%]"
fi

display_dir="${current_dir/#$HOME/~}"
echo -e "${display_dir}${git_branch} ${ctx_str}"
