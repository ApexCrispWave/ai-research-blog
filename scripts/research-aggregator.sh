#!/bin/bash
# research-aggregator.sh — Nightly AI research aggregator
# Sources: YouTube AI channels, Hacker News, Product Hunt
# Output: research/daily/YYYY-MM-DD.json
# Usage: ./scripts/research-aggregator.sh [--date YYYY-MM-DD]

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESEARCH_DIR="$PROJECT_DIR/research/daily"
LOG_DIR="$PROJECT_DIR/logs"
TODAY="${2:-$(date +%Y-%m-%d)}"
OUTPUT_FILE="$RESEARCH_DIR/$TODAY.json"

mkdir -p "$RESEARCH_DIR" "$LOG_DIR"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_DIR/research-aggregator.log"; }

log "🔬 Research Aggregator — $TODAY"

# ── Hacker News ──────────────────────────────────────────────────────────────
log "Fetching Hacker News top AI stories..."
HN_IDS=$(curl -sf "https://hacker-news.firebaseio.com/v0/topstories.json" 2>/dev/null | jq '.[0:40][]' || echo "")
HN_STORIES="[]"
if [ -n "$HN_IDS" ]; then
  HN_STORIES=$(echo "$HN_IDS" | while read -r id; do
    curl -sf "https://hacker-news.firebaseio.com/v0/item/${id}.json" 2>/dev/null || true
  done | jq -s '[.[] | select(.title != null) | select(
    (.title | ascii_downcase | test("ai|llm|gpt|claude|gemini|openai|agent|automation|model|ollama|mistral|deepseek|langchain|rag|embedding|vector|ml |machine learning|neural|transformer")) or
    (.url // "" | ascii_downcase | test("huggingface|openai|anthropic|deepseek|mistral"))
  )] | .[0:10] | map({
    title: .title,
    url: (.url // ("https://news.ycombinator.com/item?id=" + (.id | tostring))),
    score: (.score // 0),
    by: (.by // ""),
    source: "hacker_news"
  })' 2>/dev/null || echo "[]")
fi
HN_COUNT=$(echo "$HN_STORIES" | jq 'length')
log "  → $HN_COUNT HN stories found"

# ── YouTube AI Channels ───────────────────────────────────────────────────────
log "Scanning AI YouTube channels (last 7 days)..."
YOUTUBE_VIDEOS="[]"
CHANNELS=(
  "https://www.youtube.com/@MattVidPro/videos"
  "https://www.youtube.com/@TwoMinutePapers/videos"
  "https://www.youtube.com/@WorldofAI/videos"
  "https://www.youtube.com/@aiexplained-official/videos"
  "https://www.youtube.com/@bycloud/videos"
)
CHANNEL_NAMES=("MattVidPro" "TwoMinutePapers" "WorldOfAI" "AIExplained" "bycloud")

for i in "${!CHANNELS[@]}"; do
  CHANNEL_URL="${CHANNELS[$i]}"
  CHANNEL_NAME="${CHANNEL_NAMES[$i]}"
  TITLES=$(yt-dlp --flat-playlist --print "%(title)s" \
    --playlist-items 1-5 \
    --no-warnings \
    "$CHANNEL_URL" 2>/dev/null | head -5 || echo "")
  if [ -n "$TITLES" ]; then
    while IFS= read -r title; do
      [ -z "$title" ] && continue
      YOUTUBE_VIDEOS=$(echo "$YOUTUBE_VIDEOS" | jq \
        --arg ch "$CHANNEL_NAME" --arg t "$title" \
        '. += [{"channel": $ch, "title": $t, "source": "youtube"}]')
    done <<< "$TITLES"
  fi
done
YT_COUNT=$(echo "$YOUTUBE_VIDEOS" | jq 'length')
log "  → $YT_COUNT YouTube videos found"

# ── GitHub Trending (AI) ──────────────────────────────────────────────────────
log "Fetching GitHub trending AI repos..."
GH_TRENDING=$(curl -sf "https://api.github.com/search/repositories?q=topic:artificial-intelligence+pushed:>$(date -v-7d +%Y-%m-%d)&sort=stars&order=desc&per_page=10" \
  2>/dev/null | jq '[.items[] | {name: .full_name, description: .description, stars: .stargazers_count, url: .html_url, source: "github_trending"}]' || echo "[]")
GH_COUNT=$(echo "$GH_TRENDING" | jq 'length')
log "  → $GH_COUNT GitHub trending repos"

# ── Synthesize with qwen3.5:9b ────────────────────────────────────────────────
log "Synthesizing insights with qwen3.5:9b..."

ALL_TITLES=$(echo "$HN_STORIES $YOUTUBE_VIDEOS" | jq -s 'add | map(.title) | join(", ")' -r 2>/dev/null || echo "AI news")

SYNTHESIS_PROMPT="You are an AI research analyst. Based on these trending topics from today's AI news, identify the top 5 key themes and suggest the best blog angle (most interesting story for developers). Keep each theme under 15 words.

Topics: $ALL_TITLES

Respond with JSON:
{
  \"key_themes\": [\"theme1\", \"theme2\", \"theme3\", \"theme4\", \"theme5\"],
  \"blog_angle\": \"One sentence about the best story angle\",
  \"top_story\": \"The single most significant AI development today\"
}"

SYNTHESIS=$(curl -sf http://127.0.0.1:11434/api/generate \
  --data "{\"model\":\"qwen3.5:9b\",\"prompt\":$(echo "$SYNTHESIS_PROMPT" | jq -Rs .),\"stream\":false,\"options\":{\"num_predict\":500,\"temperature\":0.3}}" \
  2>/dev/null | jq -r '.response' || echo '{"key_themes":["AI automation","local LLMs","agent frameworks"],"blog_angle":"Local AI gains momentum","top_story":"Ollama MLX breakthrough"}')

# Extract JSON from response (model may add preamble)
SYNTHESIS_JSON=$(echo "$SYNTHESIS" | python3 -c "
import sys, json, re
text = sys.stdin.read()
matches = re.findall(r'\{[^{}]*\}', text, re.DOTALL)
for m in matches:
    try:
        obj = json.loads(m)
        if 'key_themes' in obj:
            print(json.dumps(obj))
            break
    except: pass
" 2>/dev/null || echo '{"key_themes":["AI tools","automation","local models"],"blog_angle":"Local AI revolution","top_story":"Ollama MLX support"}')

KEY_THEMES=$(echo "$SYNTHESIS_JSON" | jq -r '.key_themes // ["AI automation"]')
BLOG_ANGLE=$(echo "$SYNTHESIS_JSON" | jq -r '.blog_angle // "Local AI trends"')
TOP_STORY=$(echo "$SYNTHESIS_JSON" | jq -r '.top_story // "AI news roundup"')

# ── Write consolidated JSON ───────────────────────────────────────────────────
cat > "$OUTPUT_FILE" << EOF
{
  "date": "$TODAY",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "sources": {
    "hacker_news": $HN_STORIES,
    "youtube": $YOUTUBE_VIDEOS,
    "github_trending": $GH_TRENDING
  },
  "counts": {
    "hacker_news": $HN_COUNT,
    "youtube": $YT_COUNT,
    "github_trending": $GH_COUNT
  },
  "synthesis": {
    "key_themes": $KEY_THEMES,
    "blog_angle": "$BLOG_ANGLE",
    "top_story": "$TOP_STORY"
  }
}
EOF

log "✅ Research aggregated: $OUTPUT_FILE"
log "   HN: $HN_COUNT | YT: $YT_COUNT | GH: $GH_COUNT stories"
echo "$OUTPUT_FILE"
