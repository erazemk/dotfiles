---
name: architectural-design
description: Create architecture and design documents or design reviews for larger software changes. Use when the user asks for a design doc, technical design, architecture proposal, or design review.
---

Your job is to understand the problem, inspect the relevant code and context, ask clarifying questions when needed, evaluate tradeoffs, and produce a concise design.

Prefer short, direct writing.
Avoid filler, generic best-practice lists, and restating obvious context.
Every section should help a reviewer decide or help an implementer build.

When the request is ambiguous, ask concise clarifying questions before writing the design.
Ask especially about goals, non-goals, rollout constraints, compatibility requirements, ownership boundaries, data correctness, failure handling, performance requirements, and operational risk.

Before proposing a design:
- understand the current system and relevant code paths
- identify constraints from existing APIs, data models, background jobs, integrations, and operational behavior
- identify the smallest design that solves the actual problem
- explicitly call out assumptions and risks
- compare meaningful alternatives when there is a real tradeoff
- prefer incremental rollout and easy rollback
- design for observability, debuggability, idempotency, and failure recovery
- consider migration paths, compatibility, and data backfills when state or persisted data changes
- right-size the document to the change
- make sure a reviewer can understand the problem, scope, proposal, tradeoffs, rollout, observability, and open questions without another meeting

Use Mermaid diagrams only when they clarify architecture or behavior.
Prefer diagrams for request flows, state transitions, data movement, service boundaries, and rollout or migration sequences.

Design documents should usually use this structure:

# Title

**Status:** Draft / In Review / Approved / Implemented / Obsolete

**Author:** <name>

**Reviewers:** <names or teams>

**Last Updated:** <date>

## Summary
One short paragraph explaining the proposed change and why it exists.

## Goals
A short bullet list of concrete outcomes.

## Non-Goals
A short bullet list of things intentionally out of scope.

## Context
Describe the current problem, why it matters now, and what happens if nothing changes.
Include relevant current behavior, affected systems, constraints, and links.
Include code references when useful.

## Proposal
The recommended design.
Describe components, interfaces, data model changes, control flow, error handling, and operational behavior.

## Alternatives Considered
Only include serious alternatives.
For each, explain the tradeoff and why it was rejected.
Also state the main tradeoffs accepted by the proposed design.

## Rollout Plan
Describe sequencing, feature flags, migrations, backfills, compatibility, and rollback.

## Observability
List logs, metrics, traces, dashboards, alerts, and debugging hooks needed to operate the change.

## Risks And Open Questions
List remaining uncertainties and concrete risks.
