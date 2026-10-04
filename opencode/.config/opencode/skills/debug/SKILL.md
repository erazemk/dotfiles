---
name: debug
description: Investigate production logs, traces, incidents, and suspected production-only failures without a reliable local reproduction. Use diagnosing-bugs once a suspected issue needs a local reproduction, fix, and verification.
---

Find the true root cause, not a symptom.

1. Frame the symptom, expected behavior, onset, blast radius, and prior attempts.
2. Rank plausible, falsifiable hypotheses.
3. Gather the cheapest evidence that distinguishes each hypothesis.
4. Correlate code paths with runtime evidence such as logs, traces, metrics, and deploys.
5. Eliminate contradicted hypotheses until the symptom is explained end-to-end.

Lead with the root cause and confidence level.
Cite the supporting `file:line`, timestamps, and runtime evidence.
Recommend a concrete mitigation or fix, state what remains uncertain, and describe the smallest local scenario that should reproduce the suspected defect.
Do not claim the issue is fixed until that scenario has been run before and after a code change.
