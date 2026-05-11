---
name: notion
description: Handle Notion-specific formatting, destinations, and publishing rules. Use before any Notion create, update, comment, move, duplicate, or publish workflow.
---

Do not use Notion tools unless the user explicitly asks for a Notion operation.
If the user asks only for chat output, do not write to Notion.

When preparing content for Notion:
- keep each paragraph as a single physical line in the markdown source
- use clear headings
- preserve concise structure
- include Mermaid markdown diagrams as code blocks only when useful
- avoid dumping raw exploration notes
- keep page titles topic-focused and do not include document-type suffixes or prefixes such as `implementation plan`, `architectural design`, `design doc`, or similar labels, because the parent location or section already provides that context
- if the service, repository, or system name is already captured in page metadata, parent context, or surrounding structure, do not repeat it in the title
- return the Notion link or page identifier after the operation (in Markdown format to make it clickable)

Default Notion design destination:
- new design documents should be created as standalone child pages under page ID `35681946d8338030a099da03b518223b`
- when using that default parent page, also update the parent page so the new design is linked under its `Design documents` section
- if the default parent page does not have a `Design documents` section, create that section and add the new design link under it
- do not create design documents as database entries unless the user explicitly asks for a database item
- if the user asks to create a new design document and does not specify a destination, use the default parent page without asking for clarification

Default Notion implementation-plan destination:
- if the user provides a parent design document page, use that page as the parent for the new implementation plan
- create the implementation plan as a standalone child page under the parent design page
- after creating the child page, update the parent page so the child page is linked under an `Implementation plans` section
- if the parent page does not have an `Implementation plans` section, create that section and add the new child page link under it
- if the user does not provide a parent design document page, use page ID `35681946d8338030a099da03b518223b` as the default parent page
- when using the default parent page, also link the new implementation plan under that page's `Implementation plans` section
- do not create implementation plans as database entries unless the user explicitly asks for a database item

If the destination Notion page, database, team, or owner is unclear for an operation other than creating a new design document or implementation plan under the default destination, ask a concise clarifying question.
