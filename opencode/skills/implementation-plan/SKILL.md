---
name: implementation-plan
description: Create concrete service-specific implementation plans from a feature request or approved design. Use when the user asks for an implementation plan, rollout plan, checklist, or file-level execution plan.
---

Read the relevant design or feature context, inspect the current code and constraints, ask concise clarifying questions when needed, and produce a practical implementation plan.

Prefer short, direct writing.
Keep the plan grounded in the current codebase.

Before writing the plan:
- identify the exact behavior this service is responsible for
- inspect the relevant code paths, APIs, data models, jobs, config, and tests
- identify the smallest implementation that satisfies the request
- call out assumptions, blockers, local risks, rollout constraints, and compatibility concerns
- ask concise questions instead of filling important gaps with assumptions

Use Mermaid when it materially clarifies sequencing or state transitions.

Implementation plans should usually use this structure:

# Title

**Status:** Draft / Ready / In Development / In Testing / Implemented / Obsolete / Blocked

**Service:** <service or repository>

**Last Updated:** <date>

## Source Design
Link to the design doc or summarize the approved context.

## Scope
State what this service or repository is responsible for, what is out of scope, and what should not change without asking first.

## Assumptions
List assumptions inherited from the design or discovered in code.

## Dependencies And Contracts
List important upstream and downstream contracts, configs, and sequencing requirements.

## Code Areas
List the relevant files, functions, APIs, data models, configs, jobs, tests, and contracts.
Also list important areas that should be read but not modified.

## Required Changes
Describe the concrete changes grouped by area.

## File-Level Plan
List the files or components expected to change and what should change in each.

## Edge Cases
List service-local edge cases, failure handling, compatibility concerns, and data correctness requirements.

## Tests
List the tests to add or update.

## Verification
List exact commands, checks, or observable outcomes that should verify the implementation.

## Rollout And Rollback
Describe deployment sequencing, flags, migrations, backfills, rollback steps, and operational checks.

## Implementation Checklist
List the expected implementation steps and completed changes in checkbox format.
Leave items unchecked when creating a new plan.

## Open Questions
List only questions that materially affect implementation.
