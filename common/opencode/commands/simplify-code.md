---
description: Simplify the current code changes without changing behavior
---

Simplify the current code changes while preserving their behavior.

The intended behavior and any additional scope from the user is: $ARGUMENTS

The changed files are:
!`{ git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } | sort -u`

Inspect the uncommitted diff and limit changes to the listed files.
If the diff contains unrelated work, or the intended behavior is unclear, ask one concise question before editing.

Preserve exact behavior and compatibility.
Do not change exported APIs, serialized formats, database or network contracts, error identity or wrapping semantics, logging and metric behavior, context propagation, retry behavior, ordering, synchronization, or cancellation behavior unless the user explicitly requests it.

Follow all applicable `AGENTS.md` files, repository conventions, and package-local patterns.
Repository rules override this prompt.

Improve clarity by:

- Removing duplication, dead branches, redundant state, and unnecessary indirection.
- Reducing nesting where the resulting control flow is clearer.
- Using explicit, domain-meaningful names.
- Keeping related logic together.
- Preferring straightforward Go control flow over clever abstractions.
- Removing comments that merely restate code, while preserving comments that explain invariants, protocol details, concurrency, or non-obvious decisions.
- Using idiomatic Go error handling and wrapping errors only when the additional context is useful.

Do not make broad refactors, mechanical renames, new abstractions, or unrelated formatting changes unless they are necessary to simplify the scoped change or the user explicitly requests them.
Do not split a cohesive function merely to reduce its length.
Do not merge distinct concerns solely to reduce line count.
Do not replace understandable code with dense expressions.
Do not change production behavior.
Update tests only when a structural change requires adapting test setup or assertions while preserving the same externally observable behavior.
If the existing tests reveal an intended behavioral change, stop and ask the user to handle it as an implementation task rather than a simplification.

Make the smallest safe refinement.
If no material improvement is available, make no edits and say so.

After editing:

1. Run `gofmt` on changed Go files.
2. Run the narrowest relevant tests.
3. Run `gopls check --severity=hint $(git diff --name-only -- '*.go')` if working in a Go project.
4. Report only material changes, verification performed, and anything not verified.
