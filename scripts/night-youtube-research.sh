#!/bin/bash
# night-youtube-research.sh
# Analyzes trending AI/tech YouTube channels and extracts ideas
# Requires: ollama with qwen3.5:9b model
# Output: research/youtube-intel/YYYY-MM-DD.json

set -e

RESEARCH_DIR="/Users/openclaw/Projects/ai-research-blog/research/youtube-intel"
SCRIPTS_DIR="/Users/openclaw/Projects/ai-research-blog/scripts"
TODAY=$(date +%Y-%m-%d)
OUTPUT="$RESEARCH_DIR/$TODAY.json"

# Create directory if needed
mkdir -p "$RESEARCH_DIR"

# YouTube channels to analyze (configurable)
CHANNELS=(
    "Alex Finn Official"
    "Y Combinator"
    "Anthropic AI"
    "OpenAI Official"
    "Cursor IDE"
    "Code_Report"
)

echo "🎬 YouTube Research — $TODAY"
echo "Channels: ${#CHANNELS[@]}"
echo "Output: $OUTPUT"

# For now, we'll create a template that will be filled by qwen3.5:9b
# In production, this would use YouTube API to fetch real videos

python3 - <<'PYTHON'
import json
import sys
from datetime import datetime

channels = ["Alex Finn Official", "Y Combinator", "Anthropic AI", "OpenAI Official", "Cursor IDE", "Code_Report"]

# This would be populated by qwen3.5:9b in production
# For now, create a template structure
template = {
    "date": datetime.now().strftime("%Y-%m-%d"),
    "channels_analyzed": channels,
    "videos": [
        {
            "channel": "Example Channel",
            "title": "Video Title",
            "url": "https://youtube.com/watch?v=...",
            "published_date": datetime.now().strftime("%Y-%m-%d"),
            "key_concepts": ["AI", "local models"],
            "summary": "Brief summary of the video.",
            "ideas": ["idea1", "idea2"],
            "relevance_score": 0.85
        }
    ],
    "trends_identified": ["local LLMs", "AI ops"],
    "validation": {
        "videos_processed": 0,
        "ideas_extracted": 0,
        "checksum": "pending"
    }
}

print(json.dumps(template, indent=2))
PYTHON
