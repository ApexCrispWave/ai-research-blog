#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
from pathlib import Path


def parse_frontmatter(text: str):
    match = re.match(r'^---\n(.*?)\n---\n(.*)$', text, re.DOTALL)
    if not match:
        return {}, text
    frontmatter = {}
    for line in match.group(1).splitlines():
        if ':' in line:
            key, value = line.split(':', 1)
            frontmatter[key.strip()] = value.strip().strip('"')
    return frontmatter, match.group(2).strip()


def publish(post_path: str, api_key: str):
    content = Path(post_path).read_text()
    fm, body = parse_frontmatter(content)
    title = fm.get('title', Path(post_path).stem)
    tags_raw = fm.get('tags', '[]').strip('[]')
    tags = [t.strip().strip('"\'') for t in tags_raw.split(',') if t.strip()][:4]
    canonical_url = f"https://apexcrispwave.github.io/ai-research-blog/{Path(post_path).name.replace('.md', '.html')}"

    payload = {
        'article': {
            'title': title,
            'published': True,
            'body_markdown': body,
            'tags': tags,
            'canonical_url': canonical_url,
            'description': body[:240],
        }
    }

    result = subprocess.run(
        [
            'curl', '-sS',
            '-H', f'api-key: {api_key}',
            '-H', 'Content-Type: application/json',
            '-H', 'Accept: application/json',
            '-H', 'User-Agent: CrispWave-Apex/1.0',
            '-X', 'POST',
            'https://dev.to/api/articles',
            '-d', json.dumps(payload),
        ],
        capture_output=True,
        text=True,
        timeout=45,
    )
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        raise SystemExit(result.returncode)
    print(result.stdout)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: publish-to-devto.py <post_path>', file=sys.stderr)
        sys.exit(1)
    api_key = os.environ.get('DEVTO_API_KEY')
    if not api_key:
        print('DEVTO_API_KEY is required', file=sys.stderr)
        sys.exit(1)
    publish(sys.argv[1], api_key)
