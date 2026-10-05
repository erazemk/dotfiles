---
description: Simplify the current task's changed files without changing behavior
---

$ARGUMENTS

Determine the current task's changed files from staged, unstaged, and relevant untracked changes.
Inspect the diff and limit most edits to those files; preserve unrelated work even within the same file.
If scope or intended behavior is unclear, ask one focused question before editing.

Preserve behavior and compatibility, including exported interfaces, serialized formats, database/network contracts, error identity and wrapping, observability, context propagation, retries, ordering, synchronization, and cancellation.
Follow repository instructions and the existing-comment preservation rule.

Remove duplication, dead branches, redundant state, and unnecessary indirection only when doing so materially improves clarity.
Prefer straightforward control flow, meaningful names, and cohesive logic.
Do not split functions solely to reduce their size, introduce speculative abstractions, perform broad renames, or touch unrelated formatting.
Adapt tests only when structural changes require it, preserving the same observable expectations.
If tests reveal a requested behavior change, stop and handle it as implementation rather than simplification.
If there is no material improvement, make no edits and say so.

Choose formatting and the narrowest meaningful verification from the changed files, their language, and repository conventions.
Format only changed files, and account for staged-only and untracked files as well as unstaged changes.
Report material refinements, checks performed, and anything unverified.
