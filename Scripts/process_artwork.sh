#!/usr/bin/env bash
# Helper script to process artwork from clipboard or drag-and-drop
# Usage: drag images into Artwork_Inbox folder, then run: bash Scripts/ingest_artwork.sh Artwork_Inbox

echo "Artwork processing helper"
echo "========================="
echo ""
echo "To process your artwork:"
echo "1. Save your image files to: Artwork_Inbox/"
echo "2. Name them descriptively (e.g., pluto_fill.png, scorpio.png)"
echo "3. Run: bash Scripts/ingest_artwork.sh Artwork_Inbox"
echo ""
echo "Current artwork files in Artwork_Inbox:"
ls -lh Artwork_Inbox/*.{png,PNG,svg,SVG} 2>/dev/null || echo "  (no PNG/SVG files found)"
echo ""
