#!/bin/bash
# Publish blog post to Substack

set -euo pipefail
POST_FILE="${1:?Usage: $0 <post-file>}"

if [ ! -f "$POST_FILE" ]; then
  echo "❌ Post file not found: $POST_FILE"
  exit 1
fi

echo "📬 Publishing to Substack..."

# Extract frontmatter
TITLE=$(grep '^title:' "$POST_FILE" | sed 's/title: //' | tr -d '"')
CONTENT=$(sed -n '/^---$/,/^---$/!p' "$POST_FILE" | tail -n +2)

# Substack API (requires publication ID + API key)
if [ -z "${SUBSTACK_API_KEY:-}" ]; then
  echo "⚠️  SUBSTACK_API_KEY not set"
  echo "   1. Get API key from Substack settings"
  echo "   2. Find publication ID"
  echo "   3. Set: export SUBSTACK_API_KEY=your_key"
  echo "   4. Set: export SUBSTACK_PUB_ID=your_pub_id"
  exit 1
fi

SUBSTACK_PUB_ID="${SUBSTACK_PUB_ID:-}"
if [ -z "$SUBSTACK_PUB_ID" ]; then
  echo "❌ SUBSTACK_PUB_ID not set"
  exit 1
fi

# Post via Substack API
RESPONSE=$(curl -s -X POST "https://api.substack.com/publication/$SUBSTACK_PUB_ID/drafts" \
  -H "Authorization: Bearer $SUBSTACK_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"$TITLE\",
    \"body_html\": $(echo "$CONTENT" | jq -R -s .),
    \"publish_now\": false
  }")

DRAFT_ID=$(echo "$RESPONSE" | jq -r '.id' 2>/dev/null || echo "")

if [ -n "$DRAFT_ID" ] && [ "$DRAFT_ID" != "null" ]; then
  echo "✅ Posted to Substack (Draft): ID $DRAFT_ID"
  echo "   Visit: https://substack.com/@apexcrispwave to publish"
  exit 0
else
  echo "❌ Substack post failed"
  echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
  exit 1
fi
