---
name: worktree
description: Manage DevRev git worktrees. Use before making code changes on a `main` branch in ~/DevRev, or whenever the user asks for worktree-related work.
---

These instructions only apply if you are starting new work, with no previous work being done by the user on this change in the current branch.
If there is prior work done by the user and the user instructs you to update it or add to it, do not create a separate worktree and remain on the existing branch.

Create a git worktree following the naming convention below.
If you're already not on a `main` branch and the user has not explicitly asked you to switch to a different worktree, then just stop, you can make code changes here.

# Branch name

- Use `erazemk/<words>`, where `<words>` is 1-4 short words in lowercase kebab-case derived from the conversation (e.g. `<prefix>/fix-attachment-retry`).
- Don't use the DevRev issue ID in the branch name.
- Branch name is not a proper sentence, it doesn't need prepositions or other filler words.
- If there is not enough information in the conversation to derive the name, ask the user for it.

# Worktree path

- The user primarily uses VSCode for code editing and review, so use the same worktree path rules: `../<repo-name>.worktrees/<words>`.
- E.g., if the repo is `~/DevRev/airdrop-devrev-loader`, then the worktrees should go in `~/DevRev/airdrop-devrev-loader.worktrees/`.
- The worktree path shouldn't include the `erazemk` prefix, only the `<words>`.

# Create the branch

New worktrees should almost always be based off of `origin/main`.
Only when the user explicitly gives you a branch name to base the worktree off of, you should use it instead of `origin/main`.

1. Run `git fetch origin main`.
2. Create the worktree with `git worktree add --no-track -b erazemk/<words> <path> origin/main`.

The branch has no upstream after creation.
Its first push must use `git push --set-upstream origin erazemk/<words>`.

In case of an issue at any of the steps, stop, and report the issue to the user.
