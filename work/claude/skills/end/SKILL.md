---
name: end
description: Clean up a finished git worktree — switch back to the main repo root and delete the worktree. Use when the user types /end (with or without a branch name) to remove a worktree they no longer need.
argument-hint: "[branch-regex]"
allowed-tools: Bash(git worktree:*), Bash(git rev-parse:*), ExitWorktree, AskUserQuestion
disable-model-invocation: true
---

# End — remove a git worktree

## Context

Current working directory:
!`pwd`

All worktrees in this repo:
!`git worktree list`

Argument passed by user: $ARGUMENTS

## Step 1 — identify the target worktree

- If `$ARGUMENTS` is non-empty, treat it as a substring/regex and match it against the branch names
  in the worktree list above (partial matches are fine — e.g. `unresolved-references` matches
  `erazemk/backfill-unresolved-references`).
- If `$ARGUMENTS` is empty, the target is the worktree whose path matches the current working
  directory shown above. If the current directory is the main worktree (not a `.worktrees/`
  path), stop and tell the user there is no worktree to clean up here.

If more than one non-main worktree matches the argument, use `AskUserQuestion` to let the user
pick one. Show the full path and branch for each candidate.

The main worktree (no `.worktrees/` in its path) is never a valid target — never offer or select it.

Once the target is identified, note its **path** and **branch** from the worktree list.

## Step 2 — exit the worktree session if needed

If the current working directory is inside the target worktree (i.e. `pwd` starts with the target
path), call `ExitWorktree({action: "keep"})` first to return to the repo root. This is required
before deletion — do not skip it.

If the current directory is already outside the target worktree (e.g. we're cleaning up a
different worktree from the main root), skip this step.

## Step 3 — remove the worktree

Run:

```sh
git worktree remove "<path>"
```

where `<path>` is the target worktree path.

If this fails because the worktree has uncommitted changes, stop and ask the user:

> The worktree at `<path>` has uncommitted changes. Force-delete anyway (all unsaved work will
> be lost), or cancel?

Present two options: **Force delete** and **Cancel**. If they choose force delete, run:

```sh
git worktree remove --force "<path>"
```

## Step 4 — confirm

Print a single line: the branch name and path that were removed.
Do not offer to delete the remote branch or do anything else unless the user asks.
