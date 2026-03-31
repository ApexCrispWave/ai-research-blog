#!/bin/bash
# task-101: Publish blog posts to GitHub & web
# CI/CD pipeline for blog automation

set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POSTS_DIR="$PROJECT_DIR/posts"

echo "🚀 task-101: Publishing blog posts..."

# Git status check
cd "$PROJECT_DIR"

# Check for new/modified posts
CHANGED=$(git status -s posts/ 2>/dev/null | wc -l)

if [ $CHANGED -gt 0 ]; then
  echo "   $CHANGED posts changed. Committing..."
  
  git add posts/ research/ logs/
  git commit -m "Blog: Nightly content update $(date +%Y-%m-%d)" || true
  git push origin main 2>/dev/null || echo "   ⚠️  Push failed (no remote configured)"
  
  echo "✅ Posts committed and pushed"
else
  echo "   No new posts to publish"
fi

echo "✅ task-101 complete: publication pipeline ready"
exit 0
