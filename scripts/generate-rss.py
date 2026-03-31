#!/usr/bin/env python3
"""
Generate RSS feed from blog posts
Reads all posts/ markdown files and creates feed.xml
"""

import json
import sys
from datetime import datetime
from pathlib import Path
import re

REPO_ROOT = Path(__file__).parent.parent
POSTS_DIR = REPO_ROOT / "posts"
FEED_FILE = REPO_ROOT / "feed.xml"

def extract_frontmatter(content):
    """Extract YAML frontmatter from markdown"""
    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return {}
    
    fm_text = match.group(1)
    fm = {}
    for line in fm_text.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            fm[key.strip()] = value.strip().strip('"')
    return fm

def get_post_body(content):
    """Extract markdown body after frontmatter"""
    match = re.match(r'^---\n.*?\n---\n(.*)', content, re.DOTALL)
    if match:
        return match.group(1).strip()
    return content

def generate_rss():
    """Generate RSS 2.0 feed from all posts"""
    
    if not POSTS_DIR.exists():
        print(f"Posts directory not found: {POSTS_DIR}", file=sys.stderr)
        return
    
    posts = []
    for post_file in sorted(POSTS_DIR.glob("*.md"), reverse=True):
        try:
            with open(post_file) as f:
                content = f.read()
            
            fm = extract_frontmatter(content)
            body = get_post_body(content)
            
            posts.append({
                'title': fm.get('title', post_file.stem),
                'date': fm.get('date', datetime.now().isoformat()),
                'path': post_file.name,
                'excerpt': body[:200],
                'tags': fm.get('tags', '').strip('[]').split(',') if fm.get('tags') else [],
                'category': fm.get('category', 'General')
            })
        except Exception as e:
            print(f"Error processing {post_file}: {e}", file=sys.stderr)
    
    # Build RSS
    rss = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>AI Research Blog</title>
    <link>https://example.com/ai-research-blog</link>
    <description>Daily AI Research and Trends</description>
    <language>en-us</language>
'''
    
    for post in posts[:20]:  # Last 20 posts
        rss += f'''    <item>
      <title>{post['title']}</title>
      <link>https://example.com/posts/{post['path']}</link>
      <pubDate>{post['date']}</pubDate>
      <category>{post['category']}</category>
      <description>{post['excerpt']}</description>
    </item>
'''
    
    rss += '''  </channel>
</rss>'''
    
    with open(FEED_FILE, 'w') as f:
        f.write(rss)
    
    print(json.dumps({
        "status": "success",
        "feed_file": str(FEED_FILE),
        "posts_included": len(posts[:20])
    }, indent=2))

if __name__ == "__main__":
    generate_rss()
