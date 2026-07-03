---
name: split
description: Fork the current Claude Code session into a new Ghostty tab.
disable-model-invocation: true
model: haiku
argument-hint: [directive]
---

The fork has already been launched during preprocessing by the command below, which opened a new Ghostty tab running `claude --resume <this-session> --fork-session`. This session (the original) is untouched and keeps running; the fork inherits the full conversation history up to now and diverges in the new tab.

Result of launching the fork:

!`"${CLAUDE_SKILL_DIR}/split.sh" $ARGUMENTS`

Relay that one-line result to the user verbatim and do nothing else — no tools, no follow-up.
