---
name: reflect
description: Reflect on a Claude Code conversation to improve future sessions. Use when asked to reflect, consolidate session learnings, or when the reflection hook offers it.
allowed-tools: Read, Edit, Write, Grep, Glob, Bash, AskUserQuestion
effort: high
---

Reflect on a Claude Code conversation and turn what went wrong into durable, correctly-placed
fixes, so future sessions make fewer of the same mistakes.

## How this skill divides responsibility

The *reflection reasoning* — deciding what the mistakes and learnings were, reconciling them
against existing guidance, and choosing destinations — is NOT done by you, the agent in the
conversation. It is done by independent `claude -p --model haiku` processes spawned by
`scripts/analyze`, which read the transcript from disk with fresh context. This is deliberate: an
agent grading its own conversation shares the blind spots that caused the mistakes and works from a
possibly-compacted, lossy context. The on-disk transcript is the lossless source of truth.

**Your role is mechanical only.** You run the analysis script, present its finished proposals,
gate on approval, apply the approved edits verbatim, and append applied learnings to the ledger.
You do not judge the conversation, invent new learnings, or re-reconcile — if the proposals look
wrong, surface that to the user rather than substituting your own analysis.

## Hard rules

- **You do not perform the analysis.** Always obtain proposals by running `scripts/analyze`
  (directly, or by consuming a proposals file it already wrote). Never hand-write proposals from
  your own read of the conversation.
- **Destinations are real files.** Behavioral/project guidance destinations should be git-tracked
  in the target project (verify with `git ls-files --error-unmatch <path>`). Global destinations
  under `~/.claude` (the global `CLAUDE.md`, `~/.claude/skills`, `~/.claude/hooks`,
  `settings.json`) are tracked in the user's dotfiles repo and are valid. If a proposal's
  destination is neither, skip it and say so.
- **Approval gate.** Make no edit until the user approves the exact change list via
  `AskUserQuestion`.
- **Resolve contradictions at the source.** When a proposal replaces existing guidance, edit the
  existing text in place — never append a second, conflicting rule.
- **Ledger records applied learnings only.** Append to `~/.claude/learning/ledger.jsonl` only for
  edits actually applied after approval — never for skipped or rejected proposals.
- **No secrets.** Never write credentials, tokens, or private third-party data anywhere.

## Workflow

### 1. Obtain proposals

Two modes:

- **Consume mode** (the reflection hook set `REFLECT_PROPOSALS` or told you a proposals file
  exists): read that file directly. Do not re-run analysis, and do not merge or dedupe anything
  yourself — if the hook had multiple pending sessions to offer, it already ran
  `scripts/analyze --combine` (a Haiku pass, same as normal analysis) to merge them into the one
  file you were handed, so by the time you see it there is exactly one file with the reconciled
  result. A `sources:` line near the top of a combined file lists which sessions fed into it,
  and its items carry a `sessions:` field instead of one implicit session — read but do not act
  differently on this, it only affects ledger recording in step 6.
- **Analyze-current mode** (manual `/reflect`, or no proposals file exists): run the bundled
  script against the current conversation:

  ```
  <skill-dir>/scripts/analyze
  ```

  With no argument it resolves the current session's transcript for the working directory, runs the
  preprocess → chunk → Haiku map → Haiku reduce pipeline, and prints the path of the proposals file
  it wrote (or prints nothing and exits 0 if there was nothing worth proposing). Run it and capture
  the printed path.

If no proposals file is produced (script printed nothing), tell the user there were no durable
learnings this session and stop. Do not fabricate proposals.

### 2. Present the proposals

Read the proposals file and show the user its two sections verbatim, lightly formatted:

- **## Proposed learnings** — each numbered item with its type, destination, recurrence status,
  evidence, and the exact edit the analysis proposed.
- **## Skipped** — candidates the analysis dropped and why.

Do not editorialize or add learnings of your own. If a proposal is internally inconsistent (e.g.
destination file does not exist, or an edit is ambiguous), flag it inline as needing attention —
but still present it; the user decides.

### 3. Verify destinations before offering to apply

For each proposed edit, quickly confirm the destination is writable and appropriate:

- Project files: `git ls-files --error-unmatch <path>` (must be tracked).
- Global files under `~/.claude`: confirm the real path exists (these are symlinked from the
  user's dotfiles; edit the real file, never write through a symlink if that fails).
- If a destination fails verification, mark that proposal as **not applicable** with the reason.

### 4. Ask for approval

Call `AskUserQuestion`. Offer at least:

- Apply all applicable proposals
- Skip all

If proposals fall into independent groups (e.g. project-guidance edits vs. a global CLAUDE.md
change vs. a new enforcement hook), offer a selectable choice per group so the user can approve a
subset. Make no edit before approval.

### 5. Apply approved edits

- Apply only approved, applicable edits, exactly as the proposal specified. Keep them surgical.
- For a **replace**, edit the existing text in place. For an **add**, insert at the natural spot,
  matching surrounding style (e.g. this user keeps each sentence on its own line in markdown).
- For **enforcement-hook** or **permissions** proposals, create/modify the hook script or
  `settings.json` block as specified.
- Preserve existing wording conventions and ordering unless reordering was part of the approval.
- Do not stage or commit; leave the working tree dirty for the user's normal commit/PR flow.

### 6. Record applied learnings in the ledger

For each edit actually applied, append one JSON line to `~/.claude/learning/ledger.jsonl`. Use a
compact object with these fields:

```
{"date":"<YYYY-MM-DD>","session":"<session_id>","signature":"<short stable phrase describing the mistake>","type":"<behavioral|project-fact|procedure/skill|agent|enforcement-hook|permissions>","destination":"<path>","action":"<add|replace|refine>","recurred":<true|false>,"status":"active","project":"<project path>"}
```

The `signature` is what the analysis reduce step matches future mistakes against to detect
recurrence, so make it a stable, generalized description of the mistake — not a verbatim quote.
Take the date from the environment context. If the ledger file or its directory does not exist,
create it. `session` is normally the proposals file's own session id (its filename minus `.md`).
For a combined file (its item has a `sessions:` field naming more than one session), append one
ledger line per listed session so recurrence-matching still sees every originating session.

### 7. Report

End with: proposals applied, proposals skipped or rejected (with reason), any that were not
applicable (with reason), and the ledger entries appended.
