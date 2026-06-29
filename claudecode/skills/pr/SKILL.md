---
name: pr
description: Push the current branch and create a GitHub pull request from an existing commit. Use when asked to open a PR or after a commit workflow has completed.
allowed-tools: Bash(git push:*), Bash(git log:*), Bash(git branch:*), Bash(gh pr create:*), Bash(gh auth status:*)
---

The user or caller may provide:
- whether the PR should be draft

- Always inspect the relevant commit on the current branch. When the branch has more than one new commit ahead of `main`, use the **first** new commit (the one carrying the structured title and the DevRev issue URL in its body); otherwise use the latest commit.
- Always use that commit's title as the PR title and that commit's body-only text as the PR body, even if the caller already knows or provides them beforehand.
- When reading the commit, extract the title and body separately so the PR body never includes the commit title line.
- If the caller provided a DevRev URL earlier in the workflow, preserve that exact URL verbatim through the commit body and therefore the PR body.
- Do not canonicalize a provided DevRev URL or replace it with a reconstructed URL from an issue ID or DON.
- If the commit body is empty, use the exact DevRev URL only when available.
- Push the branch with `git push -u origin HEAD`.
- Open the PR immediately after push.
- Use `gh pr create --title "..." --body "..."`.
- Add `--draft` only when the caller explicitly requested a draft PR.
- PR title must exactly match the commit title being used.
- PR body must exactly match the commit body-only text being used and must not repeat the title.
- After the PR is created, print the PR URL in Markdown format so it is clickable.

- If `gh` is not authenticated, stop after the branch is pushed.
- Tell the user to authenticate with `gh auth login`.
- Tell the user to rerun only the PR creation step after authentication.
