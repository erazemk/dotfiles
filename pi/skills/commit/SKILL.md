---
name: commit
description: "Read this skill before making git commits"
disable-model-invocation: true
---

Create a git commit for the current changes following the conventions below.

## Subject Line

`<type>: <summary>`

- `type` REQUIRED. Use `feat` for new features, `fix` for bug fixes. Other types: `chore`, `test`, `docs`, `refactor`.
- `summary` REQUIRED. Short, imperative, capitalized first word, <= 72 chars, no trailing period.
- Do NOT include issue IDs (e.g. `ISS-XXXXXX`) in the subject line — they belong in the body.
- Do NOT include a scope in parentheses.

## Body

The body MUST contain at least the full issue link on its own line:

```
https://app.devrev.ai/devrev/works/ISS-XXXXXX
```

For non-trivial changes (new features, bug fixes with interesting context, refactors), add a description above the issue link. Follow these writing guidelines:

### Tone and Style

- Start the first paragraph with "This commit ..." followed by a verb (adds, updates, fixes, enables, makes, switches, sets, removes, splits, etc.).
- Write in a direct, matter-of-fact, technical tone.
- Always explain both *what* changed and *why* — never just what.
- Use "we" for team decisions or conventions ("we needed to switch", "we should import as much data as possible") and "I" sparingly when it's a personal judgment call ("I removed the header because...").
- Casual asides are fine when they add clarity: "nasty bug", "Luckily", parenthetical context like "(or rather a misunderstanding)".
- Mention future work, trade-offs, or limitations when relevant: "Other object types will be supported in a separate PR", "This is just a temporary workaround".
- Keep lines wrapped at ~72 characters.

### Structure for Complex Changes

1. **First paragraph**: "This commit [does X]" — the core change.
2. **Additional paragraphs**: context, reasoning, trade-offs, caveats, what is NOT changed or out of scope.
3. **Issue link**: always last.

### Examples

Simple change:
```
fix: Fall back to "other" meeting channel

This commit sets the meeting channel for meetings that don't have it
set to "other", so that such meetings are successfully imported.

https://app.devrev.ai/devrev/works/ISS-242818
```

Complex change:
```
feat: Support Redis locking per-object-type

This commit adds support for locking individual objects through Redis
locks instead of just object types, to prevent locking of loading
objects between different loaders, which is slowing down syncs a lot.

By default this is off, but it's enabled through a feature flag.
Deletions still lock whole object types.

https://app.devrev.ai/devrev/works/ISS-261375
```

Bug fix with context:
```
fix: Don't fail if failing to create parts of policies

This commit updates the handling of authorization policies to continue,
even if parts of the policy (e.g. roles, role sets, ACEs) failed.
This is done so that we are consistent with the rule that we should
import as much data as possible and it's also ok from a security
standpoint, since it doesn't result in users getting more permissions.

The commit also updates the deletion order when deleting old permissions
and it also prevents the deletion of old permissions if any parts of
the policy failed to import, so that we have to have a successful sync
before old permissions are deleted.

https://app.devrev.ai/devrev/works/ISS-160146
```

Trivial change:
```
chore: Switch to Chainguard images

https://app.devrev.ai/devrev/works/ISS-179734
```

## Notes

- Do NOT include sign-offs (no `Signed-off-by`).
- Do NOT include breaking-change markers or footers.
- Only commit; do NOT push.
- Treat any caller-provided arguments as additional commit guidance.

## Steps

1. Run `git status` to check for staged changes.
   - If there ARE staged changes, only commit those (do NOT stage anything else).
   - If there are NO staged changes, stage all uncommitted changes.
2. Review `git diff --cached` to understand what will be committed.
3. If there are ambiguous extra files (only when staging everything), ask the user for clarification before committing.
4. Decide whether a body description is needed (trivial changes can skip it, but the issue link is always required).
5. Run `git commit` with the formatted message.
