---
name: open-pull-request
description: Push the current branch and create a GitHub pull request from an existing commit. Use when asked to open a PR or after a commit workflow has completed.
---

The user or caller may provide:
- whether the PR should be draft

- Always inspect the latest commit on the current branch.
- Always use that commit's title as the PR title and that commit's body as the PR body, even if the caller already knows or provides them beforehand.
- Push the branch with `git push -u origin HEAD`.
- Open the PR immediately after push.
- Use `gh pr create --title "..." --body "..."`.
- Add `--draft` only when the caller explicitly requested a draft PR.
- PR title must exactly match the commit title being used.
- PR body must exactly match the commit body being used.
- Print the PR URL at the end in Markdown link form so it is clickable.

- If `gh` is not authenticated, stop after the branch is pushed.
- Tell the user to authenticate with `gh auth login`.
- Tell the user to rerun only the PR creation step after authentication.
