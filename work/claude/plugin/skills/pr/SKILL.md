---
name: pr
description: Push the current branch and create a GitHub pull request from an existing commit. Use when asked to open a PR or after a commit workflow has completed.
allowed-tools: Bash(git push:*), Bash(git log:*), Bash(git branch:*), Bash(gh pr create:*), Bash(gh pr view:*), Bash(gh auth status:*), Bash(gh api:*), AskUserQuestion
---

The user or caller may provide:
- whether the PR should be draft

- NEVER hard-wrap the body at a fixed column width: a line break must only ever fall at the end of a paragraph, never in the middle of one (multiple sentences in a paragraph should all be on the same line).
- Separate paragraphs with a blank line. The PR body must match the amended commit body verbatim, so if the commit body was re-wrapped, re-read it before creating the PR.
- Always inspect the relevant commit on the current branch. When the branch has more than one new commit ahead of `main`, use the **first** new commit (the one carrying the structured title and the DevRev issue URL in its body); otherwise use the latest commit.
- Always use that commit's title as the PR title and that commit's body-only text as the PR body, even if the caller already knows or provides them beforehand.
- When reading the commit, extract the title and body separately so the PR body never includes the commit title line.
- If the caller provided a DevRev URL earlier in the workflow, preserve that exact URL verbatim through the commit body and therefore the PR body.
- Do not canonicalize a provided DevRev URL or replace it with a reconstructed URL from an issue ID or DON.
- If the commit body is empty, use the exact DevRev URL only when available.
- Push the branch with `git push -u origin HEAD`. This initial push is expected: creating the PR requires the branch to exist on the remote, and invoking this skill is the user's request to publish it.
- This auto-push applies **only** to this first push that opens the PR. Once a PR exists, do not push subsequent commits automatically — when you add fixes or updates to an already-open PR (e.g. addressing review feedback), always ask the user (via `AskUserQuestion`, `Yes`/`No`) whether to push the new commit(s) before running `git push`.
- Open the PR immediately after push.
- Use `gh pr create --title "..." --body "..."`.
- Add `--draft` only when the caller explicitly requested a draft PR.
- PR title must exactly match the commit title being used.
- PR body must exactly match the commit body-only text being used and must not repeat the title.
- After the PR is created, print the PR URL in Markdown format so it is clickable.

- If `gh` is not authenticated, stop after the branch is pushed.
- Tell the user to authenticate with `gh auth login`.
- Tell the user to rerun only the PR creation step after authentication.

## Resolving review conversations

This is a separate action from creating a PR. Only do it when the user **explicitly** asks you to resolve the comments/conversations you fixed (e.g. "resolve the comments you fixed", "mark the resolved ones as resolved"). Never resolve threads as part of the normal PR-creation flow, and never blanket-resolve every thread — resolve only the threads whose findings you actually addressed in code this session.

Steps:

1. List the review threads with their IDs, resolved state, and anchoring comment. Replace `<owner>`, `<repo>`, and `<number>` (get them from `gh pr view --json url` or the known PR):

    ```bash
    gh api graphql -f query='
    query {
      repository(owner: "<owner>", name: "<repo>") {
        pullRequest(number: <number>) {
          reviewThreads(first: 100) {
            nodes {
              id
              isResolved
              comments(first: 1) { nodes { path line body } }
            }
          }
        }
      }
    }'
    ```

2. Match each unresolved thread to the findings you actually fixed, using the comment's `path`, `line`, and `body`. Skip threads you did not fix, threads already `isResolved: true`, and the top-level review summary comment (it is not a resolvable thread). If a thread is ambiguous or you are unsure you fixed it, leave it unresolved and say so.

3. Resolve each matched thread by its node ID (`PRRT_...`):

    ```bash
    gh api graphql -f query='
    mutation {
      resolveReviewThread(input: {threadId: "<THREAD_ID>"}) {
        thread { id isResolved }
      }
    }'
    ```

4. Report which threads you resolved and which you deliberately left unresolved (and why), so the user can see the mapping between fixes and resolved conversations.
