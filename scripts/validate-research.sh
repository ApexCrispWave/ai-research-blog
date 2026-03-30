#!/bin/bash
# validate-research.sh
# Validates research JSON against schema, checks for quality issues

set -e

if [ -z "$1" ]; then
    echo "Usage: validate-research.sh <json_file>"
    exit 1
fi

FILE="$1"

# Check file exists
if [ ! -f "$FILE" ]; then
    echo "❌ File not found: $FILE"
    exit 1
fi

# Check valid JSON
if ! python3 -m json.tool "$FILE" > /dev/null 2>&1; then
    echo "❌ Invalid JSON: $FILE"
    exit 1
fi

echo "✓ Valid JSON"

# Check required fields
python3 - "$FILE" <<'PYTHON'
import json
import sys
import hashlib

file_path = sys.argv[1]
with open(file_path) as f:
    data = json.load(f)

errors = []

# Check date field
if 'date' not in data and 'week' not in data:
    errors.append("Missing 'date' or 'week' field")

# Check for empty fields and placeholder text
def check_object(obj, path=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            new_path = f"{path}.{k}" if path else k
            if isinstance(v, str):
                if not v or v.strip() == "":
                    errors.append(f"Empty field at {new_path}")
                if "TODO" in v or "PLACEHOLDER" in v or "undefined" in v:
                    errors.append(f"Placeholder text at {new_path}: {v[:50]}")
            check_object(v, new_path)
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            check_object(item, f"{path}[{i}]")

check_object(data)

if errors:
    print("❌ Validation errors:")
    for e in errors:
        print(f"   - {e}")
    sys.exit(1)
else:
    print("✓ All required fields present")
    print("✓ No empty fields or placeholders")
    print("✓ Validation passed")
    sys.exit(0)
PYTHON
