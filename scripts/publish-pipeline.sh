#!/bin/bash
# publish-pipeline.sh — Full publishing pipeline
# GitHub Pages (auto via Actions), Dev.to, Twitter/X
# Usage: ./scripts/publish-pipeline.sh [--draft-only] [--date YYYY-MM-DD]

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
TODAY="${2:-$(date +%Y-%m-%d)}"
DRAFT_ONLY="${1:-}"

mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_DIR/publish.log"; }

log "🚀 Publishing Pipeline — $TODAY"

cd "$PROJECT_DIR"

# ── Check for posts to publish ────────────────────────────────────────────────
POST_FILE=$(ls _posts/${TODAY}*.md 2>/dev/null | head -1 || echo "")
DRAFT_FILE="posts/draft-$TODAY.md"

if [ -z "$POST_FILE" ] && [ ! -f "$DRAFT_FILE" ]; then
  log "  ⚠️  No posts found for $TODAY"
  log "  Run: ./scripts/generate-blog-post.sh"
  exit 1
fi

TARGET="${POST_FILE:-$DRAFT_FILE}"
log "  Publishing: $TARGET"

# ── GitHub: Create PR branch ──────────────────────────────────────────────────
BRANCH="post/$TODAY"
log "Creating branch: $BRANCH"

git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH" 2>/dev/null || true
git add _posts/ posts/ research/daily/ logs/metrics.json 2>/dev/null || true
git commit -m "Blog post: $(date +%Y-%m-%d) AI research roundup

Auto-generated from nightly research aggregation.
- Source: research/daily/$TODAY.json
- Post: $TARGET
- Model: qwen3.5:9b (local)" 2>/dev/null || log "  Nothing new to commit"

git push origin "$BRANCH" 2>/dev/null || log "  ⚠️  Push failed (check GitHub token)"

# ── Create GitHub PR ──────────────────────────────────────────────────────────
if [ "$DRAFT_ONLY" != "--draft-only" ]; then
  log "Creating GitHub Pull Request..."
  PR_URL=$(gh pr create \
    --title "Blog Post: $TODAY AI Research Roundup" \
    --body "## Auto-generated blog post

**Date:** $TODAY
**Model:** qwen3.5:9b (local, zero cloud cost)
**Source:** research/daily/$TODAY.json

### Checklist
- [ ] Review content accuracy
- [ ] Check frontmatter (title, tags, description)
- [ ] Verify CTA link is correct
- [ ] Approve for publication

**On merge to main:** GitHub Actions will auto-deploy to GitHub Pages." \
    --base main \
    --head "$BRANCH" \
    2>/dev/null || echo "")
  
  if [ -n "$PR_URL" ]; then
    log "  ✅ PR created: $PR_URL"
  else
    log "  ⚠️  PR creation failed (may already exist)"
  fi
fi

# ── Dev.to cross-posting ──────────────────────────────────────────────────────
if [ -n "${DEVTO_API_KEY:-}" ] && [ -f "$TARGET" ]; then
  log "Cross-posting to Dev.to..."
  
  # Extract frontmatter fields
  TITLE=$(grep '^title:' "$TARGET" | head -1 | sed 's/title: *//' | tr -d '"')
  DESCRIPTION=$(grep '^description:' "$TARGET" | head -1 | sed 's/description: *//' | tr -d '"')
  TAGS=$(grep '^tags:' "$TARGET" | head -1 | sed 's/tags: *//' | tr -d '[]' | tr ',' '\n' | tr -d ' ' | head -4 | jq -Rs 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '["ai","automation"]')
  
  # Get article body (skip frontmatter)
  BODY=$(awk '/^---$/{c++; if(c==2){found=1; next}} found{print}' "$TARGET")
  
  DEVTO_RESPONSE=$(curl -sf \
    -X POST "https://dev.to/api/articles" \
    -H "api-key: $DEVTO_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"article\": {
        \"title\": $(echo "$TITLE" | jq -Rs .),
        \"body_markdown\": $(echo "$BODY" | jq -Rs .),
        \"published\": true,
        \"description\": $(echo "$DESCRIPTION" | jq -Rs .),
        \"tags\": $TAGS,
        \"canonical_url\": \"https://ApexCrispWave.github.io/ai-research-blog/$TODAY/\"
      }
    }" 2>/dev/null || echo "")
  
  DEVTO_URL=$(echo "$DEVTO_RESPONSE" | jq -r '.url // ""' 2>/dev/null || echo "")
  if [ -n "$DEVTO_URL" ]; then
    log "  ✅ Dev.to: $DEVTO_URL"
  else
    log "  ⚠️  Dev.to posting failed (check DEVTO_API_KEY)"
  fi
else
  log "  ℹ️  Dev.to: DEVTO_API_KEY not set — skipping (set it when ready)"
fi

# ── Twitter/X Thread ──────────────────────────────────────────────────────────
if [ -n "${TWITTER_BEARER_TOKEN:-}" ] && [ -f "$TARGET" ]; then
  log "Posting Twitter thread..."
  TITLE=$(grep '^title:' "$TARGET" | head -1 | sed 's/title: *//' | tr -d '"')
  DESCRIPTION=$(grep '^description:' "$TARGET" | head -1 | sed 's/description: *//' | tr -d '"')
  
  TWEET_TEXT="🚀 New post: $TITLE

$DESCRIPTION

Read → https://ApexCrispWave.github.io/ai-research-blog/

#AI #LocalLLM #Automation"

  # Twitter API v2 tweet
  TWEET_RESPONSE=$(curl -sf \
    -X POST "https://api.twitter.com/2/tweets" \
    -H "Authorization: Bearer $TWITTER_BEARER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"text\": $(echo "$TWEET_TEXT" | jq -Rs .)}" 2>/dev/null || echo "")
  
  TWEET_ID=$(echo "$TWEET_RESPONSE" | jq -r '.data.id // ""' 2>/dev/null || echo "")
  if [ -n "$TWEET_ID" ]; then
    log "  ✅ Twitter: https://twitter.com/i/web/status/$TWEET_ID"
  else
    log "  ⚠️  Twitter: Posting failed (check TWITTER_BEARER_TOKEN)"
  fi
else
  log "  ℹ️  Twitter: credentials not set — skipping"
fi

# ── Metrics update ────────────────────────────────────────────────────────────
METRICS_FILE="$LOG_DIR/metrics.json"
if [ ! -f "$METRICS_FILE" ]; then echo '{"posts":[]}' > "$METRICS_FILE"; fi

# Log publish event
PUBLISH_LOG="$LOG_DIR/publish-timestamps.log"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | $TODAY | $TARGET | branch=$BRANCH" >> "$PUBLISH_LOG"

log "✅ Publishing pipeline complete"
log "   Branch: $BRANCH pushed to GitHub"
log "   GitHub Pages: auto-deploys on PR merge to main"
log "   Metrics: $METRICS_FILE"
