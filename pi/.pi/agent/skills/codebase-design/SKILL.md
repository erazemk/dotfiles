---
name: codebase-design
description: Evaluate architecture or refactoring choices when module shape, interfaces, dependencies, or test seams are central to the task. Use for consequential design decisions, not routine edits.
---

Identify existing callers, interfaces, dependencies, observable behavior, and repository conventions before proposing a design.
Name the concrete friction: duplicated coordination, leaked policy, excess caller knowledge, or tests coupled to implementation details.
If there is no material friction, do not invent a refactor.

Prefer the smallest design that concentrates the complexity and gives callers useful behavior without requiring them to understand the implementation.
Explain what the interface hides, what callers still need to know, and where behavior can vary without editing callers.
Depth and seams are useful design heuristics, not mandatory vocabulary or goals measured by line count or method count.

Avoid speculative abstractions and ports introduced solely for hypothetical future implementations.
Real variation, production dependencies, and practical testing needs can justify a seam; consider the existing codebase rather than requiring a fixed number of adapters.
Keep internal seams internal unless callers genuinely need them.

For consequential choices, compare materially different options, including keeping the current design.
Explain compatibility, complexity, locality of change, and testing trade-offs.
Test observable outcomes through meaningful interfaces where practical, without forbidding focused implementation or integration tests.
