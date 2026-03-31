# Operations Manual — AI Research Blog System

## Quick Start

### One-Time Setup
```bash
cd /Users/openclaw/Projects/ai-research-blog

# Install cron jobs
bash scripts/setup-cron.sh

# Set environment variables (optional, for syndication)
export DEVTO_API_KEY="your_key"
export MEDIUM_TOKEN="your_token"
```

### Manual Publishing Flow
```bash
# Run research aggregation
bash scripts/aggregate-research.sh

# Generate blog post
bash scripts/generate-blog-post.sh

# Publish
bash scripts/publish-latest-blog.sh
```

### Check Status
```bash
# View latest posts
ls -lt posts/*.md | head -3

# Check logs
tail -f logs/blog-generation.log
tail -f logs/publishing.log

# Verify GitHub push
git log --oneline | head -3
```

---

## Detailed Workflows

### Workflow 1: Generate Research Only

```bash
# Run research aggregation
bash scripts/aggregate-research.sh

# Output: research/research-YYYY-MM-DD.json
# Contains: YouTube trends, Hacker News, Product Hunt insights, analysis
```

**When to use:**
- Nightly data gathering
- Building research history
- Manual review before post generation

---

### Workflow 2: Generate Blog Post Manually

```bash
# Prerequisite: research file must exist
bash scripts/aggregate-research.sh

# Generate post from research
bash scripts/generate-blog-post.sh 2026-03-30

# Review generated post
cat posts/*.md | less

# Update status if satisfied
sed -i 's/status: draft/status: published/' posts/*.md
```

**When to use:**
- Testing the generator
- Creating urgent posts
- Manual content curation

---

### Workflow 3: Full Automated Publishing

```bash
# One-time setup
bash scripts/setup-cron.sh

# Then sits back - cron handles:
# 12:15 AM daily  → Research aggregation
# 6:00 AM Sunday  → Blog post generation
# 6:30 AM Sunday  → Publishing
```

**Schedule:**
```
15 0 * * * → Daily research (every day at 12:15 AM)
0 6 * * 0 → Weekly generation (Sundays 6 AM)
30 6 * * 0 → Weekly publish (Sundays 6:30 AM)
```

---

### Workflow 4: Publishing to Multiple Platforms

```bash
# Publish to GitHub Pages only
bash scripts/publish-blog-post.sh posts/*.md --no-syndication

# Publish to all configured platforms
bash scripts/publish-blog-post.sh posts/*.md
# (Will auto-publish to Dev.to, Medium, Substack, Twitter if keys are set)
```

**Platforms supported:**
- ✅ GitHub Pages (always)
- ✅ Dev.to (if DEVTO_API_KEY set)
- ✅ Medium (if MEDIUM_TOKEN set)
- ✅ Substack (if SUBSTACK_API_KEY set)
- ✅ Twitter/X (if TWITTER_BEARER_TOKEN set)

---

## Script Reference

### `aggregate-research.sh`
**Purpose:** Gather AI research from multiple sources

**Usage:**
```bash
bash scripts/aggregate-research.sh [YYYY-MM-DD]
```

**Inputs:**
- Optional date (defaults to today)

**Outputs:**
- `research/research-YYYY-MM-DD.json` (research data)
- `logs/research-aggregation.log` (execution log)

**Time:** ~5 seconds

**Data collected:**
- YouTube AI channels
- Hacker News top stories and AI discussions
- Product Hunt trending tools
- Market analysis and trend synthesis

---

### `generate-blog-post.sh`
**Purpose:** Create blog post from research using qwen3.5:9b

**Usage:**
```bash
bash scripts/generate-blog-post.sh [YYYY-MM-DD] [optional_title]
```

**Inputs:**
- Research JSON from research/ directory
- Optional custom title

**Outputs:**
- `posts/YYYY-MM-DD-slug.md` (blog post with frontmatter)
- `logs/blog-generation.log` (execution log)

**Time:** 30-120 seconds (qwen3.5:9b generation)

**Features:**
- Auto-generates slug from title
- Includes frontmatter (title, date, tags, etc.)
- Fallback content if model fails
- Word count tracking

---

### `publish-blog-post.sh`
**Purpose:** Publish blog to GitHub Pages + syndication

**Usage:**
```bash
bash scripts/publish-blog-post.sh <post_file> [--no-github] [--no-syndication]
```

**Inputs:**
- Path to markdown post file
- Optional flags to skip platforms

**Outputs:**
- Git commit and push
- Updated post status (draft → published)
- Syndication posts (if enabled)
- `logs/publishing.log`

**Time:** 5-60 seconds (includes git push)

**Platforms triggered:**
- GitHub Pages (auto)
- Dev.to, Medium, Substack (if API keys set)
- Twitter/X (if credentials set)

---

### `validate-posts.sh`
**Purpose:** Check posts for quality and correctness

**Usage:**
```bash
bash scripts/validate-posts.sh
```

**Checks:**
- Frontmatter integrity
- Required fields (title, date, slug)
- Word count (warns if <1800)
- Status field
- No placeholder text

**Output:**
- `logs/validation.log`
- Exit code 0 = valid, 1 = invalid

---

### `setup-cron.sh`
**Purpose:** Install automated nightly jobs

**Usage:**
```bash
# Preview (dry run)
bash scripts/setup-cron.sh --dry-run

# Install (for real)
bash scripts/setup-cron.sh
```

**Installs:**
- 12:15 AM daily: Research aggregation
- 6:00 AM Sunday: Blog post generation
- 6:30 AM Sunday: Publishing

**Management:**
```bash
crontab -l              # View jobs
crontab -e              # Edit jobs
crontab -r              # Remove all jobs
```

---

### `publish-latest-blog.sh`
**Purpose:** Publish the most recent post (helper)

**Usage:**
```bash
# Preview
bash scripts/publish-latest-blog.sh --dry-run

# Publish
bash scripts/publish-latest-blog.sh
```

**Logic:**
1. Find most recent post
2. Validate it
3. Publish to GitHub + syndication

---

## Logging & Monitoring

### Log Files

```
logs/
├── blog-generation.log          # Blog generation runs
├── publishing.log               # Publishing pipeline
├── research-aggregation.log     # Research gathering
├── validation.log               # Post validation
├── cron-research.log            # Cron research runs
├── cron-blog-gen.log            # Cron generation runs
├── cron-publishing.log          # Cron publishing runs
├── research-aggregation.json    # Research metadata
├── post-generation.json         # Generation metadata
└── published-posts.json         # Publishing metadata
```

### View Logs

```bash
# Real-time monitoring
tail -f logs/blog-generation.log

# Last 50 lines
tail -50 logs/publishing.log

# Search for errors
grep "❌" logs/*.log

# Full history
cat logs/blog-generation.log | less
```

### Check Cron Logs (macOS)

```bash
# View system cron logs
log stream --level debug --predicate 'process == "cron"'

# Filter for blog system
log stream --predicate 'process == "cron"' | grep "ai-research"
```

---

## Troubleshooting

### Issue: Posts not appearing on GitHub Pages

**Diagnosis:**
```bash
# Check if commit was pushed
git log --oneline | head -1

# Check GitHub Actions
open https://github.com/ApexCrispWave/ai-research-blog/actions

# Check if Jekyll built
curl -I https://ApexCrispWave.github.io/ai-research-blog
```

**Solutions:**
1. Verify remote is correct:
   ```bash
   git remote -v
   ```

2. Try manual rebuild:
   ```bash
   git push origin main --force
   ```

3. Check GitHub Actions workflow status

---

### Issue: Blog post generation fails

**Diagnosis:**
```bash
# Check ollama is running
ps aux | grep ollama

# Check model is loaded
ollama list | grep qwen3.5

# Check logs
tail logs/blog-generation.log
```

**Solutions:**
1. Start ollama if stopped:
   ```bash
   ollama serve &
   ```

2. Pull model if missing:
   ```bash
   ollama pull qwen3.5:9b
   ```

3. Check free disk space:
   ```bash
   df -h | grep Volumes
   ```

---

### Issue: Research aggregation is slow

**Diagnosis:**
- Check if network is available
- Check if curl/jq are installed
- Check logs for errors

**Solutions:**
```bash
# Verify dependencies
curl --version
jq --version

# Run with debug output
bash -x scripts/aggregate-research.sh
```

---

### Issue: Syndication not working

**Diagnosis:**
```bash
# Check if API keys are set
echo $DEVTO_API_KEY
echo $MEDIUM_TOKEN
echo $SUBSTACK_API_KEY
echo $TWITTER_BEARER_TOKEN
```

**Solutions:**
1. Set environment variables:
   ```bash
   export DEVTO_API_KEY="your_key"
   ```

2. Add to shell profile for persistence:
   ```bash
   echo 'export DEVTO_API_KEY="your_key"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. Verify by testing one platform:
   ```bash
   DEVTO_API_KEY="test" bash scripts/publish-to-devto.sh posts/*.md
   ```

---

## Maintenance

### Daily
- Monitor logs for errors
- Check blog posts are generating

### Weekly
- Verify published posts appear on blog
- Check syndication platforms
- Review analytics if enabled

### Monthly
- Check disk space
- Review and optimize prompts
- Update cron jobs if needed

### Quarterly
- Review blog performance
- Update documentation
- Plan feature improvements

---

## Performance Tuning

### Speed Up Generation

1. **Reduce model size (if needed):**
   - Use qwen3:8b instead of qwen3.5:9b
   - Trade: Faster, but lower quality

2. **Cache research results:**
   - Reuse yesterday's research for multiple posts
   - Faster: No re-scraping

3. **Parallel execution:**
   - Run multiple generators
   - Need: More compute, storage

### Optimize Storage

```bash
# Clean old logs (keep 30 days)
find logs -name "*.log" -mtime +30 -delete

# Compress research history
gzip research/research-*.json

# Archive published posts
tar -czf archive/posts-2026-q1.tar.gz posts/
```

---

## Advanced Configuration

### Custom Prompts

Edit these sections in scripts:

**Research prompt:**
```bash
# In: aggregate-research.sh
# Line: "RESEARCH_JSON=$(cat << 'EOF'"
```

**Blog generation prompt:**
```bash
# In: generate-blog-post.sh
# Line: "BLOG_PROMPT="
```

### Custom Cron Schedule

```bash
# Edit crontab
crontab -e

# Examples:
# Every 6 hours: 0 */6 * * *
# Every morning: 0 9 * * *
# Every Monday: 0 9 * * 1
```

### Custom Syndication

Create new script:
```bash
cp scripts/publish-to-devto.sh scripts/publish-to-myplatform.sh
# Edit with platform API details
# Add to publish-blog-post.sh
```

---

## Recovery & Backup

### Backup to Local Drive
```bash
cp -r /Users/openclaw/Projects/ai-research-blog ~/Backups/blog-backup-$(date +%Y%m%d)
```

### Restore from GitHub
```bash
cd /Users/openclaw/Projects
rm -rf ai-research-blog
git clone https://github.com/ApexCrispWave/ai-research-blog.git
cd ai-research-blog
git pull origin main
```

### Recover Lost Posts
```bash
# View git history
git log --name-only | grep posts/

# Restore deleted post
git checkout <commit-hash> -- posts/filename.md
```

---

## Escalation & Support

**For errors:**
1. Check logs in `logs/` directory
2. Verify environment (ollama running, git configured)
3. Consult troubleshooting section above
4. Check GitHub Actions for build failures

**For feature requests:**
1. Document the request
2. Estimate effort
3. Plan sprint
4. Implement with tests

---

**Last Updated:** 2026-03-30  
**System Version:** 1.0.0  
**Maintainer:** APEX
