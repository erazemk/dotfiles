---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, present them as a ranked candidate list, then grill through whichever one you pick.
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones.
The aim is testability and maintainability.

Read the `codebase-design` skill for the architecture vocabulary (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**) and its principles (the deletion test, "the interface is the test surface", "one adapter = hypothetical seam, two = real").
Use these terms exactly — don't drift into "component," "service," "API," or "boundary."

The domain language in `CONTEXT.md` (produced by the `terminology` skill) gives names to good seams.
Use it if it exists.

## Process

### 1. Explore

**Scope before you scan — YAGNI.**
Deepening a module pays off by making future changes to it easier, so weight the parts of the codebase that change most.
Decide _where_ to look before you look:

- If the user named a direction — a module, a subsystem, a pain point — take it.
- Otherwise, walk back a good stretch of the commit history (`git log --oneline`) to find hot spots — the files and areas that keep coming up.
  If changes are scattered with no clear hot spot, widen the net.

Read `CONTEXT.md` if it exists before scanning.

Explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it?
A "yes, concentrates" is the signal you want.

### 2. Present candidates

Present the candidates as a ranked list in the conversation.
For each candidate:

- **Recommendation strength** — `Strong`, `Worth exploring`, or `Speculative`
- **Files** — which files/modules are involved
- **Problem** — one sentence on why the current architecture is causing friction, using glossary terms
- **Solution** — one sentence on what would change
- **Wins** — bullets of ≤6 words each, e.g. "Tests hit one interface", "Pricing logic stops leaking"

End with a **top recommendation**: which candidate to tackle first and why.

Use `CONTEXT.md` vocabulary for domain concepts and `codebase-design` vocabulary for architecture.
If `CONTEXT.md` defines "SyncUnit," talk about "the SyncUnit intake module" — not "the FooBarHandler."

Do NOT propose interfaces yet.
After presenting, ask: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, invoke the `grill-me` skill to walk the decision tree — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

As decisions crystallise:

- **Naming a deepened module after a concept not in `CONTEXT.md`?** Add the term via the `terminology` skill.
- **Sharpening a fuzzy term during the conversation?** Update `CONTEXT.md` right there.
- **User rejects the candidate with a load-bearing reason?** Note it so future scans don't re-suggest the same thing.
- **Want to explore alternative interfaces for the deepened module?** Use the **Design It Twice** pattern from the `codebase-design` skill.
