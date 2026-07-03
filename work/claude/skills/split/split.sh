#!/usr/bin/env bash
# split.sh — fork the current Claude Code session into a NEW Ghostty tab.
#
# Invoked by the /split skill via dynamic-context injection, so it runs during
# skill preprocessing (before the model turn). Forks from the current on-disk
# tip via `claude --resume <id> --fork-session`, so the original session (the
# tab you ran /split from) is never modified and keeps running. The fork boots
# in a new tab of the front Ghostty window.
#
# Usage:
#   split.sh                 fork and wait for input in the new tab
#   split.sh <directive...>  fork and send the directive as the fork's first
#                            prompt (all arguments are joined)
#
# Reads CLAUDE_CODE_SESSION_ID from the environment (set inside Claude Code).
# Requires Ghostty on macOS with macos-applescript = true.

set -euo pipefail

sid="${CLAUDE_CODE_SESSION_ID:-}"
if [[ -z "$sid" ]]; then
  echo "split: CLAUDE_CODE_SESSION_ID is not set — not inside a Claude Code session." >&2
  exit 1
fi

# The fork must launch from the same directory so `--resume` can locate the
# session file under this project's slug.
cwd="$(pwd)"

# Build the fork command. Any directive is passed as a single positional prompt
# so the forked session submits it on boot; with none, the tab just waits.
# `printf %q` shell-escapes the prompt safely.
directive="$*"
if [[ -n "$directive" ]]; then
  cmd="claude --resume ${sid} --fork-session $(printf %q "$directive")"
else
  cmd="claude --resume ${sid} --fork-session"
fi

# Escape for embedding in AppleScript string literals: backslash then quote.
esc() { local s="${1//\\/\\\\}"; printf '%s' "${s//\"/\\\"}"; }
as_cmd="$(esc "$cmd")"
as_cwd="$(esc "$cwd")"

# Feed the command as typed input to a fresh login shell (full PATH), rather than
# exec'ing it directly, so `claude` resolves on PATH. `new tab in front window`
# lands the fork in the current window as a tab, leaving this session in place.
osascript <<APPLESCRIPT
tell application "Ghostty"
  set cfg to new surface configuration
  set initial working directory of cfg to "${as_cwd}"
  set initial input of cfg to "${as_cmd}" & linefeed
  new tab in front window with configuration cfg
end tell
APPLESCRIPT

if [[ -n "$directive" ]]; then
  echo "✓ split: forked session ${sid} into a new tab with a directive — this session is untouched."
else
  echo "✓ split: forked session ${sid} into a new tab — this session is untouched."
fi
