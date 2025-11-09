#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPORT_PATH="${REPO_ROOT}/artwork_ingest_report.json"

pushd "${REPO_ROOT}" >/dev/null
npm run ingest:art -- "$@"
popd >/dev/null

if [[ -f "${REPORT_PATH}" ]]; then
  node "${REPO_ROOT}/Scripts/print_ingest_report.mjs" "${REPORT_PATH}"
else
  echo "No ingest report found at ${REPORT_PATH}"
fi

#!/usr/bin/env bash

set -euo pipefail

SRC_DIR="${1:?usage: scripts/ingest_artwork.sh <source_folder_with_png_or_svg>}"
CATALOG="Resources/Assets.xcassets"
PLANETS=(sun moon mercury venus mars jupiter saturn uranus neptune pluto)
ZODIAC=(aries taurus gemini cancer leo virgo libra scorpio sagittarius capricorn aquarius pisces)
ASPECTS=(conjunction sextile square trine opposition)

mkdir -p "$CATALOG/AstroPlanets" "$CATALOG/AstroZodiac" "$CATALOG/AstroAspects"

# Heuristics for filename → kind + name + variant
function classify() {
  local f="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  local kind="" name="" variant="fill"           # default to fill/glow
  if [[ "$f" == *"line"* ]] || [[ "$f" == *"outline"* ]] || [[ "$f" == *"stroke"* ]]; then
    variant="line"
  fi

  for p in "${PLANETS[@]}"; do
    if [[ "$f" == *"$p"* ]]; then kind="planet"; name="$p"; echo "$kind|$name|$variant"; return; fi
  done
  for z in "${ZODIAC[@]}"; do
    if [[ "$f" == *"$z"* ]]; then kind="zodiac"; name="$z"; echo "$kind|$name|"; return; fi
  done
  for a in "${ASPECTS[@]}"; do
    if [[ "$f" == *"$a"* ]]; then kind="aspect"; name="$a"; echo "$kind|$name|"; return; fi
  done
  echo "unknown|||"
}

# Write Contents.json with correct rendering mode
function write_contents_json() {
  local imageset="$1" intent="$2"     # intent: original | template
  local base_name="$(basename "$imageset" .imageset)"
  cat > "$imageset/Contents.json" <<JSON
{
  "images": [
    { "filename": "${base_name}.png", "idiom": "universal", "scale": "1x" },
    { "filename": "${base_name}@2x.png", "idiom": "universal", "scale": "2x" },
    { "filename": "${base_name}@3x.png", "idiom": "universal", "scale": "3x" }
  ],
  "properties": {
    "template-rendering-intent": "$intent",
    "preserves-vector-representation": false
  },
  "info": { "version": 1, "author": "xcode" }
}
JSON
}

# Use sips for PNG scaling (macOS native). For SVG, just copy one raster per scale if the tool exported them already.
function place_png_scales() {
  local src="$1" base="$2"
  sips -s format png -Z 256  "$src" --out "${base}.png" >/dev/null 2>&1 || cp "$src" "${base}.png"
  sips -s format png -Z 512  "$src" --out "${base}@2x.png" >/dev/null 2>&1 || cp "$src" "${base}@2x.png"
  sips -s format png -Z 768  "$src" --out "${base}@3x.png" >/dev/null 2>&1 || cp "$src" "${base}@3x.png"
}

shopt -s nullglob
for file in "$SRC_DIR"/*.{png,PNG,svg,SVG}; do
  IFS='|' read -r kind name variant <<<"$(classify "$(basename "$file")")"
  if [[ -z "$kind" || -z "$name" ]]; then
    echo "[SKIP] Unrecognized: $file"
    continue
  fi

  case "$kind" in
    planet)
      variant="${variant:-fill}"
      base_name="planet_${name}_${variant}"
      target_dir="$CATALOG/AstroPlanets/${base_name}.imageset"
      intent=$([[ "$variant" == "line" ]] && echo "template" || echo "original")
      ;;
    zodiac)
      base_name="zodiac_${name}"
      target_dir="$CATALOG/AstroZodiac/${base_name}.imageset"
      intent="original"
      ;;
    aspect)
      base_name="aspect_${name}"
      target_dir="$CATALOG/AstroAspects/${base_name}.imageset"
      intent="template"
      ;;
  esac

  mkdir -p "$target_dir"
  write_contents_json "$target_dir" "$intent"

  # Place scaled PNGs; if SVG, first rasterize via sips (macOS renders SVG poorly, but sips can convert).
  ext="${file##*.}"
  tmp_png="$file"
  if [[ "$ext" =~ svg|SVG ]]; then
    tmp_png="${target_dir}/_tmp_src.png"
    sips -s format png "$file" --out "$tmp_png" >/dev/null 2>&1 || { echo "[WARN] Could not convert SVG $file, skipping"; continue; }
  fi
  place_png_scales "${tmp_png}" "$target_dir/$(basename "$target_dir" .imageset)"
  [[ -f "${target_dir}/_tmp_src.png" ]] && rm -f "${target_dir}/_tmp_src.png"

  echo "[OK] ${kind}/${name} → $(basename "$target_dir")"
done

echo "[DONE] Ingest complete. Open Xcode to verify imagesets."

