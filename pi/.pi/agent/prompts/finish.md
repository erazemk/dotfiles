---
description: Verify current work, commit it, and publish through the repository's workflow
---

$ARGUMENTS

Finish only the current task's changes; preserve unrelated user work.

1. Identify repository conventions and the intended commit scope, including whether staged-only changes will be committed.
   - Run the appropriate build/test verification.
   - Reuse a successful verification only if it covered that snapshot and no relevant code has changed since.
   - Stop and report a failure or unavailable required verification before committing or publishing.
2. Inspect Git remote ownership using the commit skill's rules.
   - For DevRev repositories, use an exact issue URL supplied in the arguments or unambiguously established for this task in the conversation.
   - If it is missing or ambiguous, ask for the URL and stop until it is supplied.
   - Skip issue handling entirely for personal repositories.
3. Follow the commit skill.
   - Stop if approval is declined or no commit is created.
   - If hooks changed relevant code, rerun required verification against the resulting committed snapshot before publishing.
4. For DevRev repositories, follow the pr skill to open a draft PR, or ask before pushing follow-up commits to an open PR unless that push was explicitly requested.
   - For personal repositories, do not load the pr skill or create a PR, instead just stop.
   - Inspect all outgoing commits against the destination's current state before pushing; if they include unrelated work, ask for approval rather than publishing it implicitly.

Report verification, commit, and publication results, including anything left incomplete.
