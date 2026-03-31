# Quick Start Guide - AI Research Blog

## Daily Workflow

### 1. Run Daily Research Aggregation
```bash
cd /Users/openclaw/.openclaw/workspace/ai-research-blog
python3 scripts/daily-research-consolidate.py
# Output: research/YYYY-MM-DD.json
```

### 2. Create Blog Post
```bash
# Create your post content
echo "Your content here..." > /tmp/my_post.txt

# Create post with metadata
python3 scripts/create-post.py \
  "My Post Title" \
  /tmp/my_post.txt \
  "tag1,tag2,tag3" \
  "Category"

# Output: posts/YYYY-MM-DD-slug.md
```

### 3. Generate RSS Feed
```bash
python3 scripts/generate-rss.py
# Updates feed.xml
```

### 4. Commit & Push
```bash
git add posts/ research/ feed.xml
git commit -m "Add new post and research for YYYY-MM-DD"
git push origin main
# GitHub Pages auto-deploys
```

---

## Cron Jobs (Optional)

### Daily Research (3 AM Pacific)
```bash
0 3 * * * cd /Users/openclaw/.openclaw/workspace/ai-research-blog && python3 scripts/daily-research-consolidate.py >> logs/aggregation.log 2>&1
```

### Weekly RSS (Sunday 6 AM)
```bash
0 6 * * 0 cd /Users/openclaw/.openclaw/workspace/ai-research-blog && python3 scripts/generate-rss.py >> logs/rss.log 2>&1
```

---

## Useful Commands

### View today's research
```bash
cat research/$(date +%Y-%m-%d).json | jq .
```

### List all posts
```bash
ls -lh posts/
```

### Search posts by tag
```bash
grep -r "tag: \"llm\"" posts/
```

### Verify RSS feed
```bash
curl http://localhost/feed.xml | head -20
```

### Test model integration
```bash
bash scripts/test-model-json.sh
```

---

## Troubleshooting

**Posts not showing in feed?**
- Run: `python3 scripts/generate-rss.py`

**Model timeout?**
- Check: `ollama list`
- Restart: `brew services restart ollama`

**Git push fails?**
- Verify: `git remote -v`
- Check: `gh auth login` (if using GitHub CLI)

---

## Next: Connect to GitHub

```bash
git remote add origin https://github.com/YOUR_USER/ai-research-blog.git
git branch -M main
git push -u origin main
```

Then enable GitHub Pages: Settings → Pages → Deploy from gh-pages branch

---

**Ready to go!** Start with `python3 scripts/daily-research-consolidate.py` 🚀
