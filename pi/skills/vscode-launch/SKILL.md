---
name: vscode-launch
description: Generate a VS Code launch configuration for airdrop-devrev-loader from a Datadog log JSON and insert it into .vscode/launch.json. Use when you need a local launch config from a Datadog log payload.
disable-model-invocation: true
---

# Launch Config from Datadog Log

Creates a new VS Code launch configuration using fields from a Datadog log JSON payload. It fills required loader flags and only includes non-default optional flags (no service URLs). The script always sets:

- `--event=LOAD_MIGRATION_UNIT_CONTINUE`
- `--with-debug-logs`
- `--incremental`

## Usage

From the repo root (or any subdirectory inside it):

```bash
~/.agents/skills/vscode-launch/scripts/dd-to-launch /path/to/log.json
```

Or pipe JSON from stdin:

```bash
cat /path/to/log.json | ~/.agents/skills/vscode-launch/scripts/dd-to-launch -
```

## Notes

- Configuration name format: `external_system_name - external_system_id`.
- The script inserts a new configuration block into `.vscode/launch.json` without reformatting the file.
- If a configuration with the same name already exists, the script exits without changes.
