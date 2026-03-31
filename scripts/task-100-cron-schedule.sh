#!/bin/bash
# task-100: Schedule nightly cron jobs
# Sets up 24/7 automation for the blog pipeline

set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "⏰ task-100: Scheduling cron jobs..."

# Cron job definitions (times in PT)
# 12:15 AM - YouTube research
# 1:00 AM - Market research  
# 1:45 AM - Competitive analysis
# Sat 6:00 AM - Generate blog post
# Sun 6:30 AM - Publish blog post

CRON_SCHEDULE="
# AI Research & Blog Pipeline - Night Shift Automation
15 0 * * * cd $PROJECT_DIR && bash scripts/task-094-youtube-research.sh >> logs/task-runs.log 2>&1
0 1 * * * cd $PROJECT_DIR && bash scripts/task-095-market-research.sh >> logs/task-runs.log 2>&1
45 1 * * * cd $PROJECT_DIR && bash scripts/task-096-competitive-analysis.sh >> logs/task-runs.log 2>&1
0 6 * * 6 cd $PROJECT_DIR && bash scripts/task-097-blog-generator.sh \"weekly-ai-roundup\" >> logs/task-runs.log 2>&1
30 6 * * 0 cd $PROJECT_DIR && bash scripts/task-101-publish.sh >> logs/task-runs.log 2>&1
"

# Write crontab schedule to file
echo "$CRON_SCHEDULE" > /tmp/blog-pipeline-crons.txt

echo "📋 Cron schedule created. Add to crontab with:"
echo "   crontab -e"
echo "   Then paste:"
echo "$CRON_SCHEDULE"

echo ""
echo "⚠️  Manual step required: Add the crons above to your crontab"
echo "   View current: crontab -l"
echo "   Edit: crontab -e"

# For testing, show the schedule
echo ""
echo "✅ task-100 complete: schedule configured (not yet installed)"
exit 0
