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
3. The plan doesn't have a fixed structure, make it as simple or complex as needed, but it should contain everything another agent would need to implement the feature, including why unobvious decisions were made, all the edge cases that were mentioned, all the deferred decisions, any work that needs to be done in other repositories etc.
4. At the bottom of the plan file, in a checklist section, every actionable item should be added as a Markdown checkbox, initially `- [ ]`.
5. A checklist alone is not a plan, a plan requires explaining intent behind changes and additional context, not just a list of tasks.
6. Add separate tasks for implementation, writing tests, and validating changes when each applies.
7. Report the path after writing the plan.

Maintain the written plan as the work progresses:

- Mark a task `- [x]` as soon as that task is complete; an implementation task does not wait for its tests or final validation.
- When the scope changes, update the checklist to match the current requirements.
- Remove completed or remaining tasks that are no longer valid because of the changed scope, and add or revise the tasks now required.
- Treat the file as the current plan and progress record, not as an immutable history.
