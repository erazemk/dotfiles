---
name: slack
description: Send messages, drafts, and read context in Slack. Use when asked to post, send, announce, reply, or draft a Slack message, or to find a channel/user/thread. Covers the send-vs-draft decision, resolving destinations by name, and replying in threads.
user-invocable: false
allowed-tools: mcp__slack__*
---

Use the `mcp__slack__*` tools for all Slack work.

## Send vs draft

- If the user says **send, post, reply, or announce**, send the message once the destination is clear.
- If the user says **draft, prepare, or review**, create a Slack draft instead of sending.
- If another agent or workflow delegates with wording like "post these results to Slack", treat that as permission to send, as long as the destination and message content are clear.
- Do not send duplicate messages.

## Resolving the destination

- If the destination is a channel name or user name rather than an ID, resolve it to an ID first with the Slack search tools (`slack_search_channels` / `slack_search_users`).
- A user ID can be used directly as the `channel_id` to send a DM.

## Threads

- If a thread timestamp (`thread_ts`) is provided, reply in that thread rather than posting a new top-level message.
