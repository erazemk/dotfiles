---
name: plan
description: Investigate a change read-only and write an implementation plan to a file before touching any code. Use whenever the user asks you to plan, design an approach, or think through how to implement something before writing code — "plan this", "make a plan", "how would you implement", "design an approach", "/plan".
argument-hint: "[what to plan]"
---

# Plan a change (read-only) and write it to a file

Investigate before implementing, and write the plan down as an ordinary file
using the `Write`/`Edit` tools — every revision to the plan then shows up as an
inline diff in the conversation, so changes to the plan are easy to review.

What to plan: $ARGUMENTS

## The read-only contract

While planning, you may ONLY:

- read files, search the codebase, and run **read-only** commands (`git log`,
  `git diff`, `grep`, `ls`, test/build commands only if strictly needed to
  understand behavior — nothing that mutates);
- `Write`/`Edit` the **single plan file** described below.

You may NOT edit source files, run mutating commands, create commits, or change
any system state. If the user asks you to make a change mid-plan, stop and say
planning is read-only — offer to finish the plan and then, once they approve,
implement it. The worktree (step 1) is the real safety net: if a stray edit
slips through, it lands on a throwaway branch, never on `main`.

## Step 1 — decide where the plan lives (worktree-first, conditionally)

Producing a plan usually means feature work is about to start, and feature work
in `~/DevRev` always happens in a fresh git worktree.

- **If the change is under `~/DevRev`, is real feature work, and you are NOT
  already in a worktree:** switch to a new worktree first. Read and use the
  `worktree` skill for all branch-naming and path logic — do not reimplement it.
  Write the plan inside that worktree. This is the default for DevRev work.
- **If you are already in a worktree:** stay there; do not nest. Write the plan
  in the current worktree.
- **If not in a git repo, not under `~/DevRev`, or the user explicitly wants a
  quick throwaway plan:** skip the worktree and write the plan to the current
  project's `.claude/plans/` directly.

Do not force a worktree for exploratory "should we even do this?" planning —
that is premature commitment. When unsure whether the work is worktree-worthy,
ask the user briefly rather than guessing.

## Step 2 — investigate, then design

Feel free to use `AskUserQuestion` at any point in this workflow to clarify
requirements or choose between approaches — don't make large assumptions about
user intent. The goal is a well-researched plan with no loose ends before
implementation begins.

- **Research.** Read the code yourself first. Actively search for existing
  functions, utilities, and patterns that can be reused — avoid proposing new
  code when suitable implementations already exist. Only when the scope is
  uncertain or spans several areas, launch `Explore` agent(s) in parallel
  (single message, multiple tool calls) to cover more ground, each with a
  specific search focus.
- **Design.** For anything beyond a trivial change (typo fixes, single-line
  changes, simple renames), get independent implementation strategies before
  committing to one — launch one or more `Plan` agents (a built-in,
  permission-enforced read-only agent purpose-built for this), each given the
  background context from research above, the requirements, and optionally a
  distinct perspective to weigh (e.g. simplicity vs. performance vs.
  maintainability). Read their output; take the best approach, or the best
  ideas across them.
- **Review.** Before finalizing, re-read the critical files identified during
  research to deepen your understanding, and consult the `advisor` agent with
  your drafted approach for a sanity check on risks and tradeoffs. Confirm the
  approach still aligns with the user's original request.

## Step 3 — write the plan file

Write to `.claude/plans/<descriptive-kebab-name>.md` in the repo/worktree root
(this path is gitignored globally, so it never enters version control and is
deleted automatically when the worktree is removed — you never clean it up
manually). Name the file descriptively after the feature, e.g.
`.claude/plans/oauth-token-refresh.md` — not a generic name.

Build the plan incrementally with `Edit` (not repeated full `Write`s) so each
change renders as an inline diff. Keep it concise enough to scan quickly, but
detailed enough to execute effectively. Do not hard-wrap body lines — write
each paragraph/bullet as a single unwrapped line so diffs stay clean. Structure it:

- **Context** — why this change: the problem/need, what prompted it, intended outcome.
- **Approach** — only the recommended approach, not every alternative.
- **Changes** — name the critical files to modify; reference existing functions/
  utilities to reuse (with paths). For a repeated pattern, describe it once and
  list a few representative paths — do not enumerate every file.
- **Verification** — how to test the change end-to-end (run the code, tests, MCP tools).

## Step 4 — stop and get approval

After the plan file is written, **STOP.** Present a short summary and wait for
the user's explicit approval. Do not begin implementing on your own — planning
does not silently roll into coding.

On approval, planning ends and normal editing resumes: implement the plan in the
same worktree, following it. The read-only contract is lifted only at this point.

## Later

- **Cleanup** is automatic: the plan is gitignored and lives in the worktree, so
  removing the worktree (see the `worktree` skill's cleanup section) deletes it.
  Never delete plan files manually.
- **Finishing:** when the work is done, use the `finish` skill. The plan file is
  a good source for the PR/issue description — reference it there before the
  worktree is removed, so anything worth keeping is preserved.
