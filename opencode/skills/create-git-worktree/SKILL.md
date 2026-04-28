---
name: create-git-worktree
description: Create a new git worktree. Use whenever you will start writing code on a branch that already has unrelated code changes (excluding documentation), or when asked to by the user.
---

The user may provide:
- A short branch name - optional
- A short feature description - optional

### Behavior

- Always create the new worktree from the local `main` branch, even if a different branch is currently checked out.
- Determine `shortBranchName` from the user request.
- `shortBranchName` must be:
  - 1-4 words
  - lowercase
  - words separated by dashes
  - descriptive of the feature or task
- The git branch name must be:
  - `$(git config user.username)/<shortBranchName>`
- The worktree directory must be:
  - `$PWD.worktrees/<shortBranchName>`
- If `git config user.username` is empty or `shortBranchName` cannot be inferred confidently, ask one short question before continuing.

### Command

After determining `shortBranchName`, use this exact command shape:

```bash
mkdir -p "$PWD.worktrees" && git worktree add "$PWD.worktrees/<shortBranchName>" -b "$(git config user.username)/<shortBranchName>" main
```

Replace `<shortBranchName>` with the inferred short branch name.

### Steps

1. Determine `shortBranchName` from the user's request.
2. Run the command above with the chosen `shortBranchName`.
3. Report back:
   - the branch name
   - the full worktree path
   - that it was created from `main`

### Notes

- Minimize tool calls: do not do separate exploratory git commands if the branch name is already clear.
- Let `git worktree add` fail naturally if the branch already exists or the target path is already in use, then report the error.
- Do not create a commit or a PR as part of this skill.
- Do not copy files into the new worktree unless the user explicitly asks.

### Example

If the user says:

```text
Create a new git worktree for redis locking
```

and `git config user.username` returns `erazemk`, use:

```bash
mkdir -p "$PWD.worktrees" && git worktree add "$PWD.worktrees/redis-locking" -b "$(git config user.username)/redis-locking" main
```

This creates:

- branch: `erazemk/redis-locking`
- path: `$PWD.worktrees/redis-locking`
