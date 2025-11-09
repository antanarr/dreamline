#!/usr/bin/env bash
set -euo pipefail

echo "Scanning repo for obvious secrets patterns..."
patterns=(
  "sk-[a-zA-Z0-9_\\-]{10,}"     # OpenAI keys
  "AIza[0-9A-Za-z\\-_]{35}"     # Google API key
  "AuthKey_[A-Z0-9]{10}\\.p8"   # App Store Connect
)
for p in "${patterns[@]}"; do
  echo "-- Pattern: $p"
  git grep -nE "$p" || true
done
echo "Scan done. If any hits, rotate those credentials immediately."
