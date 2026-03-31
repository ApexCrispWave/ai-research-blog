#!/bin/bash
# publish-latest-blog.sh - Publish the most recent blog post
# Usage: ./scripts/publish-latest-blog.sh [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
POSTS_DIR="$REPO_ROOT/posts"
LOG_FILE="$REPO_ROOT/logs/publish-latest.log"

DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
  DRY_RUN=true
fi

mkdir -p "$REPO_ROOT/logs"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🚀 Publish Latest Blog Started" | tee -a "$LOG_FILE"

# Find most recent post (excluding draft)
LATEST_POST=$(find "$POSTS_DIR" -name "*.md" -type f ! -path "*/draft-*" | sort -r | head -1)

if [ -z "$LATEST_POST" ]; then
  echo "❌ No publishable posts found" | tee -a "$LOG_FILE"
  exit 1
fi

echo "📄 Latest post: $(basename "$LATEST_POST")" | tee -a "$LOG_FILE"

# Check if already published
if grep -q "status: published" "$LATEST_POST" 2>/dev/null; then
  echo "ℹ️  Post already published" | tee -a "$LOG_FILE"
  exit 0
fi

# Validate post
if ! bash "$SCRIPT_DIR/validate-posts.sh" "$LATEST_POST" >> "$LOG_FILE" 2>&1; then
  echo "❌ Validation failed" | tee -a "$LOG_FILE"
  exit 1
fi

echo "✅ Validation passed" | tee -a "$LOG_FILE"

if [ "$DRY_RUN" = true ]; then
  echo "🏗️  DRY RUN - Would publish: $(basename "$LATEST_POST")"
  exit 0
fi

# Publish
echo "📤 Publishing..." | tee -a "$LOG_FILE"
bash "$SCRIPT_DIR/publish-blog-post.sh" "$LATEST_POST" 2>&1 | tee -a "$LOG_FILE"

echo "✨ Done!" | tee -a "$LOG_FILE"
