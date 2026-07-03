---
name: aws
description: AWS CLI usage at DevRev. Use when running any `aws` CLI command, especially `aws s3` against the airdrop data buckets or when mapping sync contexts to S3 paths.
user-invocable: false
---

## SSO credentials

If an `aws` command fails because SSO credentials are expired, refresh them automatically in the same turn and retry before reporting a blocker.

- Default profile: run `aws sso login`, then retry the original command.
- Specific profile: run `aws sso login --profile <profile>`, then retry with the same profile.
- If SSO requires an interactive browser login that you cannot complete, ask the user to run it (e.g. `! aws sso login`) and retry only after they confirm.

## Airdrop sync context → S3 path

Airdrop and AirSync are the same system.
The DevRev Loader reads transformer files and reads/writes run state under an S3 prefix derived from the run's `SyncContext`.
Source of truth: `core/model/context_additional_fields.go` in `github.com/devrev/airdrop-common` (the `*LevelPath*` methods).

### Bucket

`devrev-<env>-airdrop-data`, where `<env>` is `dev`, `qa`, or `prod` (see `cmd/local/main.go`).

### Key prefix

The prefix is built from `SyncContext` fields and depends on the **path format** (`AdditionalFields.V3PathFormat`) and the **mode** (`GetMode()`: defaults to `initial`; `sync_from_devrev` appends `from_devrev`).

V2 (legacy, the default when `V3PathFormat` is unset):

```
# external-system, all-users level (where mappers live)
{DevOrgID}/{ExternalSystemType}/{ExternalSystemID}
# ADaaS sources insert the slugs:
{DevOrgID}/{ExternalSystemType}/{SnapInSlug}/{ImportSlug}/{ExternalSystemID}

# external-system level (adds the dev user)
.../{DevUserID}

# external-sync-unit level (to-devrev modes: initial, sync_to_devrev) — this is the loader's working prefix
.../{ExternalSyncUnitID}

# from-devrev mode appends:
.../from_devrev
```

V3 (when `V3PathFormat` is set; requires `ExternalSystemName`):

```
# external-system level
{DevOrgID}/{ExternalSystemName}/{ExternalSystemID}

# external-sync-unit level (to-devrev)
.../{ExternalSyncUnitID}/{SyncUnitID}

# from-devrev mode appends:
.../from_devrev
```

Structured run logs live at `{external-sync-unit-level prefix}/logs/{RunId}`.

### Field glossary

- `DevOrgID` — `dev_org_id` in the sync context.
- `ExternalSystemType` — `source_type` (e.g. `ADaaS`).
- `ExternalSystemName` — `external_system_name` (V3 only).
- `ExternalSystemID` — `source_id`.
- `ExternalSyncUnitID` — `source_unit_id`.
- `SyncUnitID` — `migration_unit_id` (V3 only).
- `DevUserID` — `dev_user_id` (V2 only).
- `SnapInSlug` / `ImportSlug` — `snap_in_slug` / `import_slug`, present only for ADaaS sources.

So a full object key is `s3://devrev-<env>-airdrop-data/<key-prefix>/<object-name>`.
To inspect a run's S3 data, build the prefix from the run's sync context and list under it, e.g. `aws s3 ls s3://devrev-dev-airdrop-data/<prefix>/`.
