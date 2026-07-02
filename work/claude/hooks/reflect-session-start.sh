#!/usr/bin/env bash
# SessionStart hook: offer to reflect on the previous session in this project.
#
# Finds the most recent prior transcript for the current project, skips trivial
# or already-offered ones, and (if a candidate exists) injects context telling
# the agent to have a subagent judge whether that session is worth reflecting on
# and, if so, summarize it and offer to run the `reflect` skill.
#
# Reads the hook JSON payload on stdin; emits SessionStart additionalContext on stdout.
# Stays silent (exit 0, no output) when there is nothing worth offering.

set -euo pipefail

# --- tunables ---------------------------------------------------------------
MIN_BYTES=20000          # skip transcripts smaller than this (trivial sessions)
# ---------------------------------------------------------------------------

payload="$(cat)"

# cwd is provided in the hook payload; fall back to PWD.
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty')"
[ -z "$cwd" ] && cwd="$PWD"

current_session="$(printf '%s' "$payload" | jq -r '.session_id // empty')"
source="$(printf '%s' "$payload" | jq -r '.source // empty')"

# Only offer on a genuinely new session, not on resume/clear/compact restarts.
case "$source" in
  startup) ;;
  *) exit 0 ;;
esac

# Derive the project transcript dir the same way Claude Code does: the absolute
# project path with every character that is not alphanumeric replaced by '-'.
slug="$(printf '%s' "$cwd" | sed 's/[^a-zA-Z0-9]/-/g')"
proj_dir="$HOME/.claude/projects/$slug"
[ -d "$proj_dir" ] || exit 0

# Most recent transcript that is not the current session.
prev=""
while IFS= read -r f; do
  base="$(basename "$f" .jsonl)"
  [ "$base" = "$current_session" ] && continue
  prev="$f"
  break
done < <(ls -t "$proj_dir"/*.jsonl 2>/dev/null || true)

[ -z "$prev" ] && exit 0

# Skip trivial sessions.
size="$(wc -c < "$prev" | tr -d ' ')"
[ "$size" -lt "$MIN_BYTES" ] && exit 0

# Only offer each prior transcript once.
marker_dir="$HOME/.claude/.reflect-offered"
mkdir -p "$marker_dir"
marker="$marker_dir/$(basename "$prev" .jsonl)"
[ -f "$marker" ] && exit 0
: > "$marker"

ctx="A previous Claude Code session in this project may be worth reflecting on.

Transcript: $prev

On your FIRST action this session, before anything else, spawn an Explore (or general-purpose) subagent to read that transcript and decide whether it is worth a reflection pass. The subagent should return: (1) a verdict — is there durable, reusable learning worth consolidating (user corrections, repeated searches, forgotten instructions, hard-won project facts, contradictions to fix)? Pure status/ticket/PR/debug-path chatter is NOT worth it; (2) if yes, a 2-4 sentence summary of what the session was about so the user can recall it; (3) the top candidate learnings.

If the verdict is NOT worth it, stay silent — do not mention this to the user at all; just proceed with whatever they ask.

If it IS worth it, show the user the short summary and the candidate learnings, then use AskUserQuestion to ask whether to run a reflection pass now (offer Yes / No / Not this session). On Yes, invoke the reflect skill immediately. On No or Not this session, drop it and proceed."

jq -n --arg ctx "$ctx" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
