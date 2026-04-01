#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$REPO_ROOT/logs"
POSTS_DIR="$REPO_ROOT/_posts"
RESEARCH_DIR="$REPO_ROOT/research"
TODAY="$(date +%Y-%m-%d)"
TMP_CONTENT="/tmp/ai-research-blog-${TODAY}.md"
TMP_JSON="/tmp/ai-research-${TODAY}.json"

mkdir -p "$LOG_DIR" "$POSTS_DIR" "$RESEARCH_DIR"

echo "[$(date)] Starting daily blog pipeline"
cd "$REPO_ROOT"

python3 "$REPO_ROOT/scripts/daily-research-consolidate.py" "$TODAY" > "$TMP_JSON"

python3 - "$REPO_ROOT" "$TODAY" "$TMP_CONTENT" <<'PY'
import json
import sys
from pathlib import Path

repo = Path(sys.argv[1])
date = sys.argv[2]
out = Path(sys.argv[3])
research_path = repo / 'research' / f'{date}.json'

with open(research_path) as f:
    data = json.load(f)

hn = data.get('sources', {}).get('hacker_news', {})
top = hn.get('top_stories', [])[:5]
ask = hn.get('ask_hn', [])[:3]

if not top and not ask:
    content = f"""The signal was thin today — no meaningful AI-heavy Hacker News stories cleared the filter. Rather than manufacture hype, this snapshot stays honest: the frontier is still moving, but not every day produces a breakout worth amplifying.

That in itself is useful. A disciplined AI research operation needs quiet-day handling, not just launch-day excitement. The edge comes from consistency, not noise.
"""
    title = f"AI Research Snapshot — {date}"
    tags = ['ai', 'research', 'snapshot']
    category = 'Research'
else:
    lines = []
    lines.append(f"Today’s AI research pulse is dominated by practical engineering, open tooling, and operator-level discussions rather than pure hype cycles. Here are the stories that mattered most on Hacker News.")
    lines.append("")
    lines.append("## Top Signals")
    lines.append("")
    for idx, item in enumerate(top, 1):
        title_i = item.get('title', 'Untitled')
        score = item.get('score', 0)
        comments = item.get('comments', 0)
        url = item.get('url', '')
        domain = ''
        if url:
            try:
                from urllib.parse import urlparse
                domain = urlparse(url).netloc
            except Exception:
                domain = ''
        suffix = f" ({domain})" if domain else ''
        lines.append(f"### {idx}. {title_i}{suffix}")
        lines.append(f"This item pulled **{score} points** and **{comments} comments**, which usually means builders are paying attention. The real value is less the headline itself and more what it signals about where technical attention is concentrating right now.")
        if url:
            lines.append(f"Source: {url}")
        lines.append("")
    if ask:
        lines.append("## What Operators Are Asking")
        lines.append("")
        for item in ask:
            lines.append(f"- **{item.get('title', 'Untitled')}** — {item.get('comments', 0)} comments, {item.get('score', 0)} points")
        lines.append("")
    lines.append("## Takeaway")
    lines.append("")
    lines.append("The pattern remains consistent: practical AI infrastructure, local-model execution, and deployable tooling keep winning attention. That’s a healthier signal than generic AGI chatter because it points to work people can actually ship.")
    content = "\n".join(lines)
    title = f"AI Research Pulse — {date}"
    tags = ['ai', 'research', 'hacker-news', 'automation']
    category = 'Research'

slug = title.lower().replace(' ', '-').replace(':', '')
slug = ''.join(c for c in slug if c.isalnum() or c == '-')[:60]
post_path = repo / '_posts' / f'{date}-{slug}.md'
frontmatter = f'''---
layout: post
title: "{title}"
date: "{date}"
author: "APEX"
tags: {json.dumps(tags)}
category: {category}
---

{content}
'''
with open(post_path, 'w') as f:
    f.write(frontmatter)
with open(out, 'w') as f:
    f.write(content)
print(post_path)
PY

python3 "$REPO_ROOT/scripts/generate-rss.py" > /tmp/ai-rss-${TODAY}.json || true

git add _posts/ research/ feed.xml scripts/
if ! git diff --cached --quiet; then
  git commit -m "Daily snapshot: ${TODAY}"
  git push origin main
  echo "[$(date)] Pipeline complete: committed and pushed"
else
  echo "[$(date)] No changes to commit"
fi
