#!/usr/bin/env python3
"""
Hacker News AI Research Fetcher
Polls HN API for top AI/ML stories from last 7 days
Returns JSON-serialized results
"""

import json
import sys
import urllib.request
import urllib.error
from datetime import datetime, timedelta
from time import time

HN_API_BASE = "https://hacker-news.firebaseio.com/v0"
AI_KEYWORDS = ["ai", "ml", "machine learning", "llm", "gpt", "transformer", "neural", "deep learning", "nlp"]

def fetch_url(url):
    """Fetch JSON from URL, return parsed dict or None"""
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except (urllib.error.URLError, json.JSONDecodeError) as e:
        print(f"Error fetching {url}: {e}", file=sys.stderr)
        return None

def is_ai_story(title, url=""):
    """Check if story title/url contains AI-related keywords"""
    text = (title + " " + url).lower()
    return any(keyword in text for keyword in AI_KEYWORDS)

def get_top_ai_stories(days=7, limit=30):
    """Fetch top HN stories from last N days, filter for AI"""
    
    # Fetch top stories
    top_stories = fetch_url(f"{HN_API_BASE}/topstories.json")
    if not top_stories:
        return []
    
    cutoff_time = time() - (days * 86400)
    ai_stories = []
    
    for story_id in top_stories[:limit*3]:  # Check more to find AI stories
        story = fetch_url(f"{HN_API_BASE}/item/{story_id}.json")
        if not story:
            continue
        
        # Skip non-stories, dead links
        if story.get('type') not in ['story', 'poll']:
            continue
        if story.get('dead') or story.get('deleted'):
            continue
        if story.get('time', 0) < cutoff_time:
            continue
        
        title = story.get('title', '')
        url = story.get('url', '')
        
        if is_ai_story(title, url):
            ai_stories.append({
                'id': story_id,
                'title': title,
                'url': url,
                'score': story.get('score', 0),
                'comments': story.get('descendants', 0),
                'time': story.get('time'),
                'by': story.get('by', 'unknown')
            })
        
        if len(ai_stories) >= limit:
            break
    
    return ai_stories

def get_ask_hn_ai(limit=10):
    """Fetch Ask HN stories about AI"""
    
    search_stories = fetch_url(f"{HN_API_BASE}/topstories.json")
    if not search_stories:
        return []
    
    ask_stories = []
    for story_id in search_stories[:100]:
        story = fetch_url(f"{HN_API_BASE}/item/{story_id}.json")
        if not story:
            continue
        
        title = story.get('title', '')
        if title.startswith('Ask HN:') and is_ai_story(title):
            ask_stories.append({
                'id': story_id,
                'title': title,
                'type': 'ask_hn',
                'score': story.get('score', 0),
                'comments': story.get('descendants', 0),
                'time': story.get('time'),
                'by': story.get('by', 'unknown')
            })
            
            if len(ask_stories) >= limit:
                break
    
    return ask_stories

if __name__ == "__main__":
    output = {
        "timestamp": datetime.now().isoformat(),
        "source": "hacker_news",
        "top_stories": get_top_ai_stories(days=7, limit=20),
        "ask_hn": get_ask_hn_ai(limit=10)
    }
    
    print(json.dumps(output, indent=2))
