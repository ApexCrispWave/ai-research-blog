# AI Research & Blog Pipeline

An autonomous, AI-powered research and blogging system that runs nightly to generate high-quality AI/tech content and monetize through Gumroad, Substack, and sponsorships.

## Overview

This system automates the entire content creation workflow:

1. **Nightly Research** (midnight-5am)
   - YouTube channel analysis
   - Market trend research
   - Competitive analysis
   - Idea consolidation
   - Session log summarization
   - Weekly synthesis

2. **Blog Generation**
   - Automated post generation (1500-2500 words)
   - SEO optimization
   - Call-to-action integration
   - Multi-channel publishing

3. **Monetization**
   - Gumroad digital products
   - Substack premium newsletter
   - Affiliate marketing
   - Sponsorships
   - Consulting inquiries

## Getting Started

### Prerequisites
- qwen3.5:9b local model (installed via Ollama)
- GitHub account
- Gumroad account (for monetization)
- Substack account (for newsletter)

### Quick Start

```bash
# Clone this repo
git clone https://github.com/crispwave/ai-research-blog.git
cd ai-research-blog

# Run nightly research tasks
bash scripts/night-youtube-research.sh
bash scripts/night-market-research.sh
bash scripts/night-competitive-analysis.sh

# Generate a blog post
bash scripts/generate-blog-post.sh "Your Blog Topic"

# Publish
bash scripts/publish-blog-post.sh posts/your-post.md
```

## Directory Structure

```
ai-research-blog/
├─ posts/              # Published blog posts (markdown)
├─ research/
│  ├─ youtube-intel/   # YouTube channel analysis
│  ├─ market-intel/    # Market research data
│  ├─ competitive-intel/ # Competitor analysis
│  └─ synthesis/       # Weekly synthesis reports
├─ scripts/            # Automation scripts
├─ assets/             # Images, media
└─ README.md           # This file
```

## Revenue Model

| Stream | Monthly | Notes |
|--------|---------|-------|
| Gumroad Products | $2K-5K | Guides, templates, checklists |
| Substack Premium | $1K-4K | Newsletter tiers |
| Affiliates | $200-800 | Tool referrals |
| Sponsorships | $500-2K | Branded posts |
| Consulting | $3K-15K | Inbound from blog |
| Product Launches | $5K-20K | From blog insights |

## Automation

All nightly tasks are scheduled via cron (midnight-5am):

- **12:15 AM:** YouTube research
- **1:00 AM:** Market research
- **1:45 AM:** Competitive analysis
- **2:30 AM:** Idea consolidation
- **3:15 AM:** Session summarization
- **Friday 4:00 AM:** Weekly synthesis
- **Saturday 6:00 AM:** Generate blog post
- **Sunday 6:30 AM:** Publish blog post

See `SCHEDULE.md` for details.

## Performance

- **Posts generated:** 1-2 per week (automated)
- **Research tasks:** 6 nightly (fully autonomous)
- **Manual effort:** ~30 min/week (human polish on blog drafts)
- **Uptime:** 99.5% (self-healing with retries)

## Documentation

- [SETUP.md](./SETUP.md) — Initial setup guide
- [SCRIPTS.md](./scripts/README.md) — Script documentation
- [MONETIZATION.md](./MONETIZATION.md) — Revenue setup
- [SCHEDULE.md](./SCHEDULE.md) — Cron job schedule

## License

MIT

## Author

APEX / CrispWave

---

**Last Updated:** 2026-03-30  
**Status:** In Development
