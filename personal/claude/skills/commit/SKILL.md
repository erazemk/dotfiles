---
name: commit
description: Inspect current git changes, draft a commit message, require approval, commit, and offer to push. Use when asked to commit or push changes.
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git push:*), AskUserQuestion
---

Prefer the existing conversation context when drafting the commit message.
The current git state is captured below; use it as the primary input and only re-inspect with git tools if it is truncated or you need more detail (e.g. a full diff of a specific file).

## Current git state

Branch:
!`git branch --show-current`

Status (short):
!`git status --short`

Staged diff:
!`git diff --staged`

Unstaged diff:
!`git diff`

## Inspection rules

- if staged changes exist, use the staged diff above
- if nothing is staged, use the unstaged diff above
- if both staged and unstaged changes exist, consider both, but commit only the staged changes unless the caller explicitly asked to include unstaged changes
- if there are no staged or unstaged changes, stop and say there is nothing to commit
- exclude likely secrets such as `.env`, credentials, private keys, or token files unless the user explicitly confirms

## Commit format

- title: `<prefix>: <Short sentence, first letter capitalized>`
- allowed prefixes: `fix`, `feat`, `chore`, `docs`, `ci`
- use imperative voice and do not end the title with a period
- simple commits need only the title, no body required
- complex commits may include a short body only when extra context is genuinely needed
- if a body is written, the opening sentence must start with `This commit ...`
- use present tense and `we`
- wrap body lines at 72 characters
- separate paragraphs with a blank line

## Before committing

- show the proposed commit title and body
- use the `AskUserQuestion` tool for approval
- ask whether the commit message is okay
- provide exactly `Yes` and `No`
- if approval is not granted through `AskUserQuestion`, stop

## If approved

- if changes are already staged, commit only the staged changes
- if nothing is staged, stage all safe changes with `git add -A`
- create the commit using a heredoc
- do not amend an existing commit
- if `git commit` fails because a hook reformats or updates files, stage those changes and create a new commit with the approved message
- if `git commit` fails for any other reason, surface the error and stop

## After committing

After a successful commit, always ask the user (via `AskUserQuestion`, `Yes`/`No`) whether to push to the remote before running `git push`.
Only run `git push` if the user explicitly approves.
