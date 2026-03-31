#!/bin/bash
# Publish blog post to Dev.to via API

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POST_FILE="${1:?Usage: $0 <post_file>}"
LOG_DIR="$PROJECT_DIR/logs"
DEVTO_API_KEY="${DEVTO_API_KEY:-}"

mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_DIR/devto-publish.log"; }

log "📤 Dev.to Publisher"

if [ -z "$DEVTO_API_KEY" ]; then
  if [ -f "$PROJECT_DIR/.devto-key" ]; then
    DEVTO_API_KEY=$(cat "$PROJECT_DIR/.devto-key" 2>/dev/null)
  fi
fi

if [ -z "$DEVTO_API_KEY" ]; then
  log "❌ Dev.to API key not found. Set DEVTO_API_KEY env var."
  exit 1
fi

if [ ! -f "$POST_FILE" ]; then
  log "❌ Post file not found: $POST_FILE"
  exit 1
fi

# Extract title (from frontmatter)
TITLE=$(sed -n 's/^title: "\(.*\)".*/\1/p' "$POST_FILE" | head -1)

# Extract body (everything after the closing ---)
BODY=$(sed '1,/^---$/d' "$POST_FILE" | sed '/^---$/d')

log "   Title: $TITLE"
log "   Publishing to Dev.to..."

# Create JSON payload using jq to properly escape everything
PAYLOAD=$(jq -n \
  --arg title "$TITLE" \
  --arg body "$BODY" \
  '{article: {title: $title, body_markdown: $body, published: true}}')

# Post to Dev.to
HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/devto-response.json \
  -X POST https://dev.to/api/articles \
  -H "api-key: $DEVTO_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  ARTICLE_URL=$(jq -r '.url // empty' /tmp/devto-response.json 2>/dev/null)
  if [ -n "$ARTICLE_URL" ]; then
    log "✅ Published to Dev.to"
    log "   URL: $ARTICLE_URL"
    echo "$ARTICLE_URL"
    rm -f /tmp/devto-response.json
    exit 0
  fi
fi

log "❌ Failed (HTTP $HTTP_CODE)"
cat /tmp/devto-response.json 2>/dev/null | jq '.' 2>/dev/null | head -20 | tee -a "$LOG_DIR/devto-publish.log"
rm -f /tmp/devto-response.json
exit 1
