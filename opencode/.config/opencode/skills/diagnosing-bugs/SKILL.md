---
name: diagnosing-bugs
description: Reproduce a suspected issue locally, apply a confirmed fix, and verify the same scenario no longer fails. Use for local bugs, performance regressions, or when asked to reproduce or re-verify an issue; add regression tests only when requested.
---

Before changing code, build and run the reproduction scenario from the investigation.
It must reach the reported symptom, be deterministic or have a high enough reproduction rate to debug, finish quickly, and run unattended.

Build the loop with a CLI invocation, replayed real payload, minimal harness, property loop, bisection harness, or differential test.
Use fixed randomness and isolated state to make timing and outcomes deterministic.
For intermittent failures, increase the reproduction rate before diagnosing.

Confirm the scenario reproduces the exact original symptom.
Minimize it only when doing so makes diagnosis or reruns easier, while preserving that symptom.
Then form falsifiable hypotheses, test one variable at a time, and use targeted instrumentation only when needed.

Apply the smallest fix consistent with the confirmed cause.
Re-run the original reproduction scenario unchanged and confirm the original symptom no longer occurs.

When asked to add regression coverage, write a test at a meaningful seam using the confirmed scenario and observable behavior.
Run the regression test and the original reproduction after the fix.
Remove temporary instrumentation and either promote or delete throwaway test cases.
