#!/bin/bash
# generate-blog-post.sh — Generate 2000-word blog post from research JSON
# Usage: ./scripts/generate-blog-post.sh [--date YYYY-MM-DD] [--research path/to/research.json]
# Output: _posts/YYYY-MM-DD-slug.md + posts/draft-YYYY-MM-DD.md

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POSTS_DIR="$PROJECT_DIR/_posts"
DRAFTS_DIR="$PROJECT_DIR/posts"
LOG_DIR="$PROJECT_DIR/logs"
TODAY="${2:-$(date +%Y-%m-%d)}"
RESEARCH_FILE="${4:-$PROJECT_DIR/research/daily/$TODAY.json}"

mkdir -p "$POSTS_DIR" "$DRAFTS_DIR" "$LOG_DIR"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_DIR/blog-generator.log"; }

log "✍️  Blog Generator — $TODAY"

# Check research file
if [ ! -f "$RESEARCH_FILE" ]; then
  log "  ⚠️  Research file not found: $RESEARCH_FILE"
  log "  Running research aggregator first..."
  bash "$PROJECT_DIR/scripts/research-aggregator.sh" || true
fi

# Load research data
RESEARCH=$(cat "$RESEARCH_FILE" 2>/dev/null || echo '{}')
BLOG_ANGLE=$(echo "$RESEARCH" | jq -r '.synthesis.blog_angle // "AI automation trends"')
TOP_STORY=$(echo "$RESEARCH" | jq -r '.synthesis.top_story // "Local AI advances"')
KEY_THEMES=$(echo "$RESEARCH" | jq -r '.synthesis.key_themes | join(", ")' 2>/dev/null || echo "AI, automation, local LLMs")
HN_TITLES=$(echo "$RESEARCH" | jq -r '.sources.hacker_news[0:5] | map(.title) | join("\n- ")' 2>/dev/null || echo "")
YT_TITLES=$(echo "$RESEARCH" | jq -r '.sources.youtube[0:5] | map(.channel + ": " + .title) | join("\n- ")' 2>/dev/null || echo "")

log "  Blog angle: $BLOG_ANGLE"
log "  Top story: $TOP_STORY"

# ── Generate slug ─────────────────────────────────────────────────────────────
SLUG=$(echo "$BLOG_ANGLE" | tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9 ]//g' | \
  tr ' ' '-' | \
  sed 's/--*/-/g' | \
  cut -c1-50 | \
  sed 's/-$//')
[ -z "$SLUG" ] && SLUG="ai-research-roundup"
SLUG="$TODAY-$SLUG"

OUTPUT_FILE="$POSTS_DIR/$SLUG.md"
DRAFT_FILE="$DRAFTS_DIR/draft-$TODAY.md"

# ── Generate with qwen3.5:9b ──────────────────────────────────────────────────
log "  Calling qwen3.5:9b for content generation..."

PROMPT="Write a 2000-word blog post that's technical, opinionated, beginner-friendly, and fun to read. News digest style.

BLOG ANGLE: $BLOG_ANGLE
TOP STORY: $TOP_STORY
KEY THEMES: $KEY_THEMES

TRENDING HACKER NEWS STORIES TODAY:
- $HN_TITLES

TRENDING AI YOUTUBE VIDEOS TODAY:
- $YT_TITLES

VOICE & TONE:
• Technical + opinionated (have a POV, don't be neutral)
• Beginner-friendly (explain jargon, no gatekeeping)
• News digest style (what's hot right now, why it matters)
• Fun to read (conversational, wit where appropriate, avoid corporate speak)

CONTENT FOCUS (pick 1-2 per post):
- AI/ML research trends and breakthroughs
- Local LLM optimization (running models faster, cheaper)
- OpenClaw automation and open source optimizations
- How to hire an AI employee (tools, workflows, costs)

REQUIREMENTS:
1. SEO title that includes 2026 or a timely angle
2. Strong hook in first paragraph: Why this matters RIGHT NOW
3. 5-7 sections with ## headers
4. Real code examples, commands, or workflows where relevant
5. Direct, punchy language—no fluff
6. Each section 150-300 words
7. End with CTA: 'Ready to build? Get the AI Automation Starter Kit at crispwave.gumroad.com — scripts, templates, zero cloud cost.'

OUTPUT FORMAT (markdown with Jekyll frontmatter):
---
title: \"[SEO title here]\"
date: $TODAY
slug: $(echo "$BLOG_ANGLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-' | cut -c1-40)
tags: [ai, automation, local-llm]
description: \"[150-char SEO description]\"
reading_time: 10
word_count: 2000
author: APEX
---

[Full 2000-word article body]"

CONTENT=$(curl -sf http://127.0.0.1:11434/api/generate \
  --data "{\"model\":\"qwen3.5:9b\",\"prompt\":$(echo "$PROMPT" | jq -Rs .),\"stream\":false,\"options\":{\"num_predict\":5000,\"temperature\":0.7}}" \
  2>/dev/null | jq -r '.response' || echo "")

if [ -z "$CONTENT" ]; then
  log "  ❌ Generation failed — model not responding"
  exit 1
fi

WORD_COUNT=$(echo "$CONTENT" | wc -w)
log "  Generated $WORD_COUNT words"

# If too short, try to expand
if [ "$WORD_COUNT" -lt 800 ]; then
  log "  ⚠️  Content too short, expanding..."
  EXPAND_PROMPT="Expand this article to 2000 words. Keep all sections but add more detail, examples, and code. Here is the article: $CONTENT"
  CONTENT=$(curl -sf http://127.0.0.1:11434/api/generate \
    --data "{\"model\":\"qwen3.5:9b\",\"prompt\":$(echo "$EXPAND_PROMPT" | jq -Rs .),\"stream\":false,\"options\":{\"num_predict\":4000,\"temperature\":0.7}}" \
    2>/dev/null | jq -r '.response' || echo "$CONTENT")
  WORD_COUNT=$(echo "$CONTENT" | wc -w)
  log "  Expanded to $WORD_COUNT words"
fi

# ── Write output files ────────────────────────────────────────────────────────
echo "$CONTENT" > "$OUTPUT_FILE"
echo "$CONTENT" > "$DRAFT_FILE"

# ── Update metrics log ────────────────────────────────────────────────────────
METRICS_FILE="$LOG_DIR/metrics.json"
if [ ! -f "$METRICS_FILE" ]; then
  echo '{"posts":[]}' > "$METRICS_FILE"
fi

READING_TIME=$(( WORD_COUNT / 200 ))
NEW_ENTRY="{\"date\":\"$TODAY\",\"file\":\"$OUTPUT_FILE\",\"slug\":\"$SLUG\",\"word_count\":$WORD_COUNT,\"reading_time\":${READING_TIME}m,\"generated_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
TMP=$(jq --argjson entry "$NEW_ENTRY" '.posts += [$entry]' "$METRICS_FILE" 2>/dev/null)
[ -n "$TMP" ] && echo "$TMP" > "$METRICS_FILE"

log "✅ Blog post generated"
log "   File: $OUTPUT_FILE"
log "   Draft: $DRAFT_FILE"
log "   Words: $WORD_COUNT | Reading time: ~${READING_TIME} min"
echo "$OUTPUT_FILE"
