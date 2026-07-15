---
name: reflect
description: Reflect on the current Claude Code session to improve future sessions. Use when asked to reflect, or to consolidate this session's learnings, via /reflect.
allowed-tools: Read, Edit, Write, Grep, Glob, Bash, Agent, AskUserQuestion
effort: high
context: fork
disable-model-invocation: true
---

Reflect on the CURRENT Claude Code session only, and turn what went wrong into durable, correctly
placed fixes, so future sessions make fewer of the same mistakes. Manually invoked, turn-scoped —
no hook, no background process, no cross-session state.

## Argument hint

If this skill was invoked with arguments (e.g. `/reflect memory handling` or `/reflect <topic>`),
treat them as a focus hint: the user wants the analysis to pay particular attention to interactions
involving that topic.
Append the following sentence to both the MAP audit prompt and the REDUCE merge instructions:
"The user asked to focus on: <args>. Prioritise findings in that area, but still surface any other
high-value learnings."
If no arguments were provided, omit the sentence entirely — do not invent a focus.

## How this skill divides responsibility

The *reflection reasoning* — deciding what the mistakes and learnings were, reconciling them
against existing guidance, and choosing destinations — is done by independent Haiku subagents you
(the main agent) spawn directly via the `Agent` tool, never by yourself and never by a subagent
spawning further subagents. This is deliberate: an agent grading its own conversation shares the
blind spots that caused the mistakes, and keeping every model call at one spawn depth, issued by
you, keeps the whole run visible in Claude Code's own subagent tracking and bounded — nothing here
can spawn an unbounded chain (this replaced an older automated pipeline that did exactly that, via
background `claude -p` subprocesses launched from a `SessionEnd` hook, and caused a runaway
100+-process incident).

**Your role beyond spawning the analysis subagents is mechanical.** You resolve the transcript,
split it, spawn the MAP/REDUCE subagents, present their finished proposals, gate on approval, apply
the approved edits verbatim, and append applied learnings to the ledger. You do not judge the
conversation yourself, invent new learnings, or re-reconcile — if the proposals look wrong, surface
that to the user rather than substituting your own analysis.

## Hard rules

- **You do not perform the analysis yourself.** Always obtain proposals via the MAP/REDUCE `Agent`
  calls below. Never hand-write proposals from your own read of the conversation.
- **One spawn depth only.** You spawn every MAP and REDUCE `Agent` call directly. Never ask a
  spawned agent to spawn another agent, and never route analysis through a background process,
  hook, or detached subprocess.
- **Destinations are real files.** Project destinations must be git-tracked
  (`git ls-files --error-unmatch <path>`). Global destinations are proposed as `~/.claude/...` paths
  but are symlinks from this dotfiles repo — resolve and edit the real path under
  `~/.config/dotfiles/work/claude/...`, never write through the `~/.claude` symlink (it fails). If a
  destination is neither, skip it and say so.
- **Approval gate.** Make no edit until the user approves the exact change list via
  `AskUserQuestion`. Show the verbatim edit text and exact destination path for every proposal —
  never a summarized description. Never bundle a `settings.json`/permissions change into a blanket
  "apply all"; it always gets its own explicit confirmation.
- **Resolve contradictions at the source.** When a proposal replaces existing guidance, edit the
  existing text in place — never append a second, conflicting rule.
- **Ledger records applied learnings only.** Append to `~/.claude/learning/ledger.jsonl` only for
  edits actually applied after approval — never for skipped or rejected proposals. Its purpose here
  is cross-run dedup and an audit trail, not automated recurrence escalation (there is no automated
  trigger left to escalate).
- **No secrets.** Never write credentials, tokens, or private third-party data anywhere.

## Workflow

### 1. Resolve the transcript and split it

Find the current session's transcript: the newest `.jsonl` by mtime in
`~/.claude/projects/<cwd-slugified>/` (slugify by replacing every non-alphanumeric character in the
absolute cwd with `-`).

Run:

```
<skill-dir>/scripts/split-session <transcript-path>
```

This prints one chunk file path per line (typically one, for a normal-length session) and nothing
else. It writes chunk files to a fresh `mktemp -d` directory — a frozen, one-time snapshot of the
transcript taken at this exact moment. Everything this `/reflect` run does from here on is appended
to the live transcript file *after* this snapshot, so none of it — your own tool calls, the MAP/REDUCE
subagents, the approval conversation — is ever part of a chunk file. That is what keeps this run
from analyzing itself; no line-count bookkeeping needed.

If the script exits non-zero (e.g. the session is too large — over 12 chunks), relay its stderr
message to the user and stop.

### 2. MAP — one Agent call per chunk

For each chunk path, spawn one `Agent` call (`general-purpose`, run in parallel — a single message
with multiple tool uses when there is more than one chunk). Each call should:

- Read its assigned chunk file itself (pass the path, not the chunk's contents, in the prompt).
- Apply this audit prompt: "You are auditing a Claude Code session transcript chunk to improve
  FUTURE sessions. You are an independent reviewer; you did not participate in this conversation.
  Identify concrete MISTAKES the assistant made and durable, reusable LEARNINGS worth encoding into
  config. Look for: user corrections of the assistant; instructions the assistant missed, forgot, or
  violated; wrong tool/command choices; repeated failed attempts, retries, or thrashing; non-obvious
  project facts the assistant had to discover the hard way; permission prompts or command failures
  that a config change would prevent. Ignore one-off status, ticket/PR chatter, timestamps, and
  anything trivially re-derivable. If the chunk contains nothing worth encoding, reply with exactly:
  NONE. Otherwise output a terse markdown bullet list: for each item, what went wrong or was
  learned, a short quote or reference as evidence, and (if obvious) the kind of fix — a behavioral
  rule, a project fact, a skill, an agent tweak, an enforcement hook, or a permission/setting
  change. Be specific and concise. Do not propose file edits yet."

Collect each call's returned text; drop any that reply exactly `NONE`.

If every chunk replied `NONE`, tell the user there was nothing durable this session and stop —
don't proceed to REDUCE.

### 3. REDUCE — one Agent call to merge, dedupe, and choose destinations

Skip this step and use the single MAP result directly as the proposals block if there was only one
chunk and it already covers destination selection (fold the REDUCE instructions below into that
single MAP call's prompt instead, so a single-chunk session still gets one Haiku pass total, not two).

Otherwise, spawn exactly one more `Agent` call (`general-purpose`) with the collected non-`NONE` MAP
outputs plus these guidance file paths for it to `Read` itself: `~/.claude/CLAUDE.md`, the current
project's `CLAUDE.md` and `.claude/rules/*` (if present), and `~/.claude/learning/ledger.jsonl` (if
present). Instruct it to:

1. Merge and de-duplicate the candidates. Drop anything already covered by existing global or
   project guidance. Drop one-off, ephemeral, or trivially re-derivable items. Prefer a few
   high-value proposals over many.
2. For each surviving learning, choose the destination:
   - global `~/.claude/CLAUDE.md`: only for behavior that should apply across ALL projects.
   - project `CLAUDE.md` or `.claude/rules/`: default for repo-specific behavior/facts (prefer this
     over global).
   - a skill: reusable multi-step procedures.
   - a specific agent definition: when a subagent misbehaved.
   - an enforcement hook (PreToolUse/PostToolUse): when the mistake is deterministically detectable
     and a rule alone would keep being forgotten.
   - `settings.json` permissions: for repeated permission prompts/denials.
   If a candidate contradicts existing guidance, propose REPLACING the existing text at its source,
   never appending a duplicate.
3. Check each surviving item against the ledger for a matching signature — if found, mark it
   RECURRED (the earlier fix didn't stick) and escalate the wording rather than proposing the same
   fix again.
4. Never propose writing secrets. Destinations must be real files.

Output format — exactly this, or `NO_PROPOSALS` if nothing survives:

```
## Proposed learnings
### 1. <one-line description of the mistake or learning>
- type: <behavioral | project-fact | procedure/skill | agent | enforcement-hook | permissions>
- destination: <file path> (<add | replace | refine>)
- recurrence: <none | RECURRED: ledger match + escalation>
- evidence: <short quote or reference from the transcript>
- exact edit: <the precise text to add, or a before/after for a replacement>

### 2. ...

## Skipped
- <candidate>: <one-line reason (one-off | already covered | ephemeral | low-confidence)>
```

If the result is `NO_PROPOSALS`, tell the user there was nothing durable this session and stop.

### 4. Present the proposals

Show the user the `## Proposed learnings` and `## Skipped` sections verbatim, lightly formatted. Do
not editorialize or add learnings of your own. If a proposal is internally inconsistent (e.g.
destination file does not exist, or an edit is ambiguous), flag it inline as needing attention — but
still present it; the user decides.

### 5. Verify destinations before offering to apply

For each proposed edit, quickly confirm the destination is writable and appropriate:

- Project files: `git ls-files --error-unmatch <path>` (must be tracked).
- Global files under `~/.claude`: resolve to the real dotfiles path
  (`~/.config/dotfiles/work/claude/<...>`) and confirm that path exists — edit the real file, never
  the symlink.
- If a destination fails verification, mark that proposal as **not applicable** with the reason.

### 6. Ask for approval

Call `AskUserQuestion`. Offer at least:

- Apply all applicable proposals
- Skip all

If proposals fall into independent groups (e.g. project-guidance edits vs. a global CLAUDE.md
change vs. a new enforcement hook vs. settings.json permissions), offer a selectable choice per
group so the user can approve a subset — and always give settings.json/permissions proposals their
own explicit confirmation, never folded into a blanket "apply all." Make no edit before approval.

### 7. Apply approved edits

- Apply only approved, applicable edits, exactly as the proposal specified. Keep them surgical.
- For a **replace**, edit the existing text in place. For an **add**, insert at the natural spot,
  matching surrounding style (e.g. this user keeps each sentence on its own line in markdown).
- For **enforcement-hook** or **permissions** proposals, create/modify the hook script or
  `settings.json` block as specified.
- Preserve existing wording conventions and ordering unless reordering was part of the approval.
- Do not stage or commit; leave the working tree dirty for the user's normal commit/PR flow.

### 8. Record applied learnings in the ledger

For each edit actually applied, append one JSON line to `~/.claude/learning/ledger.jsonl`. Use a
compact object with these fields:

```
{"date":"<YYYY-MM-DD>","session":"<session_id>","signature":"<short stable phrase describing the mistake>","type":"<behavioral|project-fact|procedure/skill|agent|enforcement-hook|permissions>","destination":"<path>","action":"<add|replace|refine>","recurred":<true|false>,"status":"active","project":"<project path>"}
```

The `signature` is what a future `/reflect` REDUCE pass matches new candidates against for dedup, so
make it a stable, generalized description of the mistake — not a verbatim quote. Take the date from
the environment context. If the ledger file or its directory does not exist, create it. `session` is
the current session's id (the transcript filename minus `.jsonl`).

### 9. Report

End with: proposals applied, proposals skipped or rejected (with reason), any that were not
applicable (with reason), and the ledger entries appended.
