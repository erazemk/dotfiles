#!/usr/bin/env bash
#
# article-body.sh — read and write DevRev article bodies (devrev/rt) via the REST API.
#
# The DevRev MCP cannot set or update an article body: create_article's `content`
# field is broken server-side (missing_required_field: file_name) and update_article
# has no body/content field at all. Bodies live in a `devrev/rt` artifact referenced
# by the article's resource. This script does the artifacts.prepare -> S3 upload ->
# resource-reference dance that the API requires.
#
# Requires: curl, jq, and $DEVREV_API_KEY (raw token, NO "Bearer" prefix).
#
# Usage:
#   article-body.sh get <article-id>
#       Print the article's raw devrev/rt body JSON ({article:{doc...},artifactIds:[]})
#       to stdout. Use this to inspect structure before editing.
#
#   article-body.sh upload <rt-json-file>
#       Upload a devrev/rt JSON file as a new artifact. Prints the new artifact DON id.
#       Low-level; prefer `set` / `create` below.
#
#   article-body.sh set <article-id> <rt-json-file>
#       Upload <rt-json-file> as a new body artifact and point the article at it.
#       This is the UPDATE-body operation.
#
#   article-body.sh create <rt-json-file> <title> <owner-id> <part-id> [status]
#       Create a new article whose body is <rt-json-file>. status defaults to "draft".
#       Prints the new article's id / display_id.
#
# <article-id> accepts a full DON (don:core:...:article/<n>) or a bare numeric id.
#
set -euo pipefail

API_BASE="https://api.devrev.ai"

die() { echo "error: $*" >&2; exit 1; }
[ -n "${DEVREV_API_KEY:-}" ] || die "DEVREV_API_KEY is not set"
command -v jq >/dev/null || die "jq not found"

# Normalize a possibly-bare article id into a full DON.
article_don() {
  case "$1" in
    don:*) printf '%s' "$1" ;;
    ART-*) printf 'don:core:dvrv-us-1:devo/0:article/%s' "${1#ART-}" ;;
    *)     printf 'don:core:dvrv-us-1:devo/0:article/%s' "$1" ;;
  esac
}

api() {  # api <endpoint> <json-body>
  curl -sS -X POST "$API_BASE/$1" \
    -H "Authorization: $DEVREV_API_KEY" -H "Content-Type: application/json" \
    -d "$2"
}

# Upload a devrev/rt file as an artifact; echo the new artifact DON id.
upload_rt() {
  local file="$1"
  [ -f "$file" ] || die "file not found: $file"
  local prep art_id up_url
  prep="$(api artifacts.prepare '{"file_name":"Article","file_type":"devrev/rt"}')"
  art_id="$(printf '%s' "$prep" | jq -r '.id // empty')"
  up_url="$(printf '%s' "$prep" | jq -r '.url // empty')"
  [ -n "$art_id" ] && [ -n "$up_url" ] || die "artifacts.prepare failed: $prep"

  # Build the multipart form from prepare's form_data (order matters; file LAST).
  local form_args=()
  while IFS= read -r kv; do form_args+=(-F "$kv"); done \
    < <(printf '%s' "$prep" | jq -r '.form_data[] | "\(.key)=\(.value)"')

  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$up_url" \
    "${form_args[@]}" -F "file=@${file};type=devrev/rt")"
  [ "$code" = "204" ] || die "S3 upload failed (HTTP $code) for $file"
  printf '%s' "$art_id"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  get)
    [ $# -ge 1 ] || die "usage: article-body.sh get <article-id>"
    don="$(article_don "$1")"
    body_art="$(api articles.get "{\"id\":\"$don\"}" \
      | jq -r '.article.resource.artifacts[]? | select(.file.name=="Article") | .id' | head -1)"
    [ -n "$body_art" ] || die "no body (devrev/rt) artifact found on $don"
    dl="$(api artifacts.locate "{\"id\":\"$body_art\"}" | jq -r '.url // empty')"
    [ -n "$dl" ] || die "could not locate download URL for $body_art"
    curl -sS "$dl"
    ;;
  upload)
    [ $# -ge 1 ] || die "usage: article-body.sh upload <rt-json-file>"
    upload_rt "$1"; echo
    ;;
  set)
    [ $# -ge 2 ] || die "usage: article-body.sh set <article-id> <rt-json-file>"
    don="$(article_don "$1")"
    art_id="$(upload_rt "$2")"
    # NOTE: update uses top-level artifacts.set — NOT resource (which create uses).
    api articles.update "{\"id\":\"$don\",\"artifacts\":{\"set\":[\"$art_id\"]}}" \
      | jq '{id: .article.id, display_id: .article.display_id, resource: .article.resource, error: .message}'
    ;;
  create)
    [ $# -ge 4 ] || die "usage: article-body.sh create <rt-json-file> <title> <owner-id> <part-id> [status]"
    file="$1"; title="$2"; owner="$3"; part="$4"; status="${5:-draft}"
    art_id="$(upload_rt "$file")"
    api articles.create "$(jq -n \
      --arg t "$title" --arg o "$owner" --arg p "$part" --arg s "$status" --arg a "$art_id" \
      '{title:$t, owned_by:[$o], applies_to_parts:[$p], status:$s, resource:{artifacts:[$a]}}')" \
      | jq '{id: .article.id, display_id: .article.display_id, resource: .article.resource, error: .message}'
    ;;
  *)
    die "unknown command: '${cmd}'. Run with: get | upload | set | create"
    ;;
esac
