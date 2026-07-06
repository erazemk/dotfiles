#!/usr/bin/env bash
# PreToolUse (Write|Edit|NotebookEdit): require a git worktree for edits under ~/DevRev.
#
# Editing files directly on a repo's deploy branch (main, or whatever origin/HEAD
# points to) risks polluting that checkout with in-progress work. The worktree skill
# creates an isolated `<repo>.worktrees/<branch>` checkout for feature work; this hook
# blocks the first Edit/Write/NotebookEdit on the deploy branch so that skill actually
# gets used instead of skipped.
set -u

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

input=$(cat 2>/dev/null) || exit 0
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
[ -n "$f" ] || exit 0

# Only guard repos under ~/DevRev.
case "$f" in
  "$HOME"/DevRev/*) ;;
  *) exit 0 ;;
esac

dir=$(dirname "$f")
repo_root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0

branch=$(git -C "$repo_root" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -n "$branch" ] && [ "$branch" != "HEAD" ] || exit 0

deploy_branch=$(git -C "$repo_root" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
deploy_branch=${deploy_branch#origin/}
[ -n "$deploy_branch" ] || deploy_branch="main"

if [ "$branch" = "$deploy_branch" ]; then
  deny "\`$deploy_branch\` is the deploy branch for this repo. Use the worktree skill to create a feature branch/worktree before editing."
fi

exit 0
