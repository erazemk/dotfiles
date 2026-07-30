---
name: pr
description: Push the current branch and create a GitHub pull request from an existing commit. Use when asked to open a PR.
---

- PR titles and descriptions must exactly match the commit title and body, including keeping each paragraph on one line and preserving the DevRev issue URL verbatim.
- Always inspect the relevant commit on the current branch. When the branch has more than one new commit ahead of `main`, use the **first** new commit (the one carrying the structured title and the DevRev issue URL in its body); otherwise use the latest commit.
- When reading the commit, extract the title and body separately so the PR body never includes the commit title line.
- Auto-push the branch **only** on this first push that opens the PR. Once a PR exists, do not push subsequent commits automatically — when you add fixes or updates to an already-open PR (e.g. addressing review feedback), always ask the user if you should push the new commit(s).
- Open the PR immediately after push.
- Use `gh pr create --title "..." --body "..."`.
- Add `--draft` unless the caller explicitly asked to open the PR as ready for review.
- After the PR is created, print the PR URL in Markdown format so it is clickable.
- If `gh` is not authenticated, authenticate with `gh auth login` and retry the PR creation step. If authentication fails, stop and report the failure.
