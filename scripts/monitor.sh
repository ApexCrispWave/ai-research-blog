#!/bin/bash
# monitor.sh — Health check and metrics for the blog pipeline

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
TODAY=$(date +%Y-%m-%d)

echo "═══════════════════════════════════════"
echo "🔍 AI Research Blog — Status Monitor"
echo "   $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════"

# Posts count
TOTAL_POSTS=$(ls "$PROJECT_DIR/_posts/"*.md 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "📝 Published Posts: $TOTAL_POSTS"
ls "$PROJECT_DIR/_posts/"*.md 2>/dev/null | while read f; do
  TITLE=$(grep '^title:' "$f" | head -1 | sed 's/title: *//')
  DATE=$(basename "$f" | cut -c1-10)
  WORDS=$(wc -w < "$f" | tr -d ' ')
  echo "   $DATE | ${WORDS}w | $TITLE"
done

# Research files
RESEARCH_COUNT=$(ls "$PROJECT_DIR/research/daily/"*.json 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "🔬 Research Files: $RESEARCH_COUNT"

# Today's status
echo ""
echo "📅 Today ($TODAY):"
[ -f "$PROJECT_DIR/research/daily/$TODAY.json" ] && echo "   ✅ Research done" || echo "   ❌ No research yet"
[ -f "$PROJECT_DIR/_posts/$TODAY"*.md 2>/dev/null ] && echo "   ✅ Post generated" || echo "   ❌ No post yet"

# Last pipeline run
LAST_PIPELINE=$(ls -t "$LOG_DIR/pipeline-"*.log 2>/dev/null | head -1)
if [ -n "$LAST_PIPELINE" ]; then
  LAST_DATE=$(basename "$LAST_PIPELINE" | sed 's/pipeline-//' | sed 's/.log//')
  LAST_STATUS=$(tail -3 "$LAST_PIPELINE" 2>/dev/null | grep -q "✅" && echo "✅ Success" || echo "⚠️  Check logs")
  echo ""
  echo "🔄 Last Pipeline: $LAST_DATE — $LAST_STATUS"
fi

# Metrics
METRICS="$LOG_DIR/metrics.json"
if [ -f "$METRICS" ]; then
  POST_COUNT=$(jq '.posts | length' "$METRICS" 2>/dev/null || echo 0)
  AVG_WORDS=$(jq '.posts | map(.word_count) | add / length | floor' "$METRICS" 2>/dev/null || echo 0)
  echo ""
  echo "📊 Metrics:"
  echo "   Posts tracked: $POST_COUNT"
  echo "   Avg word count: $AVG_WORDS"
fi

# Ollama health
echo ""
OLLAMA_OK=$(curl -sf http://127.0.0.1:11434/api/tags 2>/dev/null | jq '.models | length' || echo 0)
echo "🤖 Ollama: $([ "$OLLAMA_OK" -gt 0 ] && echo "✅ Running ($OLLAMA_OK models)" || echo "❌ Not responding")"

# GitHub Pages URL
echo ""
echo "🌐 GitHub Pages: https://ApexCrispWave.github.io/ai-research-blog/"
echo "📡 RSS Feed: https://ApexCrispWave.github.io/ai-research-blog/feed.xml"
echo ""
