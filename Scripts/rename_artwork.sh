#!/usr/bin/env bash
# Quick rename helper - edit this script with your mappings
# Format: "old_filename.png" "new_filename.png"

cd "$(dirname "$0")/../Artwork_Inbox" || exit 1

# Example mappings - EDIT THESE based on what you see in the images:
# mv "Gemini_Generated_Image_xyz.png" "pluto_fill.png"
# mv "Gemini_Generated_Image_abc.png" "scorpio.png"

echo "Edit this script to add your filename mappings, then run it again."
echo ""
echo "Current files:"
ls -1 *.png 2>/dev/null | head -5
echo "..."
echo ""
echo "Add mv commands above to rename them, then run this script again."

