#!/usr/bin/env python3
"""
Generate RSS feed from blog posts.
Reads Jekyll _posts/ markdown files and creates feed.xml.
"""

from datetime import datetime
from pathlib import Path
import json
import html
import re

REPO_ROOT = Path(__file__).parent.parent
POSTS_DIR = REPO_ROOT / "_posts"
FEED_FILE = REPO_ROOT / "feed.xml"
SITE_URL = "https://apexcrispwave.github.io/ai-research-blog"


def extract_frontmatter(content):
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return {}

    fm = {}
    for line in match.group(1).split("\n"):
        if ":" in line:
            key, value = line.split(":", 1)
            fm[key.strip()] = value.strip().strip('"')
    return fm


def get_post_body(content):
    match = re.match(r"^---\n.*?\n---\n(.*)", content, re.DOTALL)
    return match.group(1).strip() if match else content.strip()


def generate_rss():
    POSTS_DIR.mkdir(parents=True, exist_ok=True)

    posts = []
    for post_file in sorted(POSTS_DIR.glob("*.md"), reverse=True):
        content = post_file.read_text()
        fm = extract_frontmatter(content)
        body = get_post_body(content)
        posts.append(
            {
                "title": fm.get("title", post_file.stem),
                "date": fm.get("date", datetime.now().strftime("%Y-%m-%d")),
                "path": post_file.name,
                "excerpt": body[:240],
                "category": fm.get("category", "Research"),
            }
        )

    rss = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<rss version="2.0">',
        '  <channel>',
        '    <title>AI Research &amp; Trends</title>',
        f'    <link>{SITE_URL}</link>',
        '    <description>Daily AI research, local model optimization, and autonomous systems analysis.</description>',
        '    <language>en-us</language>',
    ]

    for post in posts[:20]:
        rss.extend(
            [
                '    <item>',
                f'      <title>{html.escape(post["title"])}</title>',
                f'      <link>{SITE_URL}/{post["path"].replace(".md", ".html")}</link>',
                f'      <pubDate>{html.escape(post["date"])}</pubDate>',
                f'      <category>{html.escape(post["category"])}</category>',
                f'      <description>{html.escape(post["excerpt"])}</description>',
                '    </item>',
            ]
        )

    rss.extend(['  </channel>', '</rss>'])
    FEED_FILE.write_text("\n".join(rss) + "\n")

    print(json.dumps({"status": "success", "feed_file": str(FEED_FILE), "posts_included": len(posts[:20])}, indent=2))


if __name__ == "__main__":
    generate_rss()
