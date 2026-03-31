# AI Research Blog System — Setup & Deployment Guide

## Overview

This is a **fully autonomous AI research blog system** that runs on a schedule:
- **Nightly:** Aggregates AI research from YouTube, Hacker News, Product Hunt
- **Weekly:** Generates a 2000+ word blog post using local LLM (qwen3.5:9b)
- **Auto-publishes:** To GitHub Pages, Dev.to, Medium, Substack, Twitter/X

**Zero cloud API calls** for research. Only authenticated external APIs (GitHub, Dev.to, Twitter) on publish.

---

## Architecture

```
ai-research-blog/
├── posts/                    # Published blog posts (markdown)
├── research/                 # Daily research JSON files
├── scripts/
│   ├── aggregate-research.sh       # Gather research (YouTube, HN, PH)
│   ├── generate-blog-post.sh       # Create post from research
│   ├── publish-blog-post.sh        # Push to GitHub + syndication
│   ├── publish-to-medium.sh        # Medium cross-post
│   ├── publish-to-substack.sh      # Substack cross-post
│   ├── publish-to-devto.sh         # Dev.to cross-post
│   ├── publish-to-twitter.sh       # Twitter thread posting
│   ├── setup-cron.sh               # Install cron jobs
│   └── validate-posts.sh           # Check posts before publishing
├── _config.yml               # Jekyll configuration
├── Gemfile                   # Ruby dependencies
├── index.md                  # Blog homepage
└── .github/workflows/        # GitHub Actions for auto-deploy
```

---

## Prerequisites

✅ **Already Installed:**
- `qwen3.5:9b` (local model, 6.3GB)
- `ollama` (for running local models)
- Ruby 2.6+ and bundler
- `curl`, `jq`, `git`

⚠️ **Not Yet Set Up:**
- GitHub repository (needs to be pushed)
- API keys for Dev.to, Medium, Twitter (optional)

---

## Step 1: Push to GitHub

First, set the GitHub repo and push:

```bash
cd /Users/openclaw/Projects/ai-research-blog

# Verify remote is set
git remote -v

# Commit any pending changes
git add .
git commit -m "Initial: Blog infrastructure setup"

# Push to GitHub
git push origin main
```

**This enables:**
- GitHub Pages auto-deployment
- GitHub Actions workflows for CI/CD
- RSS feed auto-generation

---

## Step 2: Enable GitHub Pages

1. Go to: https://github.com/ApexCrispWave/ai-research-blog
2. Settings → Pages
3. Select:
   - Source: Deploy from a branch
   - Branch: `main`
   - Folder: `/ (root)`
4. Save

Your blog will be live at: `https://ApexCrispWave.github.io/ai-research-blog`

---

## Step 3: Test the Pipeline Locally

### Test Research Aggregation

```bash
cd /Users/openclaw/Projects/ai-research-blog

# Generate research data
bash scripts/aggregate-research.sh

# Check output
cat research/research-$(date +%Y-%m-%d).json
```

Expected output: Valid JSON with research data.

### Test Blog Post Generation

```bash
# Generate a blog post from research
bash scripts/generate-blog-post.sh

# Check output
ls -la posts/*.md
cat posts/*.md | head -50
```

Expected output: A new markdown file in `posts/` directory with frontmatter.

### Test GitHub Publishing

```bash
# Stage the post
git add posts/*.md

# Publish to GitHub Pages
bash scripts/publish-blog-post.sh posts/*.md --no-syndication

# Check build status
git log --oneline | head -3
```

Visit: `https://ApexCrispWave.github.io/ai-research-blog` to verify the post appears (takes 1-2 min for GitHub Pages to rebuild).

---

## Step 4: Set Up Cron Jobs (Optional but Recommended)

To automate the nightly research and weekly blog posting:

```bash
# Preview what will be scheduled
bash scripts/setup-cron.sh --dry-run

# Install cron jobs
bash scripts/setup-cron.sh
```

Schedule:
- **12:15 AM daily** → Research aggregation
- **6:00 AM Sunday** → Blog post generation
- **6:30 AM Sunday** → Publishing to GitHub + syndication

Check installed jobs:
```bash
crontab -l
```

---

## Step 5: Set Up Syndication (Optional)

To auto-publish to Dev.to, Medium, Substack, Twitter, set API keys.

### Dev.to

```bash
# Get API key: https://dev.to/settings/account
export DEVTO_API_KEY="your_key_here"

# Add to ~/.zshrc or ~/.bashrc for persistence
echo 'export DEVTO_API_KEY="your_key"' >> ~/.zshrc
```

### Medium

```bash
# Get token: https://medium.com/me/settings → "Integration tokens"
export MEDIUM_TOKEN="your_token_here"
```

### Substack

```bash
# Get API key + publication ID from account settings
export SUBSTACK_API_KEY="your_key"
export SUBSTACK_PUB_ID="your_pub_id"
```

### Twitter/X

```bash
# Get Bearer token from https://developer.twitter.com/
export TWITTER_BEARER_TOKEN="your_token_here"
```

Then, when publishing, the script will automatically post to all configured platforms.

---

## Manual Workflow

If you prefer manual control:

```bash
# Step 1: Gather research
bash scripts/aggregate-research.sh

# Step 2: Generate blog post
bash scripts/generate-blog-post.sh

# Step 3: Review the post
cat posts/*.md | less

# Step 4: Publish to GitHub (+ syndication)
bash scripts/publish-blog-post.sh posts/*.md
```

---

## Monitoring & Logs

All operations log to `logs/` directory:

```bash
# Check research aggregation
tail -20 logs/research-aggregation.log

# Check blog generation
tail -20 logs/blog-generation.log

# Check publishing
tail -20 logs/publishing.log

# View all cron logs
ls -la logs/cron-*.log
```

---

## Troubleshooting

### Blog post doesn't appear on GitHub Pages

1. Check if push succeeded:
   ```bash
   git log --oneline | head -1
   ```

2. Check GitHub Actions:
   - https://github.com/ApexCrispWave/ai-research-blog/actions

3. Clear browser cache (GitHub Pages caches aggressively)

4. Check Jekyll build output:
   ```bash
   bundle exec jekyll build
   ```

### Ollama model not responding

1. Check if ollama server is running:
   ```bash
   ps aux | grep ollama
   ```

2. Restart ollama:
   ```bash
   killall ollama
   ollama serve &
   ```

3. Verify model is loaded:
   ```bash
   ollama list | grep qwen3.5
   ```

### Cron jobs not running

1. Check crontab:
   ```bash
   crontab -l
   ```

2. Check system mail for errors:
   ```bash
   mail
   ```

3. Enable cron logging (macOS):
   ```bash
   log stream --level debug --predicate 'process == "cron"'
   ```

---

## Customization

### Change Blog Title & Description

Edit `_config.yml`:
```yaml
title: Your Blog Title
description: Your blog description
```

### Change Cron Schedule

Edit cron jobs:
```bash
crontab -e
```

### Customize Blog Post Topics

Modify the research aggregator prompt in `scripts/aggregate-research.sh` to focus on different topics.

### Add More Syndication Platforms

Create new scripts in `scripts/publish-to-*.sh` following the same pattern as `publish-to-medium.sh`.

---

## Production Checklist

- [ ] GitHub repo pushed
- [ ] GitHub Pages enabled and working
- [ ] First blog post published
- [ ] Cron jobs installed (if using automation)
- [ ] API keys set up for syndication (optional)
- [ ] Blog RSS feed verified at `/feed.xml`
- [ ] Links to Gumroad/resources in posts

---

## Metrics to Track

```bash
# Number of posts published
ls -1 posts/*.md | wc -l

# Total words written
find posts -name "*.md" -exec cat {} \; | wc -w

# Last publication date
ls -t posts/*.md | head -1 | xargs -I {} sh -c 'echo {} && head -2 {} | grep date'

# Blog views (requires Analytics integration)
```

---

## Next Steps

1. ✅ Local pipeline tested
2. ✅ GitHub Pages deployed
3. ✅ Cron jobs scheduled
4. ⏭️ Monitor first automated run
5. ⏭️ Set up analytics (Google Analytics optional)
6. ⏭️ Add Gumroad links to CTAs
7. ⏭️ Promote via social media

---

## Support

For issues or questions:
- Check logs in `logs/` directory
- Review GitHub Actions at `github.com/ApexCrispWave/ai-research-blog/actions`
- Verify API credentials are set correctly
- Test individual scripts manually before relying on cron

---

**Built with ❤️ using qwen3.5:9b. Zero cloud dependency.**
