#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$REPO_ROOT/logs"
POSTS_DIR="$REPO_ROOT/_posts"
RESEARCH_DIR="$REPO_ROOT/research"
TODAY="$(date +%Y-%m-%d)"
TMP_CONTENT="/tmp/ai-research-blog-${TODAY}.md"
TMP_JSON="/tmp/ai-research-${TODAY}.json"
STYLE_GUIDE="/Users/openclaw/.openclaw/workspace/research/9to5mac/style-guide.md"

mkdir -p "$LOG_DIR" "$POSTS_DIR" "$RESEARCH_DIR"

echo "[$(date)] Starting daily blog pipeline"
cd "$REPO_ROOT"

python3 "$REPO_ROOT/scripts/daily-research-consolidate.py" "$TODAY" > "$TMP_JSON"

python3 - "$REPO_ROOT" "$TODAY" "$TMP_CONTENT" "$STYLE_GUIDE" <<'PY'
import json
import sys
from pathlib import Path

repo = Path(sys.argv[1])
date = sys.argv[2]
out = Path(sys.argv[3])
style_guide_path = Path(sys.argv[4]) if len(sys.argv) > 4 else None
research_path = repo / 'research' / f'{date}.json'

# Load style guide if available
style_rules = ""
if style_guide_path and style_guide_path.exists():
    style_rules = style_guide_path.read_text()
    print(f"[style] Loaded 9to5Mac style guide ({len(style_rules)} chars)", file=sys.stderr)

with open(research_path) as f:
    data = json.load(f)

hn = data.get('sources', {}).get('hacker_news', {})
top = hn.get('top_stories', [])[:5]
ask = hn.get('ask_hn', [])[:3]

if not top and not ask:
    content = f"""The signal was thin today - no meaningful AI-heavy Hacker News stories cleared the filter. Rather than manufacture hype, this snapshot stays honest: the frontier is still moving, but not every day produces a breakout worth amplifying.

That in itself is useful. A disciplined AI research operation needs quiet-day handling, not just launch-day excitement. The edge comes from consistency, not noise.
"""
    title = f"AI Research Snapshot - {date}"
    tags = ['ai', 'research', 'snapshot']
    category = 'Research'
else:
    lines = []
    # Apply 9to5Mac style: lead immediately with the top story, no warmup
    top_story = top[0] if top else None
    top_score = top_story.get('score', 0) if top_story else 0
    top_title = top_story.get('title', '') if top_story else ''

    # Style-guided lead: strong opener referencing the #1 story directly
    if top_story and top_score >= 100:
        lead = f"**{top_title}** is driving {top_score} points and builder attention on Hacker News today — here's what it signals and why it matters."
    else:
        lead = f"Today's AI research pulse: practical engineering, open tooling, and operator-level discussion dominate. Here are the {len(top)} stories worth your attention."

    lines.append(lead)
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
        # Style: headline formula — use numbers and strong verbs
        score_label = f"**{score} points**" if score >= 50 else f"{score} points"
        suffix = f" ({domain})" if domain else ''
        lines.append(f"### {idx}. {title_i}{suffix}")
        lines.append(f"Pulled {score_label} and **{comments} comments** — builders are paying attention. This signals where practical AI work is concentrating right now.")
        if url:
            lines.append(f"[Read more →]({url})")
        lines.append("")
    if ask:
        lines.append("## What Operators Are Asking")
        lines.append("")
        for item in ask:
            lines.append(f"- **{item.get('title', 'Untitled')}** — {item.get('comments', 0)} comments, {item.get('score', 0)} points")
        lines.append("")
    lines.append("## Takeaway")
    lines.append("")
    lines.append("The pattern holds: practical AI infrastructure, local-model execution, and deployable tooling keep winning attention over AGI speculation. Build what ships.")
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

LATEST_POST="$(ls -t "$REPO_ROOT/_posts"/*.md | head -1)"
if [ -n "${DEVTO_API_KEY:-}" ] && [ -f "$LATEST_POST" ]; then
  python3 "$REPO_ROOT/scripts/publish-to-devto.py" "$LATEST_POST" > "$LOG_DIR/devto-${TODAY}.json" || true
fi

git add _posts/ research/ feed.xml scripts/ logs/
if ! git diff --cached --quiet; then
  git commit -m "Daily snapshot: ${TODAY}"
  git push origin main
  echo "[$(date)] Pipeline complete: committed and pushed"
else
  echo "[$(date)] No changes to commit"
fi
