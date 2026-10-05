---
description: Identify concrete architecture improvements and resolve a selected design before implementation
---

$ARGUMENTS

Use the codebase-design skill to assess the named area for concrete architectural friction.
Scope before scanning; if no area is supplied, inspect recent change history to identify relevant hotspots.
Use established repository terminology without creating or updating a glossary.

Look for duplicated coordination, leaked policy, excessive caller knowledge, needless indirection, or tests coupled to implementation details.
Do not invent abstractions or refactors where the current design is adequate.

Present a ranked shortlist with recommendation strength (`Strong`, `Worth exploring`, or `Speculative`), involved files, concrete problem, proposed direction, and expected benefits.
Recommend the best starting point and ask which candidate the user wants to explore.
Do not implement or design every candidate in detail.

For the selected candidate, use grill-me to resolve material decisions one question at a time.
Cover constraints, compatibility, interface shape, hidden complexity, dependencies, and verification of observable behavior.
Identify which existing tests remain valuable, which implementation-coupled tests should be replaced, and how the proposed design will be tested.
When a consequential reason rejects a candidate or design, record it in the conversation so it is not proposed again.
Compare materially different designs when the choice is consequential, including retaining the current design.
Research facts rather than asking the user to supply them.

Summarize the agreed design, trade-offs, risks, and verification strategy in the conversation.
Wait for confirmation of shared understanding before implementing.
