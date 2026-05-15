---
name: architectural-design
description: Create architecture and design documents or design reviews for larger software changes. Use when the user asks for a design doc, technical design, architecture proposal, or design review.
---

Understand the problem, inspect the relevant code and context, ask concise clarifying questions when needed, evaluate tradeoffs, and produce a concise design.

Prefer short, direct writing.

Before writing the design:
- understand the current system and relevant code paths
- identify constraints from existing APIs, data models, jobs, integrations, and operational behavior
- identify the smallest design that solves the actual problem
- call out assumptions, risks, rollout constraints, compatibility concerns, and meaningful tradeoffs
- compare alternatives only when there is a real decision to make

Use Mermaid only when it materially clarifies behavior or rollout.

Design documents should usually use this structure:

# Title

**Status:** Draft / In Review / Approved / Implemented / Obsolete

**Author:** <name>

**Reviewers:** <names or teams>

**Last Updated:** <date>

## Summary
One short paragraph explaining the proposed change and why it exists.

## Goals
Concrete outcomes.

## Non-Goals
Things intentionally out of scope.

## Context
Describe the current problem, why it matters now, and what happens if nothing changes.
Include relevant current behavior, affected systems, constraints, and links.

## Proposal
Describe components, interfaces, data model changes, control flow, error handling, and operational behavior.

## Alternatives Considered
Only include serious alternatives.
Explain the tradeoff and why each was rejected.

## Rollout Plan
Describe sequencing, feature flags, migrations, backfills, compatibility, and rollback.

## Observability
List logs, metrics, traces, dashboards, alerts, and debugging hooks needed to operate the change.

## Risks And Open Questions
List remaining uncertainties and concrete risks.
