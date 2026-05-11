---
description: Finish the current code changes by verifying, creating or resolving a DevRev issue, committing, pushing, and opening a PR
---

Arguments: $ARGUMENTS
Current date (UTC): !`date -u +%Y-%m-%d`
Current branch: !`git branch --show-current`
Git status: !`git status --short`
Staged diff stat: !`git diff --staged --stat`
Unstaged diff stat: !`git diff --stat`

Finish the current code changes.
Follow this workflow exactly.

## Verification

- If you have not already run `make FIX=true FORCE=true` in this conversation after the latest code changes, run it now before any other step.
- Run it from the repository root.
- If it fails, stop and surface the failure.
- Do not create or update the DevRev issue, commit, push, or open a PR until it passes.
- If you already ran it after the latest code changes in this conversation, do not run it again.

## Workflow

- Use the `devrev` skill first.
- Pass `$ARGUMENTS`, the current date, branch, git status, and diff stats as context.
- Resolve any existing DevRev issue reference from `$ARGUMENTS`, or create a current-work tracking issue if none was provided.
- Prefer the existing conversation context for the current work, and only inspect git state if more context is needed.
- If no DevRev issue link is produced, stop.

- Use the `git-commit` skill second.
- Pass the DevRev issue link and `$ARGUMENTS` as context.
- Prefer the existing conversation context for the commit message, and only inspect git state if more context is needed.
- If the user declines the `git-commit` skill approval or no commit is created, stop.

- Use the `open-pull-request` skill third.
- Pass `$ARGUMENTS` as context so the skill can decide whether the PR should be draft.
- Do not ask for separate PR confirmation.
- Print the PR URL at the end.
