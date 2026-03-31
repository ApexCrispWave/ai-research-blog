# AI Research & Blog Pipeline

**24/7 Autonomous Night-Shift Research & Content Generation System**

Uses **qwen3.5:9b** (zero cloud cost) to conduct nightly AI research, generate blog posts, and build revenue streams.

## Architecture

```
ai-research-blog/
├── scripts/
│   ├── night-youtube-research.sh      # Scan 4-6 AI channels
│   ├── night-market-research.sh       # Product Hunt, HN, GitHub trends
│   ├── night-competitive-analysis.sh  # Competitor features/pricing
│   ├── night-idea-consolidation.sh    # Dedup & consolidate findings
│   ├── night-session-summarization.sh # Parse session logs
│   ├── night-weekly-synthesis.sh      # Weekly theme rollup
│   ├── generate-blog-post.sh          # qwen3.5:9b → blog post
│   ├── publish-blog-post.sh           # GitHub → blog live
│   ├── track-blog-revenue.sh          # Gumroad/Substack tracking
│   ├── monitor-night-shift.sh         # Health check
│   └── night-shift-retry.sh           # Failure recovery
├── research/
│   ├── youtube-intel/
│   ├── market-intel/
│   ├── competitive-intel/
│   ├── synthesis/
│   └── YYYY-MM-DD/                    # Daily folder
├── posts/
│   └── YYYY-MM-DD-slug.md             # Published posts
├── logs/
│   ├── task-runs.json                 # All task execution logs
│   └── blog-revenue.json              # Revenue tracking
└── README.md                          # This file

```

## Nightly Schedule (Midnight - 5 AM PT)

| Time | Task | Output |
|------|------|--------|
| 12:15 AM | YouTube research | `youtube-intel/YYYY-MM-DD.json` |
| 1:00 AM | Market research | `market-intel/YYYY-MM-DD.json` |
| 1:45 AM | Competitive analysis | `competitive-intel/YYYY-MM-DD.json` |
| 2:30 AM | Idea consolidation | `apex-ideas.json` update |
| 3:15 AM | Session summarization | `memory/YYYY-MM-DD.md` update |
| Fri 4:00 AM | Weekly synthesis | `synthesis/weekly-YYYY-WW.md` |
| Sat 6:00 AM | Generate blog post | `posts/YYYY-MM-DD-slug.md` |
| Sun 6:30 AM | Publish blog post | Post live (GitHub + syndication) |
| Mon 7:00 AM | Send newsletter | Substack/email |

## Success Metrics

- **Phase 1 (Week 4):** 6/6 nightly tasks running autonomously
- **Phase 2 (Week 5):** 1+ blog posts published weekly
- **Phase 3 (Month 1):** 4+ posts live, $0 in revenue (building audience)
- **Phase 6 (Month 3):** 12+ posts, $100+/month revenue
- **Target (Month 6):** $500+/month revenue, 500+ blog readers

## Getting Started

### Prerequisites
- `qwen3.5:9b` (already installed)
- `curl`, `jq`, `python3`
- GitHub repo + access
- Gumroad + Substack accounts (Ronald sets up)

### First Run
```bash
cd /Users/openclaw/Projects/ai-research-blog

# Test individual scripts
./scripts/night-youtube-research.sh
./scripts/night-market-research.sh
./scripts/night-competitive-analysis.sh

# Generate a test blog post
./scripts/generate-blog-post.sh "Testing the Pipeline"

# Schedule all jobs (cron)
bash scripts/schedule-nightly-jobs.sh
```

### Monitoring
```bash
# Check last run status
tail -50 logs/task-runs.json

# View revenue tracking
cat logs/blog-revenue.json

# Run health check
bash scripts/monitor-night-shift.sh
```

## Key Features

✅ **Zero Cloud Costs** — All local models (qwen3.5:9b)
✅ **Autonomous** — Runs 24/7 with minimal intervention
✅ **Self-Healing** — Retry logic, automatic restarts on failure
✅ **Validated Data** — All outputs checked before propagation
✅ **Integrated** — Links to apex-ideas.json, memory system, task board
✅ **Revenue-Ready** — Gumroad products, Substack newsletter, affiliate tracking

## Tasks Status

- [ ] task-082: Orchestrator setup
- [ ] task-083: YouTube research script
- [ ] task-084: Market research script
- [ ] task-085: Competitive analysis script
- [ ] task-086: Blog post generator
- [ ] task-089: Cron job scheduling
- [ ] task-090: GitHub CI/CD + final integration

---

*Built with ❤️ using local LLMs. Zero cloud API calls.*
