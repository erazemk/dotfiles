---
name: git-commit
description: Inspect current git changes, draft a commit message, require question-tool approval, and create the commit safely. Use when asked to commit changes or when a workflow needs a structured commit step.
---

The caller must provide a DevRev issue link to append to the commit body.

Prefer the existing conversation context when drafting the branch name, commit title, and commit body.
Inspect git state only when more context is needed.

Inspection rules:
- if staged changes exist, inspect `git diff --staged`
- if nothing is staged, inspect `git diff`
- if both staged and unstaged changes exist, inspect both, but commit only the staged changes unless the caller explicitly asked to include unstaged changes
- if there are no staged or unstaged changes, stop and say there is nothing to commit
- if the DevRev issue link is missing, stop and ask for it
- exclude likely secrets such as `.env`, credentials, private keys, or token files unless the user explicitly confirms

Branch rules:
- check the current branch
- if it is `main`, create and switch to `erazemk/<1-4-words-about-the-change>`
- use lowercase kebab-case derived from the behavioral change
- do not include the DevRev issue ID
- if the branch is not `main`, stay on it
- do not use destructive git commands

Commit format:
- title: `<prefix>: <Short sentence, first letter capitalized>`
- allowed prefixes: `fix`, `feat`, `chore`, `docs`, `ci`
- use imperative voice and do not end the title with a period
- body must end with the raw DevRev issue URL
- simple commits may use only the raw issue URL as the body
- complex commits may include short paragraphs before the issue URL
- the opening sentence must start with `This commit ...`
- use present tense and `we`

Before committing:
- show the proposed commit title and body
- use the `question` tool for approval
- ask whether the commit title and description are okay
- provide exactly `Yes` and `No`
- if approval is not granted through `question`, stop

If approved:
- if changes are already staged, commit only the staged changes
- if nothing is staged, stage all safe changes with `git add -A`
- create the commit using a heredoc
- do not amend an existing commit
- if `git commit` fails because a hook reformats or updates files, stage those changes and create a new commit with the approved message
- if `git commit` fails for any other reason, surface the error and stop

After a successful commit, return the commit title, body, hash, branch name, whether staged-only or all safe changes were committed, and whether hook-generated changes had to be staged and recommitted.
