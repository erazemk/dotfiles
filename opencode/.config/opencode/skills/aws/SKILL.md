---
name: aws
description: AirSync AWS and S3 work. Use proactively whenever a task involves the AWS CLI, S3, or constructing an S3 path from a SyncContext.
---

## SSO credentials

If an `aws` command fails because SSO credentials are expired, refresh them automatically with `aws sso login` in the same turn and retry before reporting a blocker.

## AirSync sync context → S3 path

AirSync service read and write S3 files under a prefix derived from the run's `SyncContext`. The prefix format depends on whether `V3PathFormat` is enabled and the run's mode.

### Bucket

`devrev-<env>-airdrop-data`, where `<env>` is `dev`, `qa`, or `prod`.

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

# external-sync-unit level (to-devrev modes: initial, sync_to_devrev)
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
- `ExternalSystemName` — `external_system_name`.
- `ExternalSystemID` — `source_id`.
- `ExternalSyncUnitID` — `source_unit_id`.
- `SyncUnitID` — `migration_unit_id`.
- `DevUserID` — `dev_user_id`
- `SnapInSlug` / `ImportSlug` — `snap_in_slug` / `import_slug`, present only for ADaaS sources.

So a full object key is `s3://devrev-<env>-airdrop-data/<key-prefix>/<object-name>`.
To inspect a run's S3 data, build the prefix from the run's sync context and list under it, e.g. `aws s3 ls s3://devrev-dev-airdrop-data/<prefix>/`.
