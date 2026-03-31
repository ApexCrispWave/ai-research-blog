# Publishing to Medium & Substack

## Setup Required

### Medium
1. Go to: https://medium.com/me/settings
2. Under "Security and apps" → Create integration token
3. Set environment variable:
   ```bash
   export MEDIUM_TOKEN="your_token_here"
   ```

### Substack
1. Get Publication ID from your Substack settings
2. Generate API key in account settings
3. Set environment variables:
   ```bash
   export SUBSTACK_API_KEY="your_key"
   export SUBSTACK_PUB_ID="your_pub_id"
   ```

## Publishing

### Publish to Medium
```bash
./scripts/publish-to-medium.sh posts/2026-03-30-local-llm-productivity.md
```

### Publish to Substack
```bash
./scripts/publish-to-substack.sh posts/2026-03-30-local-llm-productivity.md
```

### Publish to Both
```bash
./scripts/publish-to-medium.sh posts/2026-03-30-local-llm-productivity.md
./scripts/publish-to-substack.sh posts/2026-03-30-local-llm-productivity.md
```

## Testing

To test without real API keys:
```bash
# Dry run (no actual posting)
MEDIUM_TOKEN="test_token" ./scripts/publish-to-medium.sh posts/2026-03-30-local-llm-productivity.md 2>&1 | grep -E "✅|❌"
```

## Automation

Once tokens are set, add to `~/.bashrc` or `~/.zshrc`:
```bash
export MEDIUM_TOKEN="your_token"
export SUBSTACK_API_KEY="your_key"
export SUBSTACK_PUB_ID="your_pub_id"
```

Then the nightly cron job (task-101) will automatically publish.
