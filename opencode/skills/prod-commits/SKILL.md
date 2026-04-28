---
name: prod-commits
description: Compose a Slack promotion message listing commits to promote to prod for an AirSync lambda service. Use when the user wants to promote a service, post a promotion list, or prepare a prod deployment announcement.
disable-model-invocation: true
argument-hint: "[service name]"
---

## Promotion Message

Compose a Slack message announcing which commits will be promoted to production for an AirSync lambda service, so that codeowners can review and approve.

### Step 1: Identify the service

Infer which service we're composing a promotion message for from the current working directory:
   - Check the git remote origin URL for the repo name (e.g. `airdrop-devrev-loader`).
   - Fall back to the directory name.
The **full service name** is the repo name (e.g. `airdrop-devrev-loader`).
This is what appears in the message header.

### Step 2: Find the current production commit

Fetch the production image tags from the starbase repo:

```!
gh api repos/devrev/starbase/contents/devrev/airdrop/prod/input.tf.json --jq '.content' | base64 -d
```

From the JSON output:
1. Derive the image key from the repo name: strip the `airdrop-` prefix, replace `-` with `_`, and append `_image`.
   - Example: `airdrop-devrev-loader` -> `devrev_loader_image`
2. Find that key in the `locals` object.
3. Extract the git tag from the image URI — it's the part after the colon, e.g. `:vf7511b3` -> `f7511b3` (strip the leading `v`).

If the key is not found, tell the user and stop.

### Step 3: Get the commit list

Run `git log` on the current repo's main branch to find all commits newer than the production commit:

```
git log <prod-commit-hash>..origin/main --format="%h [%ad] %s (%an)" --date=short --first-parent
```

Always target `origin/main` explicitly — not `HEAD` — so the result is the same regardless of which branch is currently checked out. Use `--first-parent` to only include commits on the main branch (not merged-in branch commits).

If the prod commit is not found locally, fetch first with `git fetch origin main` and retry.

If there are no new commits, tell the user the service is already up to date.

### Step 4: Identify the current user and codeowners to CC

1. Determine the current user by checking git config (`git config user.name`) or any other available context, and match against the **Service owners** list below.
2. From the codeowners for this service, exclude the current user — they are the one posting.
3. The remaining codeowners should be CC'd using their **Slack usernames** from the lookup table below.

### Step 5: Compose the message

Format the message as follows (Slack mrkdwn syntax):

```
I'd like to promote `<full-service-name>` with:
• <linked-commit-hash> [<commit date>] <commit-subject> (<commit author (git username, not slack mention)>)
• ...

CC: <@SLACK_USER_ID_1> <@SLACK_USER_ID_2> ...
```

Rules for each commit line:
- The commit hash should be a Slack link: `<https://github.com/devrev/<repo-name>/commit/<full-short-hash>|<short-hash>>`
- Use the commit subject (first line of message) as-is.
- Use the commit author's name from `git log` output (not Slack). If the author name is not available, fall back to their GitHub username.

The CC line at the bottom mentions all other codeowners (excluding the poster) using Slack's user mention syntax: `<@USER_ID>` (e.g. `<@U041N4C76BV>`). Use the `slack` field from the service owners list below.

### Step 6: Post or display

Check if a Slack tool for sending/drafting messages is available in this session.

- **If a Slack send/draft tool exists**: compose and send a draft message to channel `C0364R11G4Q` (#airsync-engineering) immediately without asking for confirmation. The user will review the draft in Slack before sending it.
- **If no Slack tool exists**: display the composed message in a markdown code block so the user can copy it and paste it into Slack manually.

---

### Service owners

A map of repo names to their codeowners. Each codeowner entry has a full name, github username, and a Slack display name (for tagging).

```yaml
airdrop-devrev-loader:
  owners:
    - name: "Erazem Kokot"
      github: "erazemk"
      slack: "U041N4C76BV"
    - name: "David Čadež"
      github: "cadezd1"
      slack: "U091JRZCVAN"
    - name: "Branko Raičković"
      github: "Branko3"
      slack: "U09NRRZ3WQ3"

airdrop-devrev-extractor:
  owners:
    - name: "Erazem Kokot"
      github: "erazemk"
      slack: "U041N4C76BV"
    - name: "David Čadež"
      github: "cadezd1"
      slack: "U091JRZCVAN"
    - name: "Branko Raičković"
      github: "Branko3"
      slack: "U09NRRZ3WQ3"
```
