#!/bin/bash

# Test JSON output from qwen3.5:9b model

echo "Testing Ollama model JSON parsing..."

# Test 1: Simple JSON extraction
echo "Test 1: JSON parsing capability"
cat <<'PROMPT' | ollama run qwen3.5:9b 2>/dev/null | head -20
Return a JSON object with three top AI tools of 2026, with name and description fields. Output ONLY valid JSON, no other text.
PROMPT

echo ""
echo "---"
echo "Test 2: Model accessibility check"
ollama list | grep -q "qwen3.5:9b" && echo "✅ qwen3.5:9b available" || echo "❌ Model not found"

echo ""
echo "---"
echo "Test 3: Simple completion"
echo "What is a transformer?" | ollama run qwen3.5:9b 2>/dev/null | head -5
