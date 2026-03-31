#!/bin/bash
# setup-cron.sh - Set up nightly cron jobs for autonomous research and blog publishing
# Usage: ./scripts/setup-cron.sh [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DRY_RUN=false

if [ "$1" == "--dry-run" ]; then
  DRY_RUN=true
  echo "🏗️  DRY RUN MODE - No changes will be made"
fi

echo "🕐 Setting up cron jobs for AI Research Blog..."
echo ""

# Define cron jobs
CRON_JOBS=(
  # Nightly research aggregation (12:15 AM)
  "15 0 * * * cd $REPO_ROOT && bash scripts/aggregate-research.sh >> logs/cron-research.log 2>&1"
  
  # Nightly blog post generation (Sunday 6:00 AM)
  "0 6 * * 0 cd $REPO_ROOT && bash scripts/generate-blog-post.sh >> logs/cron-blog-gen.log 2>&1"
  
  # Weekly blog publishing (Sunday 6:30 AM)
  "30 6 * * 0 cd $REPO_ROOT && bash scripts/publish-latest-blog.sh >> logs/cron-publishing.log 2>&1"
)

# Create temp crontab file
TEMP_CRON="/tmp/cron-blog-temp.$$"
crontab -l > "$TEMP_CRON" 2>/dev/null || echo "# New crontab" > "$TEMP_CRON"

# Function to add cron job if not exists
add_cron_job() {
  local job="$1"
  if grep -q "$(echo "$job" | sed 's/[.[\*^$()+?{|]/\\&/g')" "$TEMP_CRON" 2>/dev/null; then
    echo "⏭️  Already scheduled: $job"
  else
    echo "Adding: $job"
    echo "$job" >> "$TEMP_CRON"
  fi
}

# Add all cron jobs
for job in "${CRON_JOBS[@]}"; do
  add_cron_job "$job"
done

# Apply crontab
if [ "$DRY_RUN" = false ]; then
  crontab "$TEMP_CRON"
  echo ""
  echo "✅ Cron jobs installed successfully!"
else
  echo ""
  echo "📋 Would install these cron jobs:"
  cat "$TEMP_CRON"
fi

# Cleanup
rm -f "$TEMP_CRON"

# Show schedule
echo ""
echo "📅 Scheduled jobs:"
echo "  12:15 AM daily    → Research aggregation"
echo "  6:00 AM Sunday    → Blog post generation"
echo "  6:30 AM Sunday    → Blog publishing & syndication"
echo ""
echo "📊 Logs location: $REPO_ROOT/logs/"
echo ""
echo "To view installed jobs:"
echo "  crontab -l"
echo ""
echo "To edit jobs:"
echo "  crontab -e"
echo ""
echo "To disable all blog jobs:"
echo "  crontab -r"
