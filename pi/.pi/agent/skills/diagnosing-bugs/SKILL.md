---
name: diagnosing-bugs
description: Reproduce, fix, or re-verify a suspected local software bug. Use debug for production-only investigations without a reliable local reproduction; do not load this procedure for routine design or unrelated tests.
---

Honor the requested scope; do not edit during read-only investigation.
Before changing code, run a scenario that reaches the reported symptom when feasible.
If reproduction is not feasible, explain why, identify the strongest available evidence, and distinguish hypotheses from confirmed behavior.

Confirm that the scenario demonstrates the original symptom, not merely a nearby failure.
Make it deterministic and quick to rerun where practical, using isolated state and fixed randomness when relevant.
For intermittent failures, improve the reproduction rate before drawing conclusions.
Minimize the scenario only if it still demonstrates the same symptom.

Rank falsifiable causes and use targeted checks to distinguish them.
Apply the smallest fix supported by the evidence.
Rerun the original scenario unchanged where possible, then relevant tests.
For before/after comparison, stash only relevant fix changes and preserve unrelated user work and staged state.

Distinguish an actual product fix from correcting an invalid test or expectation.
Report what failed before, what passed after, and what remains unverified.
Do not claim that passing tests prove an unreproduced runtime defect is fixed.
Add regression tests only when requested.
Ground them in the confirmed reproduction and assert observable behavior at a meaningful seam.
Run both the regression test and the original reproduction after the fix.
Remove temporary instrumentation and discard or promote throwaway reproductions.
