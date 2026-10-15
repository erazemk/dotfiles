---
name: worktree
description: Choose or create a Git worktree before code changes in ~/Code, or manage worktrees when requested.
---

# Choose the workspace

Apply these rules to Git repositories under `~/Code`, including their worktrees.
Honor an explicit request to use or create a particular worktree.
Otherwise:

- Reuse the current branch if it has existing work for the issue being solved, even on `main`.
- Reuse a non-`main` branch with no existing changes.
- For new work on `main`, or on any branch with only unrelated changes, create a new worktree from `origin/main`.

Inspect the working tree, staged changes, and relevant branch commits before classifying existing work.
A clean working tree may still have related or unrelated committed work.
Preserve unrelated user changes and staged state; do not move or stash them into the new worktree.
If the relationship to the current task is unclear, ask before choosing a workspace.

# Branch and path

- Name new branches `erazemk/<words>`.
- Use 1–4 short lowercase kebab-case words derived from the task, without issue IDs or filler words.
- If the task does not provide enough context for a name, ask the user.
- Create worktrees at `~/Code/worktrees/<project-name>/<words>/<project-name>` to match Zed.
- Use only the suffix after the branch name's final `/` in the path, never the `erazemk/` prefix.

Example:

```text
Branch: erazemk/dependency-update
Path: ~/Code/worktrees/marina/dependency-update/marina
```

# Create the worktree

1. Run `git fetch origin main` from the repository.
2. Create the destination's parent directories.
3. Run `git worktree add --no-track -b erazemk/<words> <path> origin/main`.
4. Verify the worktree path, branch name, and absence of an upstream before editing.

Always base new worktrees on the freshly fetched `origin/main`, not local `main` or the current branch.
Use `--no-track` so the new branch does not track `origin/main`.
Its first push must use `git push --set-upstream origin erazemk/<words>`.

Stop and report failures rather than silently changing the base, branch, path, or overwriting an existing worktree.
