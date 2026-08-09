---
name: plan
description: Plan implementation work with the user and, only on an explicit request to write the plan, persist it as a live checklist in the project. Use whenever developing or updating an implementation plan.
---

Develop plans collaboratively in the current conversation.
Do not write a plan file merely because planning is complete or the user approves a plan.
Only write a plan file after the user explicitly asks to do so, for example, "write the plan."

When explicitly asked to write the plan:

1. Determine the project root and write the plan to `_build/plans/<name>.md` beneath it, creating the directory if needed.
2. Choose `<name>` from the context using one to four lowercase words separated by dashes and ending in `.md`.
3. The plan doesn't have a fixed structure, make it as simple or complex as needed, but if the plan contains actionable items, then additionay include a checklist at the bottom of the plan.
4. Express every actionable item as a Markdown checkbox, initially `- [ ]`.
5. Use separate tasks for implementation, writing tests, and validating changes when each applies.
6. Report the path after writing the plan.

Maintain the written plan as the work progresses:

- Mark a task `- [x]` as soon as that task is complete; an implementation task does not wait for its tests or final validation.
- When the scope changes, update the checklist to match the current requirements.
- Remove completed or remaining tasks that are no longer valid because of the changed scope, and add or revise the tasks now required.
- Treat the file as the current plan and progress record, not as an immutable history.
