---
name: debug
description: Investigate production or runtime failures using operational evidence when there is no reliable local reproduction. Use diagnosing-bugs once a local reproduction, code fix, and before/after verification become the task.
---

Establish the reported symptom, expected behavior, timing, affected scope, and prior attempts from available evidence.
Rank plausible, falsifiable hypotheses and gather the cheapest evidence that distinguishes them.
Correlate code paths with logs, traces, metrics, deployments, and relevant data.
Use whichever observability tools are available; do not assume a particular vendor.

Separate the initiating cause from downstream symptoms.
Do not infer all-record impact, production behavior, or a proven cause from a sample, QA evidence, or a suggestive log alone.

Lead with the most supported conclusion and confidence.
Cite relevant code locations, timestamps, and runtime evidence.
State missing evidence and give a concrete mitigation, next discriminating check, or fix recommendation.
Propose a local reproduction only when feasible, and use diagnosing-bugs for that work.
Do not claim that a recommended fix has been verified unless the relevant behavior was checked.
