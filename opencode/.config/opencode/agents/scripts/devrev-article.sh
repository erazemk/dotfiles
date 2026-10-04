#!/usr/bin/env bash
#
# article — manage the full lifecycle of DevRev knowledge-base articles (ART-*) via the REST API.
#
# The DevRev MCP cannot set an article body: create_article's `content` field is broken
# server-side (missing_required_field: file_name) and update_article has no body/content
# field at all. This script fills that gap end to end (get/create/update/delete/list) so
# the caller never has to think about the underlying artifact/S3 upload plumbing — pass a
# "body" field like any other field, and it's uploaded and wired up automatically.
#
# All OTHER fields (title, description, owned_by, applies_to_parts, tags, status, ...) are
# passed straight through to the DevRev REST API with the exact field names and shapes it
# expects — this script does not reinterpret them. Call the DevRev MCP's `discover_schema`
# tool (action_name='create_article' / 'update_article' / 'list_articles') to learn the
# current field names, required fields, and enum values before building the JSON payloads
# below; note the update schema wraps most array fields in {"set": [...]} while create
# takes plain arrays — that's the REST API's shape, not something this script changes.
#
# Requires: curl, jq, and the `devrev` CLI, authenticated for the target env/org
# (`devrev profiles authenticate -e <env> -o devrev`). The token is fetched fresh on every
# invocation via `devrev profiles get-token access -e <env> -o devrev`.
#
# Usage:
#   article [--env dev|qa|prod] {get|create|update|delete|list} …
#       --env defaults to prod. Use dev/qa to test against a non-prod org first. Must
#       come before the command if given.
#
#   article get <article-id> [--fields field1,field2,...]
#       Prints {title, description, body} by default. `body` is the article's devrev/rt
#       content — the same {"article":{"type":"doc","content":[...]},"artifactIds":[]}
#       shape used by `create`/`update` below — or null if the article has no body.
#       --fields adds raw API fields (as returned by articles.get) alongside the defaults,
#       e.g. --fields status,tags,owned_by,applies_to_parts.
#
#   article create <json-file>
#       <json-file> is a JSON object of fields for articles.create (title, owned_by,
#       applies_to_parts, tags, status, ... — whatever the API accepts), plus an optional
#       "body" field (the devrev/rt shape described above) which gets uploaded as the
#       article's content automatically. Prints {id, display_id, title, description, body}
#       of the created article.
#
#   article update <article-id> <json-file>
#       Like `create`, but only pass the fields you want changed, matching the
#       articles.update API shape (e.g. {"title": "...", "status": "published"}). An
#       optional "body" field replaces the article's content: if the article already has a
#       body artifact, this uploads a NEW VERSION of that SAME artifact (see note below);
#       if it has none yet, this uploads a new artifact and attaches it. Prints the
#       updated article the same way as `create`.
#
#   article delete <article-id>
#
#   article list [--filter <json-file>] [--fields field1,field2,...]
#       <json-file> (if given) is a JSON object of articles.list filter fields (e.g.
#       {"status":["draft"],"applies_to_parts":["PROD-123"],"limit":20,"cursor":"..."}).
#       Prints {total, next_cursor, prev_cursor, articles:[...]} where each entry has
#       {id, display_id, title, parent} by default; --fields adds raw API fields
#       alongside those, e.g. --fields status,owned_by.
#
# <article-id> accepts a display ID (ART-12345) or a full DON (don:core:...:article/...).
#
# Body updates NEVER go through articles.update's `content_artifact` field on an article
# that already has one — pointing an article at a *different* devrev/rt artifact leaves it
# un-renderable in the KB (404s as "item doesn't exist anymore"). Instead this script
# uploads a new version of the EXISTING artifact (artifacts.versions.prepare), which the
# article keeps pointing at unchanged, and which DevRev re-renders/re-indexes correctly.
#
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || die "jq not found"
command -v devrev >/dev/null || die "devrev CLI not found"

DEVREV_ENV="prod"
case "${1:-}" in
  --env) DEVREV_ENV="${2:-}"; shift 2 ;;
  --env=*) DEVREV_ENV="${1#--env=}"; shift ;;
esac

case "$DEVREV_ENV" in
  dev)  API_BASE="https://api.dev.devrev-eng.ai" ;;
  qa)   API_BASE="https://api.qa.devrev-eng.ai" ;;
  prod) API_BASE="https://api.devrev.ai" ;;
  *)    die "invalid --env '$DEVREV_ENV' (allowed: dev, qa, prod)" ;;
esac

TOKEN="$(devrev profiles get-token access -e "$DEVREV_ENV" -o devrev 2>/dev/null)" \
  || die "failed to get a $DEVREV_ENV token via the devrev CLI — run: devrev profiles authenticate -e $DEVREV_ENV -o devrev"
[ -n "$TOKEN" ] || die "devrev CLI returned an empty token for --env $DEVREV_ENV"

api() {  # api <endpoint> <json-body>
  curl -sS -X POST "$API_BASE/$1" \
    -H "Authorization: $TOKEN" -H "Content-Type: application/json" \
    -d "$2"
}

check_error() {  # check_error <api-response> <what> — dies if the response carries a `message`
  local resp="$1" what="$2" msg
  msg="$(printf '%s' "$resp" | jq -r '.message // empty')"
  [ -z "$msg" ] || die "$what failed: $msg"
}

fetch_article() {  # fetch_article <id> — prints the raw `.article` object from articles.get
  local resp
  resp="$(api articles.get "$(jq -n --arg id "$1" '{id:$id}')")"
  check_error "$resp" "articles.get"
  printf '%s' "$resp" | jq '.article'
}

body_artifact_id() {  # body_artifact_id <article-json> — prints the devrev/rt artifact id, or empty
  printf '%s' "$1" | jq -r '.resource.artifacts[]? | select(.file.name=="Article") | .id' | head -1
}

fetch_body() {  # fetch_body <article-json> — prints the devrev/rt body JSON, or `null`
  local article="$1" art_id dl
  art_id="$(body_artifact_id "$article")"
  if [ -z "$art_id" ]; then echo null; return; fi
  dl="$(api artifacts.locate "$(jq -n --arg id "$art_id" '{id:$id}')" | jq -r '.url // empty')"
  [ -n "$dl" ] || die "could not locate download URL for $art_id"
  curl -sS "$dl"
}

# Shared multipart upload: build the form from prepare's form_data (order matters; file
# LAST) and POST it to the presigned S3 URL.
upload_form() {  # upload_form <prepare-response-json> <file>
  local prep="$1" file="$2" up_url form_args=() code
  up_url="$(printf '%s' "$prep" | jq -r '.url')"
  while IFS= read -r kv; do form_args+=(-F "$kv"); done \
    < <(printf '%s' "$prep" | jq -r '.form_data[] | "\(.key)=\(.value)"')
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$up_url" \
    "${form_args[@]}" -F "file=@${file};type=devrev/rt")"
  [ "$code" = "204" ] || die "S3 upload failed (HTTP $code) for $file"
}

upload_new_body() {  # upload_new_body <file> — uploads as a brand-new artifact; prints its id
  local file="$1" prep art_id
  prep="$(api artifacts.prepare '{"file_name":"Article","file_type":"devrev/rt"}')"
  art_id="$(printf '%s' "$prep" | jq -r '.id // empty')"
  [ -n "$art_id" ] && [ -n "$(printf '%s' "$prep" | jq -r '.url // empty')" ] || die "artifacts.prepare failed: $prep"
  upload_form "$prep" "$file"
  printf '%s' "$art_id"
}

upload_body_version() {  # upload_body_version <artifact-id> <file> — new version of an EXISTING artifact
  local artifact_id="$1" file="$2" prep
  prep="$(api artifacts.versions.prepare "$(jq -n --arg id "$artifact_id" '{id:$id}')")"
  [ -n "$(printf '%s' "$prep" | jq -r '.url // empty')" ] || die "artifacts.versions.prepare failed: $prep"
  upload_form "$prep" "$file"
}

# Print {title, description, body} plus any --fields extras for an already-fetched article.
render_article() {  # render_article <article-json> <extra-fields-json-array>
  local article="$1" extra="$2" body
  body="$(fetch_body "$article")"
  jq -n --argjson a "$article" --argjson body "$body" --argjson extra "$extra" \
    '($a | {title, description}) + {body: $body}
     + (reduce $extra[] as $f ({}; . + {($f): $a[$f]}))'
}

# Parse `--fields a,b,c` into a JSON array; prints `[]` if absent.
parse_fields() {  # parse_fields "$@" — reads args looking for --fields
  local val=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --fields) val="${2:-}"; shift 2 ;;
      --fields=*) val="${1#--fields=}"; shift ;;
      *) shift ;;
    esac
  done
  if [ -z "$val" ]; then echo '[]'; else jq -nc --arg v "$val" '$v | split(",")'; fi
}

cmd="${1:-}"; shift || true
case "$cmd" in
  get)
    [ $# -ge 1 ] || die "usage: article get <article-id> [--fields field1,field2,...]"
    id="$1"; shift
    fields="$(parse_fields "$@")"
    article="$(fetch_article "$id")"
    render_article "$article" "$fields"
    ;;

  create)
    [ $# -ge 1 ] || die "usage: article create <json-file>"
    file="$1"
    [ -f "$file" ] || die "file not found: $file"
    input="$(cat "$file")"
    body="$(printf '%s' "$input" | jq 'if has("body") then .body else null end')"
    payload="$(printf '%s' "$input" | jq 'del(.body)')"
    if [ "$body" != null ]; then
      bodyfile="$(mktemp)"; trap 'rm -f "$bodyfile"' EXIT
      printf '%s' "$body" > "$bodyfile"
      art_id="$(upload_new_body "$bodyfile")"
      payload="$(printf '%s' "$payload" | jq --arg a "$art_id" '.resource = ((.resource // {}) + {content_artifact: $a})')"
    else
      payload="$(printf '%s' "$payload" | jq '.resource = (.resource // {})')"
    fi
    resp="$(api articles.create "$payload")"
    check_error "$resp" "articles.create"
    article="$(printf '%s' "$resp" | jq '.article')"
    render_article "$article" '["id","display_id"]'
    ;;

  update)
    [ $# -ge 2 ] || die "usage: article update <article-id> <json-file>"
    id="$1"; file="$2"
    [ -f "$file" ] || die "file not found: $file"
    input="$(cat "$file")"
    body="$(printf '%s' "$input" | jq 'if has("body") then .body else null end')"
    payload="$(printf '%s' "$input" | jq --arg id "$id" 'del(.body) + {id: $id}')"
    if [ "$body" != null ]; then
      current="$(fetch_article "$id")"
      existing_art_id="$(body_artifact_id "$current")"
      bodyfile="$(mktemp)"; trap 'rm -f "$bodyfile"' EXIT
      printf '%s' "$body" > "$bodyfile"
      if [ -n "$existing_art_id" ]; then
        upload_body_version "$existing_art_id" "$bodyfile"
      else
        new_art_id="$(upload_new_body "$bodyfile")"
        payload="$(printf '%s' "$payload" | jq --arg a "$new_art_id" '. + {content_artifact: $a}')"
      fi
    fi
    if [ "$(printf '%s' "$payload" | jq 'keys | length')" -gt 1 ]; then
      resp="$(api articles.update "$payload")"
      check_error "$resp" "articles.update"
    fi
    article="$(fetch_article "$id")"
    render_article "$article" '["id","display_id"]'
    ;;

  delete)
    [ $# -ge 1 ] || die "usage: article delete <article-id>"
    resp="$(api articles.delete "$(jq -n --arg id "$1" '{id:$id}')")"
    check_error "$resp" "articles.delete"
    echo "deleted $1"
    ;;

  list)
    filter='{}'
    fields='[]'
    while [ $# -gt 0 ]; do
      case "$1" in
        --filter) [ -f "${2:-}" ] || die "usage: article list [--filter <json-file>] [--fields field1,field2,...]"
                  filter="$(cat "$2")"; shift 2 ;;
        --fields) fields="$(parse_fields --fields "${2:-}")"; shift 2 ;;
        *) die "unknown argument: $1" ;;
      esac
    done
    resp="$(api articles.list "$filter")"
    check_error "$resp" "articles.list"
    jq --argjson extra "$fields" \
      '{total, next_cursor, prev_cursor,
        articles: [.articles[] as $a | ($a | {id, display_id, title, parent})
          + (reduce $extra[] as $f ({}; . + {($f): $a[$f]}))]}' \
      <<< "$resp"
    ;;

  *)
    die "unknown command: '${cmd}'. Run with: get | create | update | delete | list"
    ;;
esac
