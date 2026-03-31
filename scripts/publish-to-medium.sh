#!/bin/bash
# Publish blog post to Medium

set -euo pipefail
POST_FILE="${1:?Usage: $0 <post-file>}"

if [ ! -f "$POST_FILE" ]; then
  echo "❌ Post file not found: $POST_FILE"
  exit 1
fi

echo "📝 Publishing to Medium..."

# Extract frontmatter
TITLE=$(grep '^title:' "$POST_FILE" | sed 's/title: //' | tr -d '"')
CONTENT=$(sed -n '/^---$/,/^---$/!p' "$POST_FILE" | tail -n +2)

# Medium API requires token (set MEDIUM_TOKEN)
if [ -z "${MEDIUM_TOKEN:-}" ]; then
  echo "⚠️  MEDIUM_TOKEN not set. Set via: export MEDIUM_TOKEN=your_token"
  echo "   Get token from: https://medium.com/me/settings"
  exit 1
fi

# Get user ID
USER_ID=$(curl -s "https://api.medium.com/v1/me" \
  -H "Authorization: Bearer $MEDIUM_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.data.id')

echo "   User ID: $USER_ID"

# Post to Medium
RESPONSE=$(curl -s -X POST "https://api.medium.com/v1/users/$USER_ID/posts" \
  -H "Authorization: Bearer $MEDIUM_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"$TITLE\",
    \"contentFormat\": \"markdown\",
    \"content\": $(echo "$CONTENT" | jq -R -s .),
    \"publishStatus\": \"draft\"
  }")

POST_URL=$(echo "$RESPONSE" | jq -r '.data.url')

if [ "$POST_URL" != "null" ] && [ -n "$POST_URL" ]; then
  echo "✅ Posted to Medium: $POST_URL"
  exit 0
else
  echo "❌ Medium post failed"
  echo "$RESPONSE" | jq .
  exit 1
fi
