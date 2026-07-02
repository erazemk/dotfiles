---
name: reflect
description: Consolidate durable learnings from the current session into git-committed guidance files, debloating and deduplicating as you go. Migrates anything durable out of Claude auto-memory into committed files, removes duplicates from auto-memory, fixes inaccuracies, and resolves contradictions at the source. Requires approval before any edit. Use when asked to reflect, consolidate memory, or capture session learnings, or when the reflection hook offers it.
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git ls-files:*), Bash(git rev-parse:*), Bash(git log:*), Bash(ls:*), Bash(cat:*), AskUserQuestion
---

Run a memory-consolidation pass over the current session. The goal is to make future agents more
effective with less context, while keeping durable guidance lean and accurate.

This is a consolidation pass, not a session summary. Do not record one-off status, ticket/PR state,
timestamps, temporary debug paths, secrets, or facts a live API should provide fresh. Take no
argument and accept no focus instruction — decide for yourself what is worth reflecting on.

## Hard rules

- **Destinations are git-tracked files only.** Every edit must land in a file tracked by git in the
  current project (verify with `git ls-files --error-unmatch <path>`). Valid destinations: the
  project `CLAUDE.md` / `AGENTS.md`, rule files under `.claude/rules/`, skills under
  `.claude/skills/`, and docs under `docs/` or `README.md`. If a candidate's natural home is not
  git-tracked, either find a tracked home for it or skip it.
- **Never write new information into Claude auto-memory.** Auto-memory (`~/.claude/projects/<project>/memory/`,
  including its `MEMORY.md` index and topic files) is never a destination for new facts.
- **Auto-memory is only ever trimmed, never grown.** You may edit auto-memory files solely to remove
  content that is now duplicated in (or migrated to) a git-tracked file, and to keep `MEMORY.md` in sync.
- **Approval gate.** Make no edit until the user approves the exact change list via `AskUserQuestion`.
- **Resolve contradictions at the source.** When a candidate contradicts existing guidance, propose a
  replacement of the existing text — never append a second, conflicting rule.
- **No secrets.** Never write credentials, tokens, or private third-party data anywhere.

## Workflow

### 1. Gather sources

- Confirm the project root: `git rev-parse --show-toplevel`. If not in a git repo, stop and say so —
  this skill only edits git-tracked files.
- Read the project guidance: nearest `CLAUDE.md` and/or `AGENTS.md` (walk up from cwd), any
  `.claude/rules/*`, and any referenced docs that the session actually touched.
- Read the project's Claude auto-memory: the `MEMORY.md` index under
  `~/.claude/projects/<project-slug>/memory/`, plus topic files it points to that look relevant to
  this session. This is read for deduplication and migration only.
- Do not bulk-read unrelated docs hunting for a place to write something.

### 2. Extract candidates from the session

Prioritize these signals:

- User corrections about code style, response style, workflow, tool choice, or what the agent forgot.
- Repeated searches, failed attempts, retries, or debugging paths that should not be rediscovered.
- Recurring local-environment or test setup quirks (service dependencies, build steps).
- Instructions the agent missed, misunderstood, or had to be reminded about.
- Durable project facts, architecture conventions, and troubleshooting recipes that were non-obvious
  to discover.
- LSP/`gopls`/type-checker feedback after edits that reveals a reusable code-style rule.
- Opportunities to move bulky always-loaded content out of `CLAUDE.md`/`AGENTS.md` into a referenced
  doc, or to turn a repeated multi-step procedure into a skill.

### 3. Filter

Keep only candidates that are durable, reusable, and actionable. Discard:

- One-off status, ticket/PR state, timestamps, and temporary debug paths.
- Anything readily rediscoverable from first principles.
- Ephemeral facts that a live API or fresh inspection should provide.

Prefer a few high-value edits over many.

### 4. Reconcile against existing guidance and auto-memory

For every surviving candidate, before proposing anything, classify it against what already exists:

- **New** — not present anywhere; propose adding to the right git-tracked destination.
- **Duplicate of committed guidance** — already covered in a git-tracked file; do not re-add. If it
  is *also* sitting in auto-memory, propose trimming the auto-memory copy.
- **Contradicts committed guidance** — propose a replacement edit at the source (fix the existing
  line/section), not an addition.
- **Refines committed guidance** — propose a tightening/reword of the existing text.

Separately, sweep the auto-memory store itself:

- **Migrate durable content out of auto-memory into git-tracked files** wherever it belongs there,
  then remove it from auto-memory (and update `MEMORY.md`). Move as much as reasonably can live in
  committed guidance.
- **Remove duplicates**: any auto-memory entry already covered by a committed file should be deleted
  from auto-memory, with `MEMORY.md` updated to drop the pointer.
- **Fix inaccuracies**: if committed guidance contains stale or wrong information the session
  disproved, propose correcting it at the source.

### 5. Choose destinations

- `CLAUDE.md` / `AGENTS.md`: short, high-priority rules that should affect every session. Put
  frequently forgotten rules earlier, or reword them to be direct and actionable.
- `.claude/rules/`: scoped or file-type-specific rules.
- Referenced docs (`docs/`, `README.md`): verbose troubleshooting, repo maps, debugging recipes,
  detailed workflows — link from `CLAUDE.md`/`AGENTS.md` so they load lazily.
- A skill: reusable multi-step procedural knowledge that should load on demand.
- Keep always-loaded files lean: prefer moving bulk into a referenced doc over growing `CLAUDE.md`.

### 6. Present the change list and ask for approval

Print, in this order, before asking anything:

**## Proposed Updates** — one entry per change: file path, the category (add / replace / refine /
migrate-out-of-auto-memory / trim-auto-memory-duplicate / fix-inaccuracy), and the one-line future benefit.

**## Exact Edits** — show the precise text change for each file, as a unified diff or a compact
before/after snippet with enough surrounding context to be unambiguous. Do not describe edits only in
prose. Show auto-memory trims/migrations as concrete deletions with the `MEMORY.md` pointer update.

**## Skipped Candidates** — each dropped candidate and the one-line reason (one-off, not durable,
already covered, ephemeral).

Then, in the same turn, call `AskUserQuestion` for approval. Offer at least:

- Apply all proposed updates
- Skip all updates

If there are independent update groups (e.g. project-guidance edits vs. auto-memory cleanup), offer a
separate selectable choice per group so the user can approve subsets. Make no edit before approval.

### 7. Apply approved edits

- Apply only the approved edits. Keep them small and surgical.
- Preserve existing style, wording conventions, and ordering unless reordering was part of the approval.
- Do not add backward-compatibility shims or new abstractions unless clearly useful.
- Do not stage or commit; leave the working tree dirty for the user's normal `commit`/`pr` flow.

### 8. Report

End with: files changed, candidates skipped, auto-memory entries trimmed or migrated, and any
approved edits that could not be applied (with the reason).
