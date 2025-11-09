#!/usr/bin/env bash
# Helper script to identify and rename artwork files
# Usage: Open images in Preview or Finder to identify them, then rename manually
# Or use this script to list them for manual identification

echo "Artwork files in Artwork_Inbox:"
echo "================================"
echo ""

cd "$(dirname "$0")/../Artwork_Inbox" || exit 1

count=1
for file in *.png *.PNG 2>/dev/null; do
    if [ -f "$file" ]; then
        size=$(ls -lh "$file" | awk '{print $5}')
        echo "[$count] $file ($size)"
        ((count++))
    fi
done

echo ""
echo "To identify these files:"
echo "1. Open them in Preview or Finder"
echo "2. Identify which zodiac/planet each one represents"
echo "3. Rename them with descriptive names (e.g., 'pluto_fill.png', 'scorpio.png')"
echo "4. Then run: bash Scripts/ingest_artwork.sh Artwork_Inbox"

