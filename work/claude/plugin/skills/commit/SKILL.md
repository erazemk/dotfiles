---
name: commit
description: Inspect current git changes, draft a commit message, require approval, and create the commit safely. Use when asked to commit changes or when a workflow needs a structured commit step.
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git branch:*), Bash(git checkout:*), Bash(git switch:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), AskUserQuestion
---

This skill only performs the commit step. It assumes the caller already ran the rest of the wrap-up process — verifying the build and resolving/creating the DevRev issue — per the `finish` skill.
If you (the agent) have not already run the full `finish` flow in this conversation, read the `finish` skill first and follow it from the top, rather than invoking `commit` in isolation and reinventing pieces of that flow (e.g. asking the user ad hoc questions this skill has no answer for).
Only proceed straight to the steps below when `finish` has already been followed, or when the caller explicitly wants just the commit step in isolation (e.g. a follow-up commit on an already-open PR).

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
- if the DevRev issue URL is missing, this is a sign `finish` was not followed — go read it and resolve/create the issue per its process (including via `create-devrev-issue`) rather than asking the user directly. Only ask the user directly if `finish`'s own resolution step says to stop and ask (e.g. they decline to approve a drafted title/description).
- exclude likely secrets such as `.env`, credentials, private keys, or token files unless the user explicitly confirms

## Branch rules

- check the current branch
- if it is `main`, create and switch to `<prefix>/<1-4-words-about-the-change>`, where `<prefix>` is the branch prefix captured above
- use lowercase kebab-case derived from the behavioral change
- do not include the DevRev issue ID
- if the branch is not `main`, stay on it
- do not use destructive git commands

## Commit format

The required format depends on whether this is the first commit on the branch (i.e. nothing has been pushed yet) or a follow-up commit on an already-pushed branch.

### First commit (branch not yet pushed to origin)

This commit's title and body become the basis for the PR title and description, so they must follow the full convention:

- title: `<prefix>: <Short sentence, first letter capitalized>`
- allowed prefixes: `fix`, `feat`, `chore`, `docs`, `ci`
- use imperative voice and do not end the title with a period
- body must end with the exact DevRev URL provided by the caller
- simple commits should use only that exact DevRev URL as the body
- do not repeat or paraphrase the commit title in the body
- complex commits may include short paragraphs before the issue URL only when the extra context is genuinely needed
- the opening sentence must start with `This commit ...`, and if a second sentence is needed, start it with `The commit also ...`
- use present tense
- avoid personal pronouns (`I`, `we`, `our`, `my`) entirely
- avoid vague referents like `it`, `this`, `that` — name the actual service, function, file, or person explicitly instead
- NEVER hard-wrap the body at a fixed column width: a line break must only ever fall at the end of a paragraph, never in the middle of one (multiple sentences in a paragraph should all be on the same line).
- Separate paragraphs with a blank line. The PR body must match the amended commit body verbatim, so if the commit body was re-wrapped, re-read it before creating the PR.

### Follow-up commits (branch already pushed to origin)

The PR title and description are already set; these commits are squashed on merge, so only a short summary title is needed:

- title only, no body required
- still use a valid prefix and imperative voice
- skip the `AskUserQuestion` approval step — create the commit immediately
- do **not** push the follow-up commit automatically. Creating the commit and pushing it are separate steps: after committing, ask the user (via `AskUserQuestion`, `Yes`/`No`) whether to push the new commit(s) to the PR, and only run `git push` if they approve. This applies to every follow-up commit, including fixes made in response to review feedback.
- never squash, rebase, amend, or force-push to tidy up branch history. The repo's enforced merge strategy squashes all commits into one on merge, so intermediate commits never reach `main` — a messy branch history is expected and requires no cleanup.

## Before committing (first commit only)

- print the proposed commit title and body before asking for approval
- show the proposed commit title and body
- use the `AskUserQuestion` tool for approval
- ask whether the commit title and description are okay
- provide exactly `Yes` and `No`
- if approval is not granted through `AskUserQuestion`, stop
- if the response is not a plain `Yes` (e.g. the user requests a change to the title or body, via `No` with a note or free text), do not treat that as approval and do not commit with the revised message yet — revise the draft accordingly and go through the `AskUserQuestion` approval step again with the new version. Repeat until the user approves a version with a plain `Yes`.

## If approved

- if changes are already staged, commit only the staged changes
- if nothing is staged, stage all safe changes with `git add -A`
- create the commit using a heredoc
- do not amend an existing commit
- if `git commit` fails because a hook reformats or updates files, stage those changes and create a new commit with the approved message
- if `git commit` fails for any other reason, surface the error and stop

After a successful commit, return the commit title, body, hash, branch name, whether staged-only or all safe changes were committed, and whether hook-generated changes had to be staged and recommitted.
