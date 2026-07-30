---
name: worktree
description: Use this skill before making code changes on a `main` branch in a git repo in ~/DevRev, or when the user asks you to do something related to a git worktree.
---

Create a git worktree following the naming convention below, then switch this session into it.
If you're already not on a `main` branch and the user has not explicitly asked you to switch to a different worktree, then just stop, you can make code changes here.

# Branch name

- Use `erazemk/<words>`, where `<words>` is 1-4 short words in lowercase kebab-case derived from the conversation (e.g. `<prefix>/fix-attachment-retry`).
- Don't use the DevRev issue ID in the branch name.
- Branch name is not a proper sentence, it doesn't need prepositions or other filler words.
- If there is not enough information in the conversation to derive the name, ask the user for it.

# Worktree path

- The user primarily uses VSCode for code editing and review, so use the same worktree path rules: `../<repo-name>.worktrees/<words>`.
- If the repo is `~/DevRev/airdrop-devrev-loader`, then the worktrees should go in `~/DevRev/airdrop-devrev-loader.worktrees/`.
- The worktree path shouldn't include the `erazemk` prefix, only the `<words>`.

# Base ref

- Always branch off of `origin/main` and always first fetch the latest changes (`git fetch origin main`).
- Only use a different base ref if the user explicitly says to (usually if basing changes on a non-yet-merged branch).

In case of an issue at any of the steps, stop, and report the issue to the user.

# Entering the worktree

You are not able to switch to a different worktree, but the user is, through the `/move` command. Once a worktree is created, tell the user to switch to it with "Switch to the new worktree with `/move $path"`.
Substitute $path with the absolute path (use ~ for home dir) of the worktree you've created.
