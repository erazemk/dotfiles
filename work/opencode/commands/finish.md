---
description: Finish feature work end-to-end
---

Arguments: $ARGUMENTS

Finish the current code changes.
Follow this workflow exactly.

1. **Verify the build**
   - Run bare `make` from the repository root.
   - If `make` fails, stop and surface the failure.
   - If bare `make` already passed after the latest code changes in this conversation, do not run it again. But running only `make test` or `make vet` is not enough.

2. **Resolve or create the DevRev issue**
   - Determine the existing DevRev issue, ticket, work ID, or work URL to use, in this order:
     1. If the arguments contain an existing DevRev issue URL, use it.
     2. Otherwise, if a single specific DevRev issue was established as the current relevant issue earlier in this conversation (e.g. the user gave its link so you could gather context from it), use that reference. Only do this when exactly one such issue is unambiguous — if several issues were mentioned and none is clearly *the* current one, treat it as no reference.
   - If an existing DevRev reference was resolved this way, skip issue creation
   - If no DevRev reference was provided or established:
     - Draft a title and description based on the conversation, focus on what benefits/high-level changes the code changes are making, don't mention specific files or variables.
     - Show the proposed title and description to the user and ask them to approve them.
     - If the user does not approve, stop.
     - If the user approves, tell the `devrev` subagent to create the issue with the title and description you agreed on with the user.
   - If no DevRev issue link is produced, stop.

3. **Commit**
   - Use the `commit` skill.
   - If the user declines the `commit` approval or no commit is created, stop.

4. **Open the pull request**
   - Use the `pr` skill.
   - Do not ask for separate PR confirmation.
   - Print the PR URL at the end.
