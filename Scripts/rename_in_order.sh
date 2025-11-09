#!/usr/bin/env bash
# Rename artwork files in order:
# First 12 = zodiac signs (Aries through Pisces)
# Next = planets (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto)

cd "$(dirname "$0")/../Artwork_Inbox" || exit 1

# Zodiac signs in order
zodiac=("aries" "taurus" "gemini" "cancer" "leo" "virgo" "libra" "scorpio" "sagittarius" "capricorn" "aquarius" "pisces")

# Planets (in order they appear)
planets=("sun" "moon" "mercury" "venus" "mars" "jupiter" "saturn" "uranus" "neptune" "pluto")

# Get files sorted by modification time, excluding duplicates
files=($(ls -1t *.png 2>/dev/null | grep -v " (1)" | head -22))

echo "Renaming files in order..."
echo ""

# Rename zodiac signs (first 12)
for i in {0..11}; do
    if [ -n "${files[$i]}" ] && [ -f "${files[$i]}" ]; then
        old="${files[$i]}"
        new="zodiac_${zodiac[$i]}.png"
        echo "[$((i+1))] $old -> $new"
        mv "$old" "$new" 2>/dev/null || echo "  (skipped - already exists or error)"
    fi
done

# Update file list after zodiac renames
files=($(ls -1t *.png 2>/dev/null | grep -v " (1)" | head -22))

# Rename planets (next files)
planet_idx=0
for i in {12..21}; do
    if [ -n "${files[$i]}" ] && [ -f "${files[$i]}" ] && [ "$planet_idx" -lt "${#planets[@]}" ]; then
        old="${files[$i]}"
        planet="${planets[$planet_idx]}"
        new="planet_${planet}_fill.png"
        echo "[$((i+1))] $old -> $new"
        mv "$old" "$new" 2>/dev/null || echo "  (skipped - already exists or error)"
        ((planet_idx++))
    fi
done

echo ""
echo "Done! Remaining files:"
ls -1 *.png 2>/dev/null | grep "Gemini_Generated" || echo "  (all renamed)"

