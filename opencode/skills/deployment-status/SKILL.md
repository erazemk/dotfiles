---
name: deployment-status
description: Show which AirSync lambda commits are deployed across Starbase environments and regions for a service. Use when the user asks which commit is in dev, qa, prod, or any Starbase environment for a lambda service.
---

## Deployment Status

Report which commit of an AirSync lambda service is deployed in each Starbase environment and region.

The bundled script uses AWS Lambda as the source of truth for the deployed image tag, then GitHub for commit metadata. Your job is only to determine the service name before running it.

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
~/.config/opencode/skills/deployment-status/scripts/deployment-status <service-name>
```

Example:

```bash
~/.config/opencode/skills/deployment-status/scripts/deployment-status airdrop-devrev-loader
```

Optional flags:

```bash
~/.config/opencode/skills/deployment-status/scripts/deployment-status --profile qa --region us-east-1 airdrop-devrev-loader
~/.config/opencode/skills/deployment-status/scripts/deployment-status --debug airdrop-devrev-loader
```

### Script Behavior

The script:

- Requires `aws`, `gh`, and `jq`.
- Uses `aws lambda get-function` as the source of truth for the deployed image tag.
- Parses the AWS Lambda JSON response with `jq`.
- Uses `gh api` for commit metadata from `devrev/<service>`.
- Extracts the deployed commit from `Code.ImageUri`, stripping a leading `v` if present.
- Includes the Lambda `Configuration.LastModified` timestamp in the output.
- Compares the deployed commit to remote `main` with the GitHub compare API.
- Supports `--profile`, `--region`, and `--debug`.
- If `--region ap-northeast-1` is passed without `--profile`, uses AWS profile `prodjp`.
- If `--profile prodjp` is passed without `--region`, uses `ap-northeast-1`.
- Defaults to an overview across these environment and region combinations when no profile or region is provided:
- `dev`: `us-east-1`, trying AWS profiles `dev` then `default`
- `qa`: `us-east-1`, `ap-south-1`
- `pre-prod`: `ap-southeast-1` using AWS profile `prod`
- `prod`: `us-east-1`, `ap-south-1`, `ap-southeast-2`, `eu-central-1` using AWS profile `prod`, and `ap-northeast-1` using AWS profile `prodjp`
- Silently skips missing AWS profiles during normal execution.
- In `--debug`, logs AWS errors and fails if neither `dev` nor `default` exists for the `dev` overview lookup.
- If AWS returns `Error when retrieving token from sso: Token has expired and refresh failed`, runs `aws sso login --profile <profile>` and retries.

### Response

Return the script output directly.

If the script fails because `gh` is missing or unauthenticated, tell the user to run `gh auth login` and retry.
