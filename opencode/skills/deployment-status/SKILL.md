---
name: deployment-status
description: Show which AirSync lambda commits are deployed across Starbase environments and regions for a service. Use when the user asks which commit is in dev, qa, prod, or any Starbase environment for a lambda service.
---

## Deployment Status

Report which commit of an AirSync lambda service is deployed in each Starbase environment and region.

The bundled script does all remote Starbase and GitHub lookups. Your job is only to determine the service name before running it.

### Step 1: Determine The Service

Resolve the full service/repo name, such as `airdrop-devrev-loader`.

Use this order:

1. Prefer the service name explicitly provided by the user.
2. If no service was provided, infer it from the current git remote origin repo basename, for example `git@github.com:devrev/airdrop-devrev-loader.git` -> `airdrop-devrev-loader`.
3. If there is no useful remote, infer it from the current repository root basename.
4. If that is unavailable, infer it from the current working directory basename.
5. If the inferred value is generic or uncertain, such as `DevRev`, `starbase`, or `airdrop`, ask: `Which AirSync lambda service should I check?`

Only run the script after a concrete service name is known.

### Step 2: Run The Script

Run the bundled script with the resolved service name:

```bash
~/.config/opencode/skills/deployment-status/scripts/starbase <service-name>
```

Example:

```bash
~/.config/opencode/skills/deployment-status/scripts/starbase airdrop-devrev-loader
```

### Script Behavior

The script:

- Uses `gh api` for all GitHub data.
- Does not read local `starbase` files.
- Does not use local git branches, local refs, local commit history, `git fetch`, or `git log`.
- Discovers `devrev/airdrop/**/input.tf.json` files from remote `devrev/starbase` `main`.
- Treats `devrev/airdrop/<env>/input.tf.json` as region `us-east-1`.
- Treats `devrev/airdrop/<env>/<region>/input.tf.json` as that explicit region.
- Extracts the deployed commit from the lambda image tag, stripping a leading `v` if present.
- Resolves the deployed commit title from remote `devrev/<service>`.
- Compares the deployed commit to remote `main` with the GitHub compare API.

### Response

Return the script output directly.

If the script fails because `gh` is missing or unauthenticated, tell the user to run `gh auth login` and retry.
