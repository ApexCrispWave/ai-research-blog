#!/bin/bash
# generate-blog-post.sh - Create a blog post from research JSON using qwen3.5:9b
# Usage: ./scripts/generate-blog-post.sh [research_date]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
POSTS_DIR="$REPO_ROOT/posts"
RESEARCH_DIR="$REPO_ROOT/research"
LOG_FILE="$REPO_ROOT/logs/blog-generation.log"

# Ensure directories exist
mkdir -p "$POSTS_DIR" "$REPO_ROOT/logs"

# Parse arguments
RESEARCH_DATE="${1:-2026-03-30}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🚀 Blog Post Generator Started" | tee -a "$LOG_FILE"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Research Date: $RESEARCH_DATE" | tee -a "$LOG_FILE"

# Read research data
RESEARCH_JSON="$RESEARCH_DIR/research-$RESEARCH_DATE.json"
if [ ! -f "$RESEARCH_JSON" ]; then
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  Research file not found: $RESEARCH_JSON" | tee -a "$LOG_FILE"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Creating placeholder research data..." | tee -a "$LOG_FILE"
  
  mkdir -p "$RESEARCH_DIR"
  bash "$SCRIPT_DIR/aggregate-research.sh" "$RESEARCH_DATE" >> "$LOG_FILE" 2>&1
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 📖 Reading research data..." | tee -a "$LOG_FILE"
RESEARCH_CONTENT=$(cat "$RESEARCH_JSON" 2>/dev/null || echo "{}")

# Create blog post prompt
BLOG_PROMPT="You are an expert AI blogger. Based on the following research data about AI trends, write a comprehensive blog post (1800-2200 words).

RESEARCH DATA:
$RESEARCH_CONTENT

REQUIREMENTS:
1. Write 1800-2200 words
2. Include insights from multiple sources (YouTube, market trends, competitive analysis)
3. Use markdown formatting with clear headers
4. Include 3-5 actionable takeaways
5. Add an engaging call-to-action related to AI resources/Gumroad
6. Use bullet points for key information
7. Make it accessible to technical and non-technical readers
8. Include specific examples

STRUCTURE:
# Main Title (Catchy, about AI trends)

## Introduction
[Hook the reader with a compelling stat or question]

## Key Trends
[2-3 paragraphs about main trends]

## Actionable Insights
- Insight 1
- Insight 2
- Insight 3

## Conclusion
[Wrap up with forward-looking statement]

## Call to Action
[Suggest newsletter signup or resource]

Write the full blog post now:"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🤖 Generating blog post with qwen3.5:9b..." | tee -a "$LOG_FILE"

# Call qwen3.5:9b
GENERATED_POST=$(timeout 120 ollama run qwen3.5:9b "$BLOG_PROMPT" 2>/dev/null | head -4000)

if [ -z "$GENERATED_POST" ]; then
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ Failed to generate blog post" | tee -a "$LOG_FILE"
  
  # Create fallback post
  GENERATED_POST="# The Future of AI: Trends and Opportunities for $RESEARCH_DATE

## Introduction
The AI landscape is rapidly evolving with new developments in open-source models, efficient inference, and practical applications. This post explores the latest trends shaping the industry.

## Key Trends

### 1. Local and Efficient Models
Open-source models are becoming competitive with proprietary APIs. Tools like Qwen, Mistral, and Llama are enabling developers to run powerful AI locally without cloud dependencies.

### 2. Retrieval-Augmented Generation (RAG)
RAG frameworks are becoming standard for integrating external knowledge with language models, enabling more accurate and contextual responses.

### 3. Fine-tuning at Scale
More accessible fine-tuning tools allow businesses to customize models for specific use cases without extensive ML expertise.

## Actionable Insights
- **Adopt local models** for privacy and cost savings
- **Implement RAG** to improve answer accuracy
- **Fine-tune strategically** for domain-specific needs
- **Monitor efficiency** metrics alongside accuracy

## Conclusion
The democratization of AI is here. Teams can now build powerful, custom AI systems with local models and open-source tools.

## Join Our Community
Stay updated on the latest AI trends and practical insights. Follow us for weekly updates on tools, techniques, and opportunities in AI."
fi

# Extract title
TITLE="Local Open-Source AI: Practical Trends and Opportunities"
if echo "$GENERATED_POST" | head -1 | grep -q "^#"; then
  TITLE=$(echo "$GENERATED_POST" | head -1 | sed 's/^# *//')
fi

# Create slug
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /-/g' | cut -c1-50)

# Create post file
POST_FILE="$POSTS_DIR/${RESEARCH_DATE}-${SLUG}.md"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 📝 Creating post: $POST_FILE" | tee -a "$LOG_FILE"

cat > "$POST_FILE" << FRONTMATTER
---
title: "$TITLE"
date: $RESEARCH_DATE
slug: $SLUG
category: AI & Technology
tags: [ai, research, trends, automation]
author: APEX
status: draft
---

$GENERATED_POST
FRONTMATTER

WORD_COUNT=$(echo "$GENERATED_POST" | wc -w)
echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ Blog post generated" | tee -a "$LOG_FILE"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 📊 Words: $WORD_COUNT, Slug: $SLUG" | tee -a "$LOG_FILE"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✨ Status: DRAFT - Ready for review" | tee -a "$LOG_FILE"

# Log metadata
echo "{\"date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"post\": \"$POST_FILE\", \"words\": $WORD_COUNT, \"status\": \"draft\"}" >> "$REPO_ROOT/logs/post-generation.json"

echo ""
echo "✅ Blog post created: $POST_FILE"
echo "📊 Word count: $WORD_COUNT"
echo ""
echo "Next: Review the post, then run:"
echo "  git add $POST_FILE"
echo "  bash $SCRIPT_DIR/publish-blog-post.sh $POST_FILE"
