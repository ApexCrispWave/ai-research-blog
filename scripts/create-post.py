#!/usr/bin/env python3
"""
Create new blog post with frontmatter metadata
Handles reading time calculation, tag system, archive structure
"""

import json
import sys
import math
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
POSTS_DIR = REPO_ROOT / "posts"
ARCHIVE_DIR = REPO_ROOT / "archive"

FRONTMATTER_TEMPLATE = """---
title: "{title}"
date: {date}
author: "Research Bot"
tags: {tags}
category: {category}
reading_time: {reading_time} min
status: "draft"
word_count: {word_count}
---

{content}
"""

def calculate_reading_time(content):
    """Calculate reading time based on word count (avg 200 words/minute)"""
    words = len(content.split())
    return max(1, math.ceil(words / 200))

def create_post(title, content, tags=None, category="Research", date=None):
    """
    Create new blog post
    Returns path to created post
    """
    if not date:
        date = datetime.now().strftime("%Y-%m-%d")
    
    if not tags:
        tags = ["ai", "research"]
    
    # Ensure directories exist
    POSTS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Slugify title for filename
    slug = title.lower().replace(" ", "-").replace(":", "").replace("/", "-")
    slug = "".join(c for c in slug if c.isalnum() or c == "-")
    slug = slug[:50]  # Limit length
    
    filename = f"{date}-{slug}.md"
    filepath = POSTS_DIR / filename
    
    # Calculate metadata
    word_count = len(content.split())
    reading_time = calculate_reading_time(content)
    
    # Build frontmatter
    frontmatter = FRONTMATTER_TEMPLATE.format(
        title=title.replace('"', '\\"'),
        date=f'"{date}"',
        tags=json.dumps(tags),
        category=category,
        reading_time=reading_time,
        word_count=word_count,
        content=content
    )
    
    with open(filepath, 'w') as f:
        f.write(frontmatter)
    
    return filepath, {
        "title": title,
        "filename": filename,
        "path": str(filepath),
        "word_count": word_count,
        "reading_time": reading_time,
        "tags": tags,
        "date": date
    }

def archive_post(post_path, year_month):
    """
    Move post to archive based on date
    """
    archive_subdir = ARCHIVE_DIR / year_month[:7]  # YYYY-MM
    archive_subdir.mkdir(parents=True, exist_ok=True)
    
    import shutil
    archived = archive_subdir / Path(post_path).name
    shutil.copy(post_path, archived)
    return archived

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: create-post.py <title> <content_file> [tags] [category]", file=sys.stderr)
        sys.exit(1)
    
    title = sys.argv[1]
    content_file = sys.argv[2]
    tags = sys.argv[3].split(",") if len(sys.argv) > 3 else ["ai", "research"]
    category = sys.argv[4] if len(sys.argv) > 4 else "Research"
    
    try:
        with open(content_file) as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Content file not found: {content_file}", file=sys.stderr)
        sys.exit(1)
    
    filepath, metadata = create_post(title, content, tags, category)
    
    print(json.dumps({
        "status": "success",
        "post": metadata
    }, indent=2))
