---
name: worktree
description: Create a git worktree following a VS Code-style convention and switch the session into it. Branch <prefix>/<1-4-kebab-words>, worktree at <repo-root>.worktrees/<trimmed-branch>, branched fresh from the remote default branch. Use when asked to start/create/use a worktree, or via /worktree [branch] [instructions...]. The first word is the branch name; any words after it are instructions to carry out once inside the new worktree.
argument-hint: "[branch] [instructions...]"
arguments: [branch]
allowed-tools: Bash(git worktree:*), Bash(git fetch:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git show-ref:*), Bash(git symbolic-ref:*), EnterWorktree, AskUserQuestion
---

# Create and enter a git worktree

Create a git worktree following the naming convention below, then switch this session
into it. **Be fast: exactly two tool calls** — one prepared Bash command that does all
the work in-shell, then one `EnterWorktree`. Do not run any exploratory commands first
(no separate `git rev-parse`, `git worktree list`, etc.) and do not narrate the steps.

## Argument parsing

The full argument string is: $ARGUMENTS

The harness also extracts the first token into `$branch` (declared in the `arguments`
frontmatter). The grammar is `<branch> [instructions...]`:

- **`$branch`** (the first token) → the branch name, for steps 1-3.
- **Everything after the first token** → free-form instructions to carry out once inside
  the new worktree (step 4).

The four supported invocation shapes:

1. **Nothing** (`$ARGUMENTS` empty) → no branch given. Derive one from context, or stop
   and ask (see step 1). No follow-up instructions.
2. **Branch only** (`$ARGUMENTS` is a single token) → use `$branch`. No follow-up
   instructions; confirm and stop after step 3.
3. **Branch + instructions** (`$ARGUMENTS` is a token followed by more text) → use
   `$branch`, then carry out the trailing text in step 4.

Note: "instructions only / no branch" is **not** a supported shape. The first token is
always treated as the branch name. If the user wants a guessed branch, they pass no
arguments (shape 1) and describe the work in conversation, not as `/worktree` arguments.

Example: `/worktree attachment-retry implement the plan in PLAN.md` → `$branch` is
`attachment-retry`, and after entering the worktree you execute "implement the plan in
PLAN.md".

## Conventions

- **Branch**: `<prefix>/<words>`, where `<prefix>` is the branch prefix and `<words>`
  is 1-4 short words in lowercase kebab-case derived from the change (e.g.
  `<prefix>/fix-attachment-retry`), no DevRev issue ID. The script in step 2 resolves
  `<prefix>` in-shell — you never substitute it by hand.
- **Worktree path**: `<repo-root>.worktrees/<words>` — the current repo root path with
  `.worktrees/<words>` appended (the `<prefix>/` prefix is omitted from the path).
- **Base ref**: branch fresh from the remote default branch (e.g. `origin/main`),
  resolved dynamically so it works in any repo.

## Step 1 — pick the branch words

- If `$branch` is non-empty (shapes 2 and 3), use it as the branch name, converted to
  1-4 lowercase kebab-case words. It is a single token, so anything after it in
  `$ARGUMENTS` is follow-up instructions for step 4, never part of the branch name.
- Else (shape 1, no arguments) if the current task or uncommitted changes clearly imply
  a name, derive 1-4 lowercase kebab-case words (no DevRev issue ID).
- Else (conversation just started, no clear change) **stop and ask** the user for words
  — do not guess. Tell them to run e.g. `/worktree fix-attachment-retry`.

## Step 2 — run this one command, substituting only `WORDS`

Everything else (repo root, default branch, path, existence checks, fetch, create vs.
reuse) is resolved in-shell. Set `WORDS` to the chosen words and run it as-is. It prints
the worktree path on the last line.

```sh
WORDS="fix-attachment-retry"  # <-- substitute the chosen words; this is the ONLY edit
PREFIX="$(id -un)"
BRANCH="$PREFIX/$WORDS"
WT_PATH="$(git rev-parse --show-toplevel).worktrees/$WORDS"
if git worktree list --porcelain | grep -qxF "worktree $WT_PATH"; then
  :  # already a registered worktree — just enter it
elif [ -e "$WT_PATH" ]; then
  echo "CONFLICT: $WT_PATH exists but is not a registered worktree" >&2; exit 1
elif git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git fetch origin --quiet; git worktree add "$WT_PATH" "$BRANCH"        # reuse branch
else
  git fetch origin --quiet
  git worktree add -b "$BRANCH" "$WT_PATH" "$(git symbolic-ref --short refs/remotes/origin/HEAD)"
fi
echo "$WT_PATH"
```

If it exits with a `CONFLICT:` message, stop and report it — do not clobber anything.

## Step 3 — enter the worktree

Call `EnterWorktree` with the path printed on the last line of step 2's output:

```
EnterWorktree({ path: "<that path>" })
```

Then give a one-line confirmation (branch, path, cwd moved).

## Step 4 — carry out the follow-up instructions (only if given)

If `$ARGUMENTS` had text after the first token (shape 3), now that the session is inside
the new worktree, carry out that trailing text exactly as if it had been typed as a
fresh prompt in this worktree. The "exactly two tool calls" budget covers only worktree
creation (steps 2-3); the follow-up work is unbounded and uses whatever tools it needs.

If there were no trailing instructions (shapes 1 and 2), stop after the step 3
confirmation.

## Leaving / cleaning up later

This session enters the worktree via `path`, so `EnterWorktree` does **not** own it and
`ExitWorktree({action:"remove"})` will refuse. To leave or delete:

- **Leave, keep the worktree**: `ExitWorktree({action:"keep"})`.
- **Delete it**: `ExitWorktree({action:"keep"})` first (returns to the repo root), then
  remove manually — `git worktree remove "<path>"` (add `--force` if it has changes) and
  optionally `git branch -D "<prefix>/<words>"`. Do not call `ExitWorktree` with
  `remove` — it cannot remove a path-entered worktree.
