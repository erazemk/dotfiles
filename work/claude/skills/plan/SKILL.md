---
name: plan
description: Discuss and plan a change before touching any code. Use when the user wants to think through an approach, design a feature, or prepare a spec — "plan this", "let's plan", "how would you implement", "design an approach", "/plan". Does NOT write a plan file until the user explicitly asks.
argument-hint: "[what to plan]"
---

# Plan a change

What to plan: $ARGUMENTS

## Two modes

This skill has two modes.
The default is **conversation**.
The plan file is only written when the user explicitly asks for it (e.g. "write the plan", "write it up", "let's create the spec").

---

## Mode 1 — Conversation (default)

Engage in a back-and-forth discussion to understand the problem and iron out the approach.
Explore the codebase as questions arise — read files, search for existing patterns, check ADRs — but only what the current question requires.
Do not run a full upfront investigation pipeline; let the conversation drive what you read.

The goal is to arrive at a shared understanding of:
- what problem is being solved and why
- where the seams are (prefer existing seams at the highest level possible; the fewer new seams, the better)
- what the approach is and what the key tradeoffs are
- what is explicitly out of scope

Stay in this mode until the user signals they are ready to write the plan.
Do not produce a plan file, create a worktree, or begin implementing.

## Mode 2 — Write the plan

Triggered only by an explicit user signal.

### Worktree

If the change is under `~/DevRev`, is real feature work, and you are not already in a worktree, switch to a new worktree first using the `worktree` skill.
If already in a worktree, stay there.
If not in a git repo, not under `~/DevRev`, or the user wants a quick throwaway plan, skip the worktree and write to `.claude/plans/` in the current project root.

### Read-only contract

While writing the plan you may read files, search the codebase, and run read-only commands.
You may not edit source files, run mutating commands, or create commits.
If the user asks for a change mid-plan, finish the plan first, then implement after approval.

### The plan file

Write to `.claude/plans/<descriptive-kebab-name>.md` in the repo/worktree root.
This path is gitignored globally and is deleted automatically when the worktree is removed.
Name the file after the feature, not generically.

The plan should contain whatever is needed to execute the work without ambiguity.
For a small focused change a lightweight plan is fine.
For feature work, include enough to serve as a spec:

- **Problem** — what problem is being solved, from the user's perspective
- **Solution** — what the solution looks like, from the user's perspective
- **User stories** — a thorough numbered list of "As a X, I want Y, so that Z"
- **Implementation decisions** — modules touched, interface changes, architectural decisions, schema or API changes; no file paths or code snippets unless a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, type shape, schema) — trim to the decision-rich parts only
- **Testing decisions** — what seams will be tested, what prior art in the codebase applies, what makes a good test for this change
- **Out of scope** — explicit list of what is not being done

Omit sections that add no value for the specific change.
Keep it concise enough to scan, detailed enough to execute.
Do not hard-wrap body lines — write each paragraph or bullet as a single unwrapped line so diffs stay clean.

### After writing

Stop and present a short summary.
Wait for explicit approval before implementing.
Planning does not silently roll into coding.

## Later

The plan file is gitignored and lives in the worktree, so removing the worktree deletes it automatically.
When finishing the work, use the `finish` skill — the plan file is a good source for the PR/issue description.
