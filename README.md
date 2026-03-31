# AI Research Blog - Autonomous Publishing System

Lightweight, local-model-driven blog system that aggregates AI research from Hacker News, YouTube, and Product Hunt, then auto-publishes via GitHub Pages.

## Structure

```
ai-research-blog/
├── posts/                    # Published blog posts (markdown with frontmatter)
├── research/                 # Daily research aggregation (YYYY-MM-DD.json)
├── archive/                  # Older posts organized by date
├── drafts/                   # Work in progress
├── logs/                     # Aggregation logs (gitignored)
├── scripts/                  # Python/Bash automation
│   ├── aggregate-research.sh      # Main aggregation orchestrator
│   ├── hacker-news-fetch.py       # HN API polling
│   ├── daily-research-consolidate.py # Consolidate sources
│   ├── create-post.py             # Create new post with metadata
│   └── generate-rss.py            # RSS feed generation
├── .github/workflows/        # GitHub Actions for auto-deploy
├── feed.xml                  # Generated RSS feed
└── README.md
```

## Quick Start

### 1. Run Daily Research Aggregation

```bash
python3 scripts/daily-research-consolidate.py
```

Generates `research/YYYY-MM-DD.json` with top AI posts from Hacker News.

### 2. Create a Test Post

```bash
# Create content
echo "This is a test post about LLM trends..." > test_content.txt

# Create post with metadata
python3 scripts/create-post.py "LLM Trends Q1 2026" test_content.txt "llm,trends" "Analysis"
```

### 3. Generate RSS Feed

```bash
python3 scripts/generate-rss.py
```

Creates `feed.xml` from all posts in `posts/`.

### 4. GitHub Setup

```bash
# Initialize git repo
git init
git add .
git commit -m "Initial commit: research blog setup"
git remote add origin https://github.com/YOUR_USER/ai-research-blog.git
git branch -M main
git push -u origin main

# Create gh-pages branch (auto-deployed)
git checkout --orphan gh-pages
git rm -rf .
git commit --allow-empty -m "Initialize gh-pages branch"
git push -u origin gh-pages

# Switch back to main
git checkout main
```

## Local Model Integration

### Verify Ollama Installation

```bash
ollama list | grep qwen
```

Expected: `qwen3.5:9b` available

### Test Model Output

```bash
echo "Summarize the latest AI trends in 3 bullet points" | ollama run qwen3.5:9b
```

### Parse JSON from Model

```bash
echo '{"prompt": "List top 3 AI tools", "format": "json"}' | \
  ollama run qwen3.5:9b | \
  jq '.tools'
```

## Cron Scheduling

### Daily Research Aggregation (3 AM Pacific)

```bash
0 3 * * * cd /Users/openclaw/.openclaw/workspace/ai-research-blog && \
  python3 scripts/daily-research-consolidate.py >> logs/cron.log 2>&1
```

### Weekly RSS Generation (Sunday 6 AM)

```bash
0 6 * * 0 cd /Users/openclaw/.openclaw/workspace/ai-research-blog && \
  python3 scripts/generate-rss.py >> logs/rss-gen.log 2>&1
```

## Features

- ✅ **Lightweight**: Pure Python/Bash, no heavy frameworks
- ✅ **Local Models**: Uses Ollama qwen3.5:9b for processing
- ✅ **No Cloud APIs**: Hacker News only (free, unauthenticated)
- ✅ **Frontmatter Metadata**: Auto-calculated reading time, word count, tags
- ✅ **RSS Feed**: Auto-generated feed.xml
- ✅ **GitHub Pages Ready**: Push main → auto-deploys to gh-pages
- ✅ **Archive Structure**: Posts organized by YYYY-MM
- ✅ **Logging**: All operations logged to logs/

## Next Steps

1. Connect to GitHub repository
2. Set up cron jobs for daily aggregation
3. Test auto-deploy workflow with a manual post
4. Integrate with local Ollama for post summarization
5. Scale to multiple research sources (YouTube, Product Hunt)

## Notes

- Product Hunt and YouTube aggregation require authentication/API keys
- Current setup uses HN free API (rate-limited to ~100 req/min)
- RSS feed uses placeholder domain — update before deploying publicly
- All timestamps in UTC; adjust as needed for your timezone

---

**Status**: ✅ Ready for testing and integration
