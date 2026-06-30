---
name: commit
description: Inspect current git changes, draft a commit message, require approval, and create the commit safely. Use when asked to commit changes or when a workflow needs a structured commit step.
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git branch:*), Bash(git checkout:*), Bash(git switch:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), AskUserQuestion
---

The caller must provide a DevRev issue URL to append to the commit body.
If the caller provides a DevRev URL, use that exact URL verbatim everywhere.
Do not canonicalize it, normalize it, reconstruct it from an issue ID, or replace it with another URL format.

Prefer the existing conversation context when drafting the branch name, commit title, and commit body.
The current git state is captured below; use it as the primary input and only re-inspect with git tools if it is truncated or you need more detail (e.g. a full diff of a specific file).

## Current git state

Branch prefix:
!`id -un`

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
- if the DevRev issue URL is missing, stop and ask for it
- exclude likely secrets such as `.env`, credentials, private keys, or token files unless the user explicitly confirms

## Branch rules

- check the current branch
- if it is `main`, create and switch to `<prefix>/<1-4-words-about-the-change>`, where `<prefix>` is the branch prefix captured above
- use lowercase kebab-case derived from the behavioral change
- do not include the DevRev issue ID
- if the branch is not `main`, stay on it
- do not use destructive git commands

## Commit format

- title: `<prefix>: <Short sentence, first letter capitalized>`
- allowed prefixes: `fix`, `feat`, `chore`, `docs`, `ci`
- use imperative voice and do not end the title with a period
- body must end with the exact DevRev URL provided by the caller
- simple commits should use only that exact DevRev URL as the body
- do not repeat or paraphrase the commit title in the body
- complex commits may include short paragraphs before the issue URL only when the extra context is genuinely needed
- the opening sentence must start with `This commit ...`
- use present tense and `we`

## Before committing

- print the proposed commit title and body before asking for approval
- show the proposed commit title and body
- use the `AskUserQuestion` tool for approval
- ask whether the commit title and description are okay
- provide exactly `Yes` and `No`
- if approval is not granted through `AskUserQuestion`, stop

## If approved

- if changes are already staged, commit only the staged changes
- if nothing is staged, stage all safe changes with `git add -A`
- create the commit using a heredoc
- do not amend an existing commit
- if `git commit` fails because a hook reformats or updates files, stage those changes and create a new commit with the approved message
- if `git commit` fails for any other reason, surface the error and stop

After a successful commit, return the commit title, body, hash, branch name, whether staged-only or all safe changes were committed, and whether hook-generated changes had to be staged and recommitted.
