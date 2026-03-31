#!/bin/bash

# night-youtube-research.sh
# Scan AI YouTube channels nightly, extract insights, and feed idea pipeline
# Uses qwen3.5:9b for summarization

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESEARCH_DIR="$PROJECT_DIR/research/youtube-intel"
LOG_DIR="$PROJECT_DIR/logs"
TODAY=$(date +%Y-%m-%d)
OUTPUT_FILE="$RESEARCH_DIR/$TODAY.json"

# Ensure directories exist
mkdir -p "$RESEARCH_DIR" "$LOG_DIR"

# YouTube channels to monitor (configurable)
CHANNELS=(
  "@AlexFinnOfficial"
  "@imscottsimson"
  "@timcarambat"
  "@ThePrimeagen"
  "@Fireship"
  "@KevinPowell"
)

echo "🎬 Starting YouTube Research Task — $TODAY"
echo "Channels: ${CHANNELS[*]}"

# Initialize JSON output
cat > "$OUTPUT_FILE" << 'EOF'
{
  "date": "DATE_PLACEHOLDER",
  "source": "night-youtube-research.sh",
  "channels_scanned": 0,
  "videos_analyzed": 0,
  "videos": [],
  "key_themes": [],
  "opportunities": [],
  "validation": {
    "min_videos": 3,
    "all_summarized": true,
    "errors": []
  }
}
EOF

# Replace date placeholder
sed -i.bak "s/DATE_PLACEHOLDER/$TODAY/" "$OUTPUT_FILE" && rm -f "$OUTPUT_FILE.bak"

# Counter
VIDEOS_FOUND=0
VIDEOS_SUMMARIZED=0

echo "📡 Fetching latest videos from ${#CHANNELS[@]} channels..."

# For each channel, extract latest videos (using yt-dlp or manual fetch)
for CHANNEL in "${CHANNELS[@]}"; do
  echo "  → Scanning $CHANNEL..."
  
  # Using yt-dlp to get latest 3 videos from channel (if available)
  if command -v yt-dlp &> /dev/null; then
    # Get channel info and latest videos
    VIDEOS=$(yt-dlp --dump-json --flat-playlist -e "https://www.youtube.com/$CHANNEL/videos" 2>/dev/null | jq -r '.entries | .[0:3] | .[] | "\(.id)|\(.title)"' 2>/dev/null || echo "")
    
    if [ -n "$VIDEOS" ]; then
      while IFS='|' read -r VIDEO_ID VIDEO_TITLE; do
        if [ -z "$VIDEO_ID" ]; then continue; fi
        
        VIDEOS_FOUND=$((VIDEOS_FOUND + 1))
        
        # Skip video summarization if yt-dlp captions aren't available
        # Instead, use video metadata + title as context
        SUMMARY="Video: $VIDEO_TITLE | Channel: $CHANNEL | New AI/tech content in focus area."
        
        # Call qwen3.5:9b to generate key insights from title + description
        INSIGHT=$(curl -s http://127.0.0.1:11434/api/generate \
          --data "{\"model\":\"qwen3.5:9b\",\"prompt\":\"Summarize the key insight from this YouTube video title: \\"$VIDEO_TITLE\\". What's the main learning or opportunity? Keep it to 1-2 sentences.\",\"stream\":false}" \
          | jq -r '.response' 2>/dev/null || echo "$SUMMARY")
        
        VIDEOS_SUMMARIZED=$((VIDEOS_SUMMARIZED + 1))
        
        # Append to JSON
        jq \
          --arg id "$VIDEO_ID" \
          --arg title "$VIDEO_TITLE" \
          --arg channel "$CHANNEL" \
          --arg insight "$INSIGHT" \
          --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
          '.videos += [{
            "video_id": $id,
            "title": $title,
            "channel": $channel,
            "insight": $insight,
            "fetched_at": $date,
            "url": "https://www.youtube.com/watch?v=" + $id
          }]' \
          "$OUTPUT_FILE" > "$OUTPUT_FILE.tmp" && mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
      done <<< "$VIDEOS"
    fi
  else
    echo "    ⚠️  yt-dlp not installed, skipping live fetch"
  fi
done

# Extract key themes from all videos using local model
if [ $VIDEOS_SUMMARIZED -gt 0 ]; then
  echo "🧠 Extracting themes from $VIDEOS_SUMMARIZED videos..."
  
  ALL_INSIGHTS=$(jq -r '.videos[].insight' "$OUTPUT_FILE" | tr '
' ' ')
  
  THEMES=$(curl -s http://127.0.0.1:11434/api/generate \
    --data "{\"model\":\"qwen3.5:9b\",\"prompt\":\"From these video insights, identify 3-5 key themes or patterns: $ALL_INSIGHTS. List as JSON array of strings.\",\"stream\":false}" \
    | jq -r '.response' 2>/dev/null | jq -R 'split(",") | map(gsub("[^a-zA-Z0-9 ]"; ""))' || echo '[]')
  
  jq --argjson themes "$THEMES" '.key_themes = $themes' "$OUTPUT_FILE" > "$OUTPUT_FILE.tmp" && mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
fi

# Identify opportunities
if [ $VIDEOS_SUMMARIZED -gt 0 ]; then
  echo "💡 Identifying opportunities..."
  
  OPPORTUNITIES=$(curl -s http://127.0.0.1:11434/api/generate \
    --data "{\"model\":\"qwen3.5:9b\",\"prompt\":\"Based on these YouTube trends, what are 2-3 product/business opportunities? $ALL_INSIGHTS\",\"stream\":false}" \
    | jq -r '.response' 2>/dev/null || echo "")
  
  jq --arg opp "$OPPORTUNITIES" '.opportunities += [$opp]' "$OUTPUT_FILE" > "$OUTPUT_FILE.tmp" && mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
fi

# Update metadata
jq \
  --arg channels "${#CHANNELS[@]}" \
  --arg videos "$VIDEOS_SUMMARIZED" \
  '.channels_scanned = ($channels | tonumber) | .videos_analyzed = ($videos | tonumber)' \
  "$OUTPUT_FILE" > "$OUTPUT_FILE.tmp" && mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"

# Validation
if [ $VIDEOS_SUMMARIZED -lt 3 ]; then
  jq '.validation.all_summarized = false | .validation.errors += ["Less than 3 videos summarized"]' "$OUTPUT_FILE" > "$OUTPUT_FILE.tmp" && mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
fi

# Log run
LOG_ENTRY=$(jq -n \
  --arg task "night-youtube-research" \
  --arg date "$TODAY" \
  --arg status "$([ $VIDEOS_SUMMARIZED -ge 3 ] && echo 'success' || echo 'warning')" \
  --arg videos "$VIDEOS_SUMMARIZED" \
  '{task: $task, date: $date, status: $status, videos_analyzed: ($videos | tonumber), output_file: "'$OUTPUT_FILE'", timestamp: now}')

# Append to task runs log
if [ -f "$LOG_DIR/task-runs.json" ]; then
  jq ". += [$LOG_ENTRY]" "$LOG_DIR/task-runs.json" > "$LOG_DIR/task-runs.json.tmp" && mv "$LOG_DIR/task-runs.json.tmp" "$LOG_DIR/task-runs.json"
else
  echo "[$LOG_ENTRY]" > "$LOG_DIR/task-runs.json"
fi

echo "✅ YouTube Research Task Complete"
echo "   Videos Analyzed: $VIDEOS_SUMMARIZED"
echo "   Output: $OUTPUT_FILE"
echo "   Status: $([ $VIDEOS_SUMMARIZED -ge 3 ] && echo 'PASS' || echo 'WARNING')"

# Return exit code based on success
[ $VIDEOS_SUMMARIZED -ge 3 ] && exit 0 || exit 1
