#!/bin/bash
# daily-pipeline.sh — Master orchestrator for the full daily pipeline
# Runs: research → generate → publish PR
# Usage: ./scripts/daily-pipeline.sh [--skip-research] [--draft-only] [--date YYYY-MM-DD]

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
TODAY=$(date +%Y-%m-%d)
SKIP_RESEARCH=false
DRAFT_ONLY=false

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-research) SKIP_RESEARCH=true ;;
    --draft-only) DRAFT_ONLY=true ;;
    --date) TODAY="$2"; shift ;;
  esac
  shift
done

mkdir -p "$LOG_DIR"
PIPELINE_LOG="$LOG_DIR/pipeline-$TODAY.log"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$PIPELINE_LOG"; }

log "═══════════════════════════════════════════════════"
log "🤖 CrispWave AI Research Blog — Daily Pipeline"
log "   Date: $TODAY"
log "═══════════════════════════════════════════════════"

START_TIME=$(date +%s)

# ── Step 1: Research Aggregation ──────────────────────────────────────────────
if [ "$SKIP_RESEARCH" = false ]; then
  log ""
  log "STEP 1/3: Research Aggregation"
  RESEARCH_FILE=$(bash "$PROJECT_DIR/scripts/research-aggregator.sh" --date "$TODAY" 2>&1 | tee -a "$PIPELINE_LOG" | tail -1)
  
  if [ ! -f "$RESEARCH_FILE" ]; then
    RESEARCH_FILE="$PROJECT_DIR/research/daily/$TODAY.json"
  fi
  
  if [ ! -f "$RESEARCH_FILE" ]; then
    log "  ❌ Research aggregation failed"
    exit 1
  fi
  log "  ✅ Research complete: $RESEARCH_FILE"
else
  log "STEP 1/3: Research — SKIPPED"
  RESEARCH_FILE="$PROJECT_DIR/research/daily/$TODAY.json"
fi

# ── Step 2: Blog Post Generation ──────────────────────────────────────────────
log ""
log "STEP 2/3: Blog Post Generation"
POST_FILE=$(bash "$PROJECT_DIR/scripts/generate-blog-post.sh" --date "$TODAY" --research "$RESEARCH_FILE" 2>&1 | tee -a "$PIPELINE_LOG" | tail -1)

if [ ! -f "$POST_FILE" ]; then
  POST_FILE=$(ls "$PROJECT_DIR/_posts/${TODAY}"*.md 2>/dev/null | head -1 || echo "")
fi

if [ -z "$POST_FILE" ] || [ ! -f "$POST_FILE" ]; then
  log "  ❌ Blog post generation failed"
  exit 1
fi
log "  ✅ Post generated: $POST_FILE"

# ── Step 3: Publish ───────────────────────────────────────────────────────────
log ""
log "STEP 3/3: Publishing"
DRAFT_FLAG=""
[ "$DRAFT_ONLY" = true ] && DRAFT_FLAG="--draft-only"
bash "$PROJECT_DIR/scripts/publish-pipeline.sh" $DRAFT_FLAG --date "$TODAY" 2>&1 | tee -a "$PIPELINE_LOG"

# ── Summary ───────────────────────────────────────────────────────────────────
END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))

log ""
log "═══════════════════════════════════════════════════"
log "✅ Pipeline Complete in ${DURATION}s"
log "   Post: $POST_FILE"
log "   Log:  $PIPELINE_LOG"
log "   GitHub Pages: https://ApexCrispWave.github.io/ai-research-blog/"
log "═══════════════════════════════════════════════════"
