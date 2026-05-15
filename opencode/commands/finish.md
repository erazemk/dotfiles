---
description: Finish the current code changes by verifying, creating or resolving a DevRev issue, committing, pushing, and opening a PR
---

Arguments: $ARGUMENTS

Finish the current code changes.
Follow this workflow exactly.

- If you have not already run `make` in this conversation after the latest code changes, run it now from the repository root.
- If `make` fails, stop and surface the failure.
- If `make` already passed after the latest code changes in this conversation, do not run it again.
- Determine whether `$ARGUMENTS` contains an existing DevRev issue, ticket, work ID, or work URL.
- If an existing DevRev reference was provided, skip the `devrev` subagent and use that reference as the issue link for `git-commit`.
- If no DevRev reference was provided, draft an exact current-work issue title and description from the conversation context and verified changes.
- Use the `devrev` subagent only to create the issue.
- Pass only the operation, exact title, and exact description to the subagent.
- If no DevRev issue link is produced, stop.
- Use the `git-commit` skill second.
- Pass the DevRev issue link and `$ARGUMENTS` as context.
- If the user declines the `git-commit` approval or no commit is created, stop.
- Use the `open-pull-request` skill third.
- Pass `$ARGUMENTS` as context so the skill can decide whether the PR should be draft.
- Do not ask for separate PR confirmation.
- Print the PR URL at the end.
