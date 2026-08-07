---
description: Find and explore codebase deepening opportunities
---

Assess the named area for deepening opportunities: refactors that concentrate behavior behind a smaller interface and improve testability and maintainability.
Use the `codebase-design` skill's vocabulary and principles throughout.
Read `.claude/CONTEXT.md` if it exists before assessing candidates.

## Explore

Scope before scanning.
Deepening pays off where future changes are likely, so prioritize the named module, subsystem, or pain point.
If no scope is supplied, inspect a meaningful span of commit history to identify change hotspots before exploring code.

Look for concrete architectural friction:

- Understanding one concept requires navigating many small modules.
- An interface is nearly as complex as its implementation.
- Functions were extracted only for testability, but defects live in caller coordination.
- Tightly coupled modules leak policy across seams.
- A module is untested or difficult to test through its interface.

Apply the deletion test to suspected shallow modules: if deleting one spreads its complexity among callers, it is earning its keep.

## Present Candidates

Present a ranked list.
For each candidate, include:

- **Recommendation strength:** `Strong`, `Worth exploring`, or `Speculative`.
- **Files:** The involved files or modules.
- **Problem:** One sentence describing the concrete friction using the design vocabulary.
- **Solution:** One sentence describing the proposed deepening direction.
- **Wins:** Flat bullets of no more than six words each.

Use terms from `.claude/CONTEXT.md` when naming domain concepts and modules.
End with a top recommendation and why it is the best first candidate.
Do not propose detailed interfaces yet.
Ask which candidate the user wants to explore.

## Decision Loop

After the user selects a candidate, resolve the design through a decision-by-decision interview.
Ask one question at a time and wait for the user's answer before continuing.
Provide a recommended answer for each question.
Research facts available in the environment rather than asking about them.
The user owns decisions; do not implement the refactor until shared understanding is confirmed.

Cover the candidate's constraints, dependencies, module shape, what the interface hides, what remains outside it, and which behavioral guarantees must survive.
Identify which existing tests remain valuable, which implementation-coupled tests should be replaced, and how the deeper interface will be tested.
When a load-bearing reason rejects a candidate or design, record it in the conversation so it is not proposed again.
For consequential or ambiguous interface choices, compare materially different designs using depth, locality, seam placement, and trade-offs.
When the discussion resolves a new codebase-specific domain term, load `domain-modeling` and update `.claude/CONTEXT.md`.

When the decisions are resolved, summarize the agreed design, interface boundaries, hidden complexity, rejected alternatives, risks, and testing strategy.
Ask the user to confirm that summary before proposing or beginning implementation.

Treat supplied command arguments as additional context: $ARGUMENTS
