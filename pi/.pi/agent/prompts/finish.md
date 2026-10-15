---
description: Verify work, resolve its issue, commit with any required approval, and publish through the repository's workflow
argument-hint: "[DevRev issue URL] [message or instructions]"
---

User arguments:
$ARGUMENTS

Finish only the current task's changes; preserve unrelated user work.
Load the commit skill and inspect Git remote ownership using its exact host/owner checks.
Resolve the intended destination and commit scope, including staged-only changes, before any mutations.
If there are no relevant changes and no partially completed finish workflow established in this conversation, stop instead of creating an issue or publishing unrelated work.
For partial-success recovery, identify the previously approved commit hash, message, issue and destination from established context; ask if any are uncertain.
Recheck the committed snapshot, outgoing scope, matching PR and current issue stage, then resume only missing publication/lifecycle steps without requiring another commit or recreating successful artifacts.
Prior approval remains usable only for that same verified commit, wording, scope and destination.
For DevRev repositories, inspect the actual base/head and matching PR state first; resolve closed/merged PRs and ambiguous outgoing work with the user before creating an issue or committing.

1. Run `make` from the repository root.
   Report what the default target actually does; if it only prints help, do not describe that as passing build/test checks.
   This check must cover the selected commit snapshot, not unstaged changes that will be excluded.
   If the checked working tree differs from that snapshot, rerun `make` against the actual committed snapshot before publication, using an isolated worktree or equivalent without disturbing unrelated work.
   Reuse a successful `make` run only if it covered this snapshot and no relevant code has changed since.
   Stop and report a failed or unavailable `make` run before committing or publishing.
2. For DevRev repositories, load the devrev skill.
   Reuse the exact issue URL supplied in arguments or unambiguously established for this task.
   Otherwise ask whether an existing issue exists; if no, follow the skill's enhancement selection, proposal, confirmation and creation steps.
   Print the newly created issue URL and continue automatically.
   Ensure the issue is In development before commit preparation, except an existing In review issue with a matching open PR should remain In review.
   Skip all DevRev issue operations for personal repositories.
3. Follow the commit skill, accepting a user-written message or drafting one from the task, diff and issue.
   For an initial DevRev commit, show the exact complete title/body and obtain approval before committing.
   For a follow-up commit on a matching open PR, use a short summary title; no message approval, body or issue URL is required.
   Let the user rewrite either field; never silently change final user wording.
   For an initial DevRev commit, state that message approval authorizes committing, pushing and opening the PR without separate publication confirmation.
   For a follow-up commit, pushing requires explicit user approval; a request to commit and push supplies that approval, but a request only to commit or finish does not.
   Stop if required approval is declined or no commit is created.
   If hooks change relevant code, rerun `make` against the actual committed snapshot before publishing.
4. Inspect all outgoing commits against the destination's current state before pushing.
   If they include unrelated work, ask for approval rather than publishing it implicitly.
   For DevRev repositories, follow the pr skill to open a draft PR using the approved commit's exact title/body.
   For an existing matching open PR, push the follow-up commit only after explicit approval to push, unless the user has already requested publication.
   Do not change the existing PR title/body.
   Personal repositories retain the existing workflow: stop after committing; do not load the pr skill, create a PR, or push automatically.
5. After successful DevRev PR creation or requested follow-up publication, use the devrev skill to transition the issue to In review.
   Do not treat a historical/pushed branch as an open PR.
   If the stage update fails after publication, report both URLs and the remaining step without recreating successful artifacts.

Report verification, exact committed title/body, hash, branch, issue URL, PR URL and stage, including anything left incomplete.
