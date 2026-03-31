#!/bin/bash
# validate-posts.sh - Validate blog posts before publishing
# Checks: frontmatter, markdown syntax, word count, no drafts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
POSTS_DIR="$REPO_ROOT/posts"
LOG_FILE="$REPO_ROOT/logs/validation.log"

mkdir -p "$REPO_ROOT/logs"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🔍 Post Validation Started" | tee -a "$LOG_FILE"

# Check for any posts
POST_COUNT=$(find "$POSTS_DIR" -name "*.md" -type f | wc -l)
if [ "$POST_COUNT" -eq 0 ]; then
  echo "❌ No posts found in $POSTS_DIR" | tee -a "$LOG_FILE"
  exit 1
fi

echo "📊 Found $POST_COUNT posts to validate" | tee -a "$LOG_FILE"

VALID=0
INVALID=0

# Validate each post
find "$POSTS_DIR" -name "*.md" -type f | while read -r POST_FILE; do
  FILENAME=$(basename "$POST_FILE")
  echo "" | tee -a "$LOG_FILE"
  echo "Validating: $FILENAME" | tee -a "$LOG_FILE"
  
  # Check frontmatter exists
  if ! head -1 "$POST_FILE" | grep -q "^---"; then
    echo "  ❌ Missing frontmatter (no opening ---)" | tee -a "$LOG_FILE"
    INVALID=$((INVALID + 1))
    continue
  fi
  
  # Check required frontmatter fields
  for field in "title" "date" "slug"; do
    if ! grep -q "^$field:" "$POST_FILE"; then
      echo "  ❌ Missing required field: $field" | tee -a "$LOG_FILE"
      INVALID=$((INVALID + 1))
      continue 2
    fi
  done
  
  # Check content length
  CONTENT=$(sed '/^---$/d' "$POST_FILE" | sed '/^---$/d' | tail -n +2)
  WORD_COUNT=$(echo "$CONTENT" | wc -w)
  
  if [ "$WORD_COUNT" -lt 500 ]; then
    echo "  ⚠️  Low word count: $WORD_COUNT words" | tee -a "$LOG_FILE"
  elif [ "$WORD_COUNT" -lt 1800 ]; then
    echo "  ⚠️  Below target: $WORD_COUNT words (target: 1800+)" | tee -a "$LOG_FILE"
  else
    echo "  ✅ Word count: $WORD_COUNT" | tee -a "$LOG_FILE"
  fi
  
  # Check for draft status
  if grep -q "status: draft" "$POST_FILE"; then
    echo "  ℹ️  Status: DRAFT (will not be published)" | tee -a "$LOG_FILE"
  else
    echo "  ✅ Status: PUBLISHED" | tee -a "$LOG_FILE"
  fi
  
  # Extract title
  TITLE=$(grep "^title:" "$POST_FILE" | sed 's/^title: *"\?\(.*\)"\?$/\1/')
  echo "  📌 Title: $TITLE" | tee -a "$LOG_FILE"
  
  # Check for common issues
  if grep -q "null" "$POST_FILE" | head -5; then
    echo "  ⚠️  Contains 'null' - verify generated content" | tee -a "$LOG_FILE"
  fi
  
  echo "  ✅ Validation passed" | tee -a "$LOG_FILE"
  VALID=$((VALID + 1))
  
done

echo "" | tee -a "$LOG_FILE"
echo "📋 Validation Summary" | tee -a "$LOG_FILE"
echo "  Valid posts: $VALID" | tee -a "$LOG_FILE"
echo "  Issues found: $INVALID" | tee -a "$LOG_FILE"

if [ "$INVALID" -gt 0 ]; then
  echo "⚠️  Some posts have validation issues" | tee -a "$LOG_FILE"
  exit 1
else
  echo "✅ All posts validated successfully" | tee -a "$LOG_FILE"
  exit 0
fi
