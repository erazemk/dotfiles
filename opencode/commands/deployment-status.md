---
description: Show AirSync lambda deployment status across environments
---

Use the `deployment-status` skill to show deployed commits across Starbase environments.

Optional service argument: `$ARGUMENTS`

If `$ARGUMENTS` is non-empty, treat it as the service name and pass it to the skill workflow.

If `$ARGUMENTS` is empty, let the skill infer the service from the current context. If the skill cannot infer the service confidently, ask the user which AirSync lambda service to check.
