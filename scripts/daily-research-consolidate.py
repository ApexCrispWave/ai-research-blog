#!/usr/bin/env python3
"""
Daily Research Consolidation
Combines HN, Product Hunt, and other sources into single research/YYYY-MM-DD.json
Ranks trends, calculates metadata
"""

import json
import sys
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
RESEARCH_DIR = REPO_ROOT / "research"
SCRIPTS_DIR = REPO_ROOT / "scripts"


def consolidate_research(date_str=None):
    """
    Consolidate all research sources for today
    """
    if not date_str:
        date_str = datetime.now().strftime("%Y-%m-%d")

    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)

    import subprocess
    hn_data = {}
    try:
        result = subprocess.run(
            ["python3", str(SCRIPTS_DIR / "hacker-news-fetch.py")],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode == 0 and result.stdout.strip():
            hn_data = json.loads(result.stdout)
        elif result.stderr.strip():
            print(result.stderr.strip(), file=sys.stderr)
    except Exception as e:
        print(f"Warning: Could not fetch HN data: {e}", file=sys.stderr)

    consolidated = {
        "date": date_str,
        "timestamp": datetime.now().isoformat(),
        "sources": {
            "hacker_news": hn_data,
            "youtube": {"note": "YouTube API requires authentication - manual aggregation recommended"},
            "product_hunt": {"note": "Product Hunt requires API key - manual tracking recommended"},
        },
        "metadata": {
            "total_articles": len(hn_data.get("top_stories", [])) + len(hn_data.get("ask_hn", [])),
            "research_dir": str(RESEARCH_DIR),
            "source_status": "ok" if hn_data else "degraded",
        },
    }

    output_file = RESEARCH_DIR / f"{date_str}.json"
    with open(output_file, "w") as f:
        json.dump(consolidated, f, indent=2)

    print(f"Research consolidated: {output_file}", file=sys.stderr)
    print(
        json.dumps(
            {
                "status": "success",
                "file": str(output_file),
                "date": date_str,
                "articles_found": consolidated["metadata"]["total_articles"],
                "source_status": consolidated["metadata"]["source_status"],
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    date = sys.argv[1] if len(sys.argv) > 1 else None
    consolidate_research(date)
