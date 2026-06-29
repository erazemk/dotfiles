---
name: vsc
description: Open a directory in VS Code and bring it to the foreground — like `code .` plus activating the window. User-invoked only via /vsc [path].
disable-model-invocation: true
argument-hint: "[path]"
allowed-tools: Bash(code:*), Bash(open:*)
---

Opened in VS Code:
!`d="$ARGUMENTS"; code "${d:-.}" && open -a "Visual Studio Code" && pwd`
