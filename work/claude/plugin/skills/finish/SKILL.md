---
name: finish
description: Finish feature work end-to-end — verify the build, create or resolve a DevRev issue, commit, push, open a PR, and move the issue to in_review. Use when the user explicitly runs /finish to wrap up the current changes.
argument-hint: "[devrev-issue-url]"
---

Arguments: $ARGUMENTS

Finish the current code changes.
Follow this workflow exactly.

1. **Verify the build.**
   - If you or the user have not already run `make` in this conversation after the latest code changes, run it now from the repository root.
   - If `make` fails, stop and surface the failure.
   - If `make` already passed after the latest code changes in this conversation, do not run it again.

2. **Resolve or create the DevRev issue.**
   - Determine the existing DevRev issue, ticket, work ID, or work URL to use, in this order:
     1. If the arguments contain an existing DevRev reference, use it.
     2. Otherwise, if a single specific DevRev issue was established as the current relevant issue earlier in this conversation (e.g. the user gave its link so you could gather context from it), use that reference. Only do this when exactly one such issue is unambiguous — if several issues were mentioned and none is clearly *the* current one, treat it as no reference.
   - If an existing DevRev reference was resolved this way, skip issue creation and use that reference as the issue link for `commit`.
   - If no DevRev reference was provided or established:
     - Draft an exact issue title and description from the conversation context and verified changes.
     - Confirm them with the user using `AskUserQuestion` (show the proposed title and description; offer `Yes` / `No`). Do this here in the main context — the creation step cannot ask.
     - If the user does not approve, stop.
     - Once approved, use the `create-devrev-issue` skill, passing the confirmed exact title and exact description. That skill runs in a forked context, picks the part/sprint, creates the issue, and moves it through `in_development` to `in_review`.
   - If no DevRev issue link is produced, stop.

3. **Commit.**
   - Use the `commit` skill.
   - Pass the DevRev issue link and the arguments as context.
   - If the user declines the `commit` approval or no commit is created, stop.

4. **Open the pull request.**
   - Use the `pr` skill.
   - Pass the arguments as context to e.g. decide whether the PR should be a draft.
   - Do not ask for separate PR confirmation.
   - Print the PR URL at the end.
