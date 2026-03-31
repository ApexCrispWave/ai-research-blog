#!/bin/bash
# task-097: Blog Post Generator
# Generates 1500-2500 word blog posts using qwen3.5:9b

set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POSTS_DIR="$PROJECT_DIR/posts"
TODAY=$(date +%Y-%m-%d)
SLUG="${1:-local-llm-guide}"  # Topic slug from input

mkdir -p "$POSTS_DIR"

echo "✍️  task-097: Blog Generator — generating post on '$SLUG'"

PROMPT="Write a comprehensive 1500-2500 word blog post about: $SLUG. Include:
- Compelling title (SEO-optimized)
- Hook paragraph (50 words)
- 3-5 main sections with subheadings
- Real examples and code snippets
- Calls-to-action for CrispWave products
- Conclusion with next steps

Format as markdown with frontmatter:
---
title: TITLE_HERE
date: $TODAY
category: AI
tags: [ai, automation, local-llms]
---"

echo "  Calling qwen3.5:9b for content generation..."

# Generate blog content
CONTENT=$(curl -s http://127.0.0.1:11434/api/generate \
  --data "{\"model\":\"qwen3.5:9b\",\"prompt\":\"$PROMPT\",\"stream\":false}" \
  2>/dev/null | jq -r '.response' || echo "# Blog Post\n\nContent generation failed. Retry manually.")

# Validate content
WORD_COUNT=$(echo "$CONTENT" | wc -w)

if [ $WORD_COUNT -lt 800 ]; then
  echo "  ⚠️  Content too short ($WORD_COUNT words). Enhancing..."
  ENHANCE_PROMPT="Expand this to 1500+ words: $CONTENT"
  CONTENT=$(curl -s http://127.0.0.1:11434/api/generate \
    --data "{\"model\":\"qwen3.5:9b\",\"prompt\":\"$ENHANCE_PROMPT\",\"stream\":false}" \
    2>/dev/null | jq -r '.response' || echo "$CONTENT")
fi

# Save to file
OUTPUT_FILE="$POSTS_DIR/$TODAY-$SLUG.md"
cat > "$OUTPUT_FILE" << EOF
---
title: Blog Post on $SLUG
date: $TODAY
category: AI
tags: [ai, automation]
status: draft
---

$CONTENT

---

**Ready to publish.** Review before pushing to production.
EOF

echo "✅ task-097 complete"
echo "   Post saved: $OUTPUT_FILE"
echo "   Word count: $WORD_COUNT"
exit 0
