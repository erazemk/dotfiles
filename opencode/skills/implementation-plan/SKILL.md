---
name: implementation-plan
description: Create concrete service-specific implementation plans from a feature request or approved design. Use when the user asks for an implementation plan, rollout plan, checklist, or file-level execution plan.
---

Your job is to read the relevant source design or feature context, inspect the current code and constraints, ask concise clarifying questions when needed, and produce a practical implementation plan.

Prefer short, direct writing.
Avoid filler, generic best-practice lists, and restating obvious context.
Every section should reduce ambiguity for the implementer.

When the request is ambiguous, ask concise clarifying questions before writing the plan.
Ask especially about the source design, target service or repository, ownership boundaries, rollout constraints, compatibility requirements, migration or backfill needs, testing expectations, and service boundaries.
If the request spans multiple services or repositories, create one implementation plan per service.

Before proposing an implementation plan:
- read the source design and identify the exact behavior this service is responsible for
- inspect the relevant current code paths, APIs, data models, background jobs, configuration, tests, and operational hooks
- explore the relevant parts of the codebase before planning
- identify the smallest implementation that satisfies the design
- explicitly call out assumptions, blockers, and local risks
- prefer incremental rollout and easy rollback
- keep the plan grounded in the current codebase rather than restating the design in abstract terms
- do not reopen settled product or architecture decisions unless the code reveals a concrete implementation blocker
- right-size the plan to the change
- stop and ask questions instead of filling important gaps with assumptions
- avoid full code snippets unless they are necessary to define an API contract, schema, or algorithm

Use Mermaid diagrams when they materially clarify execution order, state transitions, or migration sequencing.

Implementation plans should usually use this structure:

# Title

**Status:** Draft / Ready / In Development / In Testing / Implemented / Obsolete / Blocked

**Service:** <service or repository>

**Last Updated:** <date>

## Source Design
Link to the design doc or summarize the approved design context that this plan implements.

## Scope
State exactly what this service or repository is responsible for.

## Scope Boundaries
List what is in scope, what is out of scope, and what the coding agent should not change without asking first.

## Assumptions
List assumptions inherited from the design or discovered in code.

## Dependencies And Contracts
List upstream and downstream service contracts, API expectations, event shapes, data dependencies, feature flags, config dependencies, and sequencing requirements.

## Impact Map
List the files, packages, APIs, configs, jobs, tests, dashboards, and external contracts this implementation is expected to touch.
Also list important files or areas that should be read but not modified.

## Current Code Paths
List the relevant files, functions, APIs, jobs, data models, configs, and tests.
Include code references when useful.

## Required Changes
Describe the concrete changes grouped by area.

## File-Level Plan
List the files or components expected to change and what should change in each.

## Edge Cases
List service-local edge cases, failure handling, compatibility concerns, and data correctness requirements.

## Tests
List the tests to add or update.
Include unit, integration, migration, regression, and manual verification where relevant.

## Verification
List exact commands, checks, or observable outcomes that should verify the implementation.

## Rollout And Rollback
Describe deployment sequencing, flags, migrations, backfills, rollback steps, and operational checks.

## Implementation Checklist
List the expected implementation steps and completed changes in checkbox format.
Leave items unchecked when creating a new plan.
Only mark items complete when implementation has been confirmed.

## Open Questions
List only questions that materially affect implementation.
